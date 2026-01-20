//
//  WithdrawalsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct WithdrawalsView: View {
    private let testTransactions: [WithdrawalTransaction] = [
        WithdrawalTransaction(
            title: "Ticket - Neon Nights",
            detail: "Order #T-1024",
            amount: 45.00,
            date: "Jan 10, 2026"
        ),
        WithdrawalTransaction(
            title: "Ticket - Winter Gala",
            detail: "Order #T-1031",
            amount: 30.00,
            date: "Jan 12, 2026"
        ),
        WithdrawalTransaction(
            title: "Ticket - City Lights",
            detail: "Order #T-1042",
            amount: 45.00,
            date: "Jan 15, 2026"
        )
    ]
    private let realTransactions: [WithdrawalTransaction] = []
    
    private var testBalance: Double {
        testTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var realBalance: Double {
        realTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var totalBalance: Double {
        testBalance + realBalance
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                Section {
                    BalanceRow(
                        title: "Total available to withdraw",
                        amount: totalBalance,
                        isEmphasis: true
                    )
                    
                    NavigationLink(destination: WithdrawalTransactionsView(
                        title: "Test money",
                        transactions: testTransactions,
                        total: testBalance,
                        emptyMessage: "No test transactions yet."
                    )) {
                        BalanceRow(
                            title: "Test money to withdraw",
                            amount: testBalance,
                            showsDisclosureIndicator: true
                        )
                    }
                    
                    NavigationLink(destination: WithdrawalTransactionsView(
                        title: "Real money",
                        transactions: realTransactions,
                        total: realBalance,
                        emptyMessage: "No real money to withdraw yet."
                    )) {
                        BalanceRow(
                            title: "Real money to withdraw",
                            amount: realBalance,
                            showsDisclosureIndicator: true
                        )
                    }
                } header: {
                    Text("Withdraw")
                        .foregroundColor(.sioreeLightGrey)
                } footer: {
                    Text("Total available reflects ticket sales not yet withdrawn.")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Withdraw")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter
    }()
    
    private func formattedAmount(_ amount: Double) -> String {
        if let formatted = WithdrawalsView.currencyFormatter.string(from: NSNumber(value: amount)) {
            return formatted
        }
        
        return String(format: "$%.2f", amount)
    }
    
    private struct BalanceRow: View {
        let title: String
        let amount: Double
        var isEmphasis = false
        var showsDisclosureIndicator = false
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(isEmphasis ? .sioreeBodyBold : .sioreeBody)
                        .foregroundColor(.sioreeWhite)
                    
                    if isEmphasis {
                        Text("Includes test and real balances")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                
                Spacer()
                
                Text(formattedAmount(amount))
                    .font(isEmphasis ? .sioreeH3 : .sioreeBody)
                    .foregroundColor(.sioreeIcyBlue)
                
                if showsDisclosureIndicator {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sioreeLightGrey)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        
        private func formattedAmount(_ amount: Double) -> String {
            WithdrawalsView.currencyFormatter.string(from: NSNumber(value: amount))
            ?? String(format: "$%.2f", amount)
        }
    }
}

private struct WithdrawalTransaction: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let amount: Double
    let date: String
}

private struct WithdrawalTransactionsView: View {
    let title: String
    let transactions: [WithdrawalTransaction]
    let total: Double
    let emptyMessage: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                Section {
                    HStack {
                        Text("Total")
                            .font(.sioreeBodyBold)
                            .foregroundColor(.sioreeWhite)
                        Spacer()
                        Text(formattedAmount(total))
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeIcyBlue)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                } header: {
                    Text("Available to withdraw")
                        .foregroundColor(.sioreeLightGrey)
                }
                
                Section {
                    if transactions.isEmpty {
                        Text(emptyMessage)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.vertical, Theme.Spacing.xs)
                    } else {
                        ForEach(transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                } header: {
                    Text("Transactions")
                        .foregroundColor(.sioreeLightGrey)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedAmount(_ amount: Double) -> String {
        WithdrawalsView.currencyFormatter.string(from: NSNumber(value: amount))
        ?? String(format: "$%.2f", amount)
    }
    
    private struct TransactionRow: View {
        let transaction: WithdrawalTransaction
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                    Text("\(transaction.detail) • \(transaction.date)")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
                
                Spacer()
                
                Text(formattedAmount(transaction.amount))
                    .font(.sioreeBodyBold)
                    .foregroundColor(.sioreeIcyBlue)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        
        private func formattedAmount(_ amount: Double) -> String {
            WithdrawalsView.currencyFormatter.string(from: NSNumber(value: amount))
            ?? String(format: "$%.2f", amount)
        }
    }
}

#Preview {
    NavigationStack {
        WithdrawalsView()
    }
}
