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
    @Published var paymentSheetErrorMessage: String?
    @Published var isPreparingPaymentSheet = false

    private var backendCheckoutUrl: URL {
        let urlString = "\(Constants.API.baseURL)/api/stripe/payment-sheet"
        return URL(string: urlString)!
    }

    private struct CheckoutResponse: Decodable {
        let paymentIntent: String
        let customer: String
        let ephemeralKey: String
        let publishableKey: String
    }

    func preparePaymentSheet(amount: Double, retryCount: Int = 0) {
        let maxRetries = 2
        if retryCount == 0 {
            DispatchQueue.main.async {
                self.paymentSheetErrorMessage = nil
                self.isPreparingPaymentSheet = true
            }
        }

        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["amount": amount, "currency": "usd"] as [String: Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let handleFailure: (String) -> Void = { message in
                guard let self = self else { return }
                if retryCount < maxRetries {
                    let delay = Double(retryCount + 1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.preparePaymentSheet(amount: amount, retryCount: retryCount + 1)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.paymentSheetErrorMessage = message
                        self.isPreparingPaymentSheet = false
                    }
                }
            }

            if let error = error {
                handleFailure("Payment setup failed. \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                handleFailure("Payment setup failed. Invalid server response.")
                return
            }

            guard let data = data else {
                handleFailure("Payment setup failed. Empty response.")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Server error."
                handleFailure("Payment setup failed. \(serverMessage)")
                return
            }

            do {
                let response = try JSONDecoder().decode(CheckoutResponse.self, from: data)
                STPAPIClient.shared.publishableKey = response.publishableKey

                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Soirée"
                configuration.customer = .init(
                    id: response.customer,
                    ephemeralKeySecret: response.ephemeralKey
                )
                configuration.allowsDelayedPaymentMethods = true
                configuration.returnURL = "your-app://stripe-redirect"

                DispatchQueue.main.async {
                    self?.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: response.paymentIntent,
                        configuration: configuration
                    )
                    self?.paymentSheetErrorMessage = nil
                    self?.isPreparingPaymentSheet = false
                }
            } catch {
                handleFailure("Payment setup failed. \(error.localizedDescription)")
            }
        }.resume()
    }

    func onPaymentCompletion(result: PaymentSheetResult) {
        paymentResult = result
    }
}
