//
//  CheckoutViewModel.swift
//  Sioree
//
//  Handles ticket checkout with Stripe Connect and Apple Pay
//

import Foundation
import SwiftUI
import Combine

class CheckoutViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var paymentIntent: StripeCheckoutIntent?
    @Published var selectedQuantity = 1
    @Published var showPaymentSheet = false

    private let stripeService = StripePaymentService.shared
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()

    private let eventId: String

    init(eventId: String) {
        self.eventId = eventId
    }

    // MARK: - Create Payment Intent
    func createPaymentIntent(quantity: Int = 1) {
        isLoading = true
        errorMessage = nil
        selectedQuantity = quantity

        stripeService.createTicketPaymentIntent(eventId: eventId, quantity: quantity)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Failed to create payment intent: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] checkoutIntent in
                    self?.paymentIntent = checkoutIntent
                    self?.showPaymentSheet = true
                    print("✅ Payment intent created successfully")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Calculate Pricing Display
    func getPricingBreakdown() -> (ticketPrice: Double, fees: Double, total: Double)? {
        guard let pricing = paymentIntent?.pricing else { return nil }

        let ticketPrice = Double(pricing.ticket_price_cents) / 100.0
        let fees = Double(pricing.fees_amount_cents) / 100.0
        let total = Double(pricing.total_amount_cents) / 100.0

        return (ticketPrice, fees, total)
    }

    // MARK: - Confirm Payment (called after Stripe payment succeeds)
    func confirmPayment(paymentIntentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // In the new flow, payment confirmation is handled via webhooks
        // We can optionally poll for confirmation or just assume success
        // since Stripe handles the actual payment processing

        // For now, just mark as successful - the webhook will handle the actual ticket creation
        completion(.success(()))
    }

    // MARK: - Reset State
    func reset() {
        paymentIntent = nil
        showPaymentSheet = false
        errorMessage = nil
        selectedQuantity = 1
    }
}
