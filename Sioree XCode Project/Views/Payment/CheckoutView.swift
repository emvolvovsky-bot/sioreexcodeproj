//
//  CheckoutView.swift
//  Sioree
//
//  Stripe PaymentSheet checkout flow
//

import SwiftUI
import StripePaymentSheet

struct CheckoutView: View {
    @StateObject private var model = CheckoutViewModel()
    private let sampleAmount = 10.00

    var body: some View {
        VStack(spacing: 16) {
            if let paymentSheet = model.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onPaymentCompletion
                ) {
                    Text("Buy")
                }
            }

            if let paymentResult = model.paymentResult {
                Text(resultText(for: paymentResult))
            }
        }
        .onAppear {
            model.preparePaymentSheet(amount: sampleAmount, eventId: nil)
        }
    }

    private func resultText(for result: PaymentSheetResult) -> String {
        switch result {
        case .completed:
            return "Payment complete"
        case .failed(let error):
            return "Payment failed: \(error.localizedDescription)"
        case .canceled:
            return "Payment canceled"
        }
    }
}


