//
//  HostOnboardingViewModel.swift
//  Sioree
//
//  Handles Stripe Connect onboarding for hosts
//

import Foundation
import SwiftUI
import Combine

class HostOnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var accountStatus: StripeAccountStatus?
    @Published var onboardingUrl: String?
    @Published var showOnboardingWebView = false

    private let stripeService = StripePaymentService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Check Onboarding Status
    func checkOnboardingStatus() {
        isLoading = true
        errorMessage = nil

        stripeService.getAccountStatus()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Failed to check onboarding status: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] status in
                    self?.accountStatus = status
                    print("✅ Onboarding status checked: complete=\(status.onboarding_complete)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Create Stripe Account
    func createStripeAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil

        stripeService.createStripeConnectAccount()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                        print("❌ Failed to create Stripe account: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] account in
                    print("✅ Stripe account created: \(account.account_id)")
                    // After creating account, start onboarding
                    self?.startOnboarding()
                    completion(.success(()))
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Start Onboarding
    func startOnboarding() {
        isLoading = true
        errorMessage = nil

        stripeService.createAccountLink()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Failed to create onboarding link: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] link in
                    self?.onboardingUrl = link.url
                    self?.showOnboardingWebView = true
                    print("✅ Onboarding link created: \(link.url)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Refresh Status After Onboarding
    func refreshStatusAfterOnboarding() {
        // Add a small delay to allow Stripe to process the onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.checkOnboardingStatus()
        }
    }

    // MARK: - Check if Host Can Publish Events
    func canPublishEvents() -> Bool {
        return accountStatus?.onboarding_complete == true
    }

    // MARK: - Get Status Message
    func getStatusMessage() -> String {
        guard let status = accountStatus else {
            return "Checking payout setup..."
        }

        if status.onboarding_complete {
            return "Payout setup complete ✓"
        } else if status.needs_onboarding {
            return "Finish payout setup to publish events"
        } else {
            return "Payout setup in progress..."
        }
    }
}
