//
//  BankAccountsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct BankAccountsView: View {
    @StateObject private var bankService = BankAccountService.shared
    @State private var accounts: [BankAccount] = []
    @State private var isLoading = false
    @State private var showLinkFlow = false
    @State private var errorMessage: String?
    @State private var isStartingOnboarding = false
    @State private var isLoadingStatus = false
    @State private var connectStatus: BankConnectStatus?
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ZStack {
            // Subtle gradient on black background
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading || isLoadingStatus {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
            } else {
                List {
                    Section {
                        Button(action: {
                            startStripeOnboarding()
                        }) {
                            HStack(spacing: Theme.Spacing.s) {
                                Image(systemName: "bolt.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isStartingOnboarding ? "Starting Stripe Setup..." : "Complete Stripe Setup")
                                        .font(.sioreeBody)
                                    Text(connectStatus?.isReady == true ? "Verified" : "Setup required")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                }
                            }
                            .foregroundColor(.sioreeIcyBlue)
                        }
                        .disabled(isStartingOnboarding || connectStatus?.isReady == true)
                    } header: {
                        Text("Stripe Payouts")
                            .foregroundColor(.sioreeLightGrey)
                    } footer: {
                        Text("Stripe requires identity verification before you can receive ticket payouts.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }

                    if connectStatus?.isReady == true {
                        Section {
                            ForEach(accounts) { account in
                                BankAccountRow(account: account) {
                                    removeAccount(account.id)
                                }
                            }
                            
                            Button(action: {
                                showLinkFlow = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Bank Account")
                                        .font(.sioreeBody)
                                }
                                .foregroundColor(.sioreeIcyBlue)
                            }
                        } header: {
                            Text("Connected Accounts")
                                .foregroundColor(.sioreeLightGrey)
                        } footer: {
                            Text("Bank accounts are securely connected using Stripe. Your credentials are never stored.")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    } else {
                        Section {
                            Text("Complete Stripe setup to enable payouts and connect a bank.")
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                        } header: {
                            Text("Connected Accounts")
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Bank Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLinkFlow) {
            BankConnectOnboardingView { request in
                connectBankAccount(request)
            }
        }
        .onAppear {
            loadConnectStatus()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadAccounts() {
        isLoading = true
        bankService.getConnectedAccounts()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { accounts in
                    self.accounts = accounts
                }
            )
            .store(in: &cancellables)
    }

    private func loadConnectStatus() {
        isLoadingStatus = true
        bankService.fetchOnboardingStatus()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingStatus = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { status in
                    connectStatus = status
                    if status.isReady {
                        loadAccounts()
                    } else {
                        accounts = []
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func connectBankAccount(_ request: BankAccountConnectRequest) {
        isLoading = true
        bankService.addBankAccount(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { account in
                    accounts.append(account)
                    loadAccounts() // Reload to get updated list
                }
            )
            .store(in: &cancellables)
    }
    
    private func removeAccount(_ accountId: String) {
        bankService.removeAccount(accountId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { success in
                    if success {
                        accounts.removeAll { $0.id == accountId }
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func startStripeOnboarding() {
        isStartingOnboarding = true
        bankService.createOnboardingLink()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isStartingOnboarding = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { url in
                    openURL(url)
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct BankAccountRow: View {
    let account: BankAccount
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "building.columns.fill")
                .foregroundColor(.sioreeIcyBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.bankName)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                Text("\(account.accountType.capitalized) •••• \(account.last4)")
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
            }
            
            Spacer()
            
            if account.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BankAccountsView()
    }
}
