//
//  CheckoutViewModel.swift
//  Sioree
//
//  Checkout view model placeholder - payments not implemented
//

import Foundation
import StripePaymentSheet

class CheckoutViewModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    let backendCheckoutUrl = URL(string: "https://sioree-api.onrender.com/payment-sheet
")!

    private struct CheckoutResponse: Decodable {
        let paymentIntent: String
        let customer: String
        let customerSessionClientSecret: String
        let publishableKey: String
    }

    func preparePaymentSheet() {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                print("PaymentSheet request failed: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("PaymentSheet request returned empty response")
                return
            }

            do {
                let response = try JSONDecoder().decode(CheckoutResponse.self, from: data)
                STPAPIClient.shared.publishableKey = response.publishableKey

                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Soirée"
                configuration.customer = .init(
                    id: response.customer,
                    customerSessionClientSecret: response.customerSessionClientSecret
                )
                configuration.allowsDelayedPaymentMethods = true
                configuration.returnURL = "your-app://stripe-redirect"

                DispatchQueue.main.async {
                    self?.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: response.paymentIntent,
                        configuration: configuration
                    )
                }
            } catch {
                print("Failed to decode PaymentSheet response: \(error.localizedDescription)")
            }
        }.resume()
    }

    func onPaymentCompletion(result: PaymentSheetResult) {
        paymentResult = result
    }
}
