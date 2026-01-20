//
//  BankConnectOnboardingView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BankConnectOnboardingView: View {
    struct BankOption: Identifiable {
        let id = UUID()
        let name: String
        let subtitle: String
    }
    
    @Environment(\.dismiss) private var dismiss
    let onConnect: (BankAccountConnectRequest) -> Void
    
    @State private var searchText = ""
    @State private var selectedBankId: BankOption.ID?
    @State private var accountHolderName = ""
    @State private var routingNumber = ""
    @State private var accountNumber = ""
    @State private var confirmAccountNumber = ""
    @State private var accountType = "checking"
    
    private let banks: [BankOption] = [
        BankOption(name: "Chase", subtitle: "JPMorgan Chase Bank, N.A."),
        BankOption(name: "Capital One", subtitle: "Capital One, N.A."),
        BankOption(name: "Bank of America", subtitle: "Bank of America, N.A."),
        BankOption(name: "Wells Fargo", subtitle: "Wells Fargo Bank, N.A."),
        BankOption(name: "Citi", subtitle: "Citibank, N.A."),
        BankOption(name: "U.S. Bank", subtitle: "U.S. Bancorp"),
        BankOption(name: "TD Bank", subtitle: "TD Bank, N.A."),
        BankOption(name: "PNC Bank", subtitle: "PNC Bank, N.A."),
        BankOption(name: "HSBC", subtitle: "HSBC Bank USA, N.A."),
        BankOption(name: "Ally Bank", subtitle: "Ally Bank"),
        BankOption(name: "Discover", subtitle: "Discover Bank"),
        BankOption(name: "Charles Schwab", subtitle: "Charles Schwab Bank, SSB")
    ]
    
    private var filteredBanks: [BankOption] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return banks }
        return banks.filter { option in
            option.name.localizedCaseInsensitiveContains(trimmed) ||
            option.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    private var selectedBankName: String {
        banks.first { $0.id == selectedBankId }?.name ?? "Bank Account"
    }
    
    private var isRoutingValid: Bool {
        routingNumber.filter(\.isNumber).count == 9
    }
    
    private var isAccountValid: Bool {
        accountNumber.filter(\.isNumber).count >= 4
    }
    
    private var doAccountNumbersMatch: Bool {
        !accountNumber.isEmpty && accountNumber == confirmAccountNumber
    }
    
    private var isSelectionValid: Bool {
        selectedBankId != nil &&
        !accountHolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isRoutingValid &&
        isAccountValid &&
        doAccountNumbersMatch
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Connect your bank")
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)
                        
                        Text("Choose your bank to securely link your account with Stripe.")
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeLightGrey)
                    }
                    .padding(.top, Theme.Spacing.l)
                    
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        
                        TextField("Search banks", text: $searchText)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .foregroundColor(.sioreeWhite)
                            .font(.sioreeBody)
                    }
                    .padding(Theme.Spacing.m)
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
                    )
                    
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.s) {
                            ForEach(filteredBanks) { bank in
                                BankOptionRow(
                                    bank: bank,
                                    isSelected: selectedBankId == bank.id,
                                    onTap: {
                                        selectedBankId = bank.id
                                    }
                                )
                            }
                            
                            if filteredBanks.isEmpty {
                                Text("No results. Try another bank name.")
                                    .font(.sioreeBodySmall)
                                    .foregroundColor(.sioreeLightGrey)
                                    .padding(.vertical, Theme.Spacing.l)
                            }
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                Text("Bank account details")
                                    .font(.sioreeBodyBold)
                                    .foregroundColor(.sioreeWhite)
                                    .padding(.top, Theme.Spacing.m)
                                
                                VStack(spacing: Theme.Spacing.s) {
                                    TextField("Account holder name", text: $accountHolderName)
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.sioreeWhite)
                                        .font(.sioreeBody)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeLightGrey.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                    
                                    TextField("Routing number", text: $routingNumber)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.sioreeWhite)
                                        .font(.sioreeBody)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeLightGrey.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                    
                                    SecureField("Account number", text: $accountNumber)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.sioreeWhite)
                                        .font(.sioreeBody)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeLightGrey.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                    
                                    SecureField("Confirm account number", text: $confirmAccountNumber)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.sioreeWhite)
                                        .font(.sioreeBody)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeLightGrey.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                    
                                    HStack(spacing: Theme.Spacing.s) {
                                        AccountTypeButton(
                                            title: "Checking",
                                            isSelected: accountType == "checking",
                                            onTap: { accountType = "checking" }
                                        )
                                        
                                        AccountTypeButton(
                                            title: "Savings",
                                            isSelected: accountType == "savings",
                                            onTap: { accountType = "savings" }
                                        )
                                    }
                                }
                            }
                            .padding(.top, Theme.Spacing.s)
                        }
                        .padding(.top, Theme.Spacing.s)
                    }
                    
                    Button(action: {
                        let request = BankAccountConnectRequest(
                            bankName: selectedBankName,
                            accountHolderName: accountHolderName.trimmingCharacters(in: .whitespacesAndNewlines),
                            routingNumber: routingNumber.filter(\.isNumber),
                            accountNumber: accountNumber.filter(\.isNumber),
                            accountType: accountType
                        )
                        onConnect(request)
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.sioreeBodyBold)
                            .foregroundColor(.sioreeWhite)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.m)
                            .background(isSelectionValid ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.3))
                            .cornerRadius(Theme.CornerRadius.medium)
                    }
                    .disabled(!isSelectionValid)
                    .padding(.bottom, Theme.Spacing.l)
                }
                .padding(.horizontal, Theme.Spacing.l)
            }
            .navigationTitle("Connect Bank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Not now") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
}

private struct BankOptionRow: View {
    let bank: BankConnectOnboardingView.BankOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.sioreeIcyBlue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(String(bank.name.prefix(1)))
                        .font(.sioreeBodyBold)
                        .foregroundColor(.sioreeIcyBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bank.name)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                    
                    Text(bank.subtitle)
                        .font(.sioreeBodySmall)
                        .foregroundColor(.sioreeLightGrey)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
            .padding(Theme.Spacing.m)
            .background(isSelected ? Color.sioreeIcyBlue.opacity(0.2) : Color.sioreeLightGrey.opacity(0.1))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Color.sioreeIcyBlue : Color.sioreeIcyBlue.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

private struct AccountTypeButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.sioreeBody)
                .foregroundColor(isSelected ? .sioreeWhite : .sioreeLightGrey)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.s)
                .background(isSelected ? Color.sioreeIcyBlue.opacity(0.3) : Color.sioreeLightGrey.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(isSelected ? Color.sioreeIcyBlue : Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    BankConnectOnboardingView(onConnect: { _ in })
}
