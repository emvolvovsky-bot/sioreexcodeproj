//
//  EarningsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct EarningsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = EarningsViewModel()
    @State private var showWithdrawal = false
    @State private var selectedBankAccount: BankAccount?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Total Earnings Card
                        VStack(spacing: Theme.Spacing.m) {
                            Text("Total Earnings")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("$\(String(format: "%.2f", viewModel.totalEarnings))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Available to withdraw")
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.xl)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.large)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.m)
                        
                        // Withdraw Button
                        if viewModel.totalEarnings > 0 {
                            Button(action: {
                                showWithdrawal = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Withdraw to Bank Account")
                                        .font(.sioreeBody)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                        
                        // Earnings History
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Earnings History")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            if viewModel.earnings.isEmpty {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "dollarsign.circle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                    Text("No earnings yet")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.xl)
                            } else {
                                LazyVStack(spacing: Theme.Spacing.m) {
                                    ForEach(viewModel.earnings) { earning in
                                        EarningsRow(earning: earning)
                                            .padding(.horizontal, Theme.Spacing.m)
                                    }
                                }
                            }
                        }
                        .padding(.top, Theme.Spacing.m)
                        
                        // Withdrawal History
                        if !viewModel.withdrawals.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                Text("Withdrawal History")
                                    .font(.sioreeH3)
                                    .foregroundColor(.sioreeWhite)
                                    .padding(.horizontal, Theme.Spacing.m)
                                
                                LazyVStack(spacing: Theme.Spacing.m) {
                                    ForEach(viewModel.withdrawals) { withdrawal in
                                        WithdrawalRow(withdrawal: withdrawal)
                                            .padding(.horizontal, Theme.Spacing.m)
                                    }
                                }
                            }
                            .padding(.top, Theme.Spacing.m)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Earnings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadEarnings()
            }
            .sheet(isPresented: $showWithdrawal) {
                WithdrawalView(availableBalance: viewModel.totalEarnings)
            }
        }
    }
}

struct EarningsRow: View {
    let earning: Earning
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(earning.source)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                Text(earning.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
            }
            
            Spacer()
            
            Text("+$\(String(format: "%.2f", earning.amount))")
                .font(.sioreeBody)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct WithdrawalRow: View {
    let withdrawal: Withdrawal
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.sioreeIcyBlue)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Withdrawn to \(withdrawal.bankAccountName)")
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                Text(withdrawal.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
                
                Text("Status: \(withdrawal.status.rawValue.capitalized)")
                    .font(.sioreeCaption)
                    .foregroundColor(withdrawal.status == .completed ? .green : .orange)
            }
            
            Spacer()
            
            Text("-$\(String(format: "%.2f", withdrawal.amount))")
                .font(.sioreeBody)
                .fontWeight(.semibold)
                .foregroundColor(.sioreeIcyBlue)
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
        )
    }
}

// Earning, Withdrawal, and WithdrawalStatus are now defined in NetworkService.swift

class EarningsViewModel: ObservableObject {
    @Published var totalEarnings: Double = 0.0
    @Published var earnings: [Earning] = []
    @Published var withdrawals: [Withdrawal] = []
    @Published var isLoading = false
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadEarnings() {
        isLoading = true
        networkService.fetchEarnings()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load earnings: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.totalEarnings = response.totalEarnings
                    self?.earnings = response.earnings
                    self?.withdrawals = response.withdrawals
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
}

struct WithdrawalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var bankService = BankAccountService.shared
    @State private var bankAccounts: [BankAccount] = []
    @State private var selectedAccountId: String?
    @State private var amount: String = ""
    @State private var isWithdrawing = false
    @State private var errorMessage: String?
    let availableBalance: Double
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Available Balance
                        VStack(spacing: Theme.Spacing.m) {
                            Text("Available Balance")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("$\(String(format: "%.2f", availableBalance))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.sioreeIcyBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.xl)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.large)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.m)
                        
                        // Amount Input
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Amount")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                            
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.sioreeWhite)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Bank Account Selection
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Select Bank Account")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                            
                            if bankAccounts.isEmpty {
                                NavigationLink(destination: BankAccountsView()) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Bank Account")
                                    }
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            } else {
                                ForEach(bankAccounts) { account in
                                    Button(action: {
                                        selectedAccountId = account.id
                                    }) {
                                        HStack {
                                            Image(systemName: "building.columns.fill")
                                                .foregroundColor(.sioreeIcyBlue)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(account.bankName)
                                                    .font(.sioreeBody)
                                                    .foregroundColor(.sioreeWhite)
                                                
                                                Text("\(account.accountType.capitalized) •••• \(account.last4)")
                                                    .font(.sioreeBodySmall)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedAccountId == account.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.sioreeIcyBlue)
                                            }
                                        }
                                        .padding(Theme.Spacing.m)
                                        .background(selectedAccountId == account.id ? Color.sioreeIcyBlue.opacity(0.2) : Color.sioreeLightGrey.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                .stroke(selectedAccountId == account.id ? Color.sioreeIcyBlue : Color.sioreeIcyBlue.opacity(0.3), lineWidth: selectedAccountId == account.id ? 2 : 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Withdraw Button
                        Button(action: {
                            withdraw()
                        }) {
                            Text("Withdraw")
                                .font(.sioreeBody)
                                .fontWeight(.semibold)
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(isValid ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.3))
                                .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .disabled(!isValid || isWithdrawing)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Withdraw Earnings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onAppear {
                loadBankAccounts()
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
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount),
              amountValue > 0,
              amountValue <= availableBalance,
              selectedAccountId != nil else {
            return false
        }
        return true
    }
    
    private func loadBankAccounts() {
        bankService.getConnectedAccounts()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { accounts in
                    self.bankAccounts = accounts
                }
            )
            .store(in: &cancellables)
    }
    
    private func withdraw() {
        guard let accountId = selectedAccountId,
              let amountValue = Double(amount),
              amountValue > 0,
              amountValue <= availableBalance else {
            errorMessage = "Invalid amount or account selection"
            return
        }
        
        isWithdrawing = true
        let networkService = NetworkService()
        networkService.withdrawEarnings(amount: amountValue, bankAccountId: accountId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isWithdrawing = false
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to withdraw: \(error.localizedDescription)"
                    } else {
                        dismiss()
                    }
                },
                receiveValue: { [self] _ in
                    isWithdrawing = false
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    EarningsView()
        .environmentObject(AuthViewModel())
}

