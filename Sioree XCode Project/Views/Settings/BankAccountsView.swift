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
    
    var body: some View {
        ZStack {
            // Subtle gradient on black background
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
            } else {
                List {
                    Section {
                        ForEach(accounts) { account in
                            BankAccountRow(account: account) {
                                removeAccount(account.id)
                            }
                        }
                        
                        Button(action: {
                            connectBankAccount()
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
                        Text("Bank accounts are securely connected using Plaid. Your credentials are never stored.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Bank Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAccounts()
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
    
    private func connectBankAccount() {
        isLoading = true
        bankService.getLinkToken()
            .flatMap { token in
                // In production, this would open Plaid Link SDK
                // For now, we'll call the backend which handles Plaid
                // The backend should return a link_token that can be used with Plaid Link
                return self.bankService.exchangePublicToken("mock-public-token")
            }
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
