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
        makeCheckoutURL(baseURL: Constants.API.baseURL, path: "api/stripe/payment-sheet")
    }

    private var fallbackCheckoutUrl: URL {
        makeCheckoutURL(baseURL: Constants.API.baseURL, path: "stripe/payment-sheet")
    }

    private var onrenderFallbackCheckoutUrls: [URL] {
        let baseCandidates = inferredBaseURLCandidates(from: Constants.API.baseURL)
        return baseCandidates.flatMap { baseURL in
            [
                makeCheckoutURL(baseURL: baseURL, path: "api/stripe/payment-sheet"),
                makeCheckoutURL(baseURL: baseURL, path: "stripe/payment-sheet")
            ]
        }
    }

    private var hardcodedFallbackCheckoutUrls: [URL] {
        [
            makeCheckoutURL(baseURL: "https://sioree-api.onrender.com", path: "api/stripe/payment-sheet"),
            makeCheckoutURL(baseURL: "https://sioree-api.onrender.com", path: "stripe/payment-sheet")
        ]
    }

    private func makeCheckoutURL(baseURL: String, path: String) -> URL {
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") {
            base.removeLast()
        }
        if base.hasSuffix("/api") {
            base = String(base.dropLast(4))
        }
        return URL(string: base)!.appendingPathComponent(path)
    }

    private func inferredBaseURLCandidates(from baseURL: String) -> [String] {
        guard let url = URL(string: baseURL),
              let host = url.host,
              host.hasSuffix(".onrender.com"),
              !host.contains("-api") else {
            return []
        }

        let apiHost = host.replacingOccurrences(of: ".onrender.com", with: "-api.onrender.com")
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = apiHost
        return [components.string].compactMap { $0 }
    }

    private struct CheckoutResponse: Decodable {
        let paymentIntent: String
        let customer: String
        let customerSessionClientSecret: String?
        let ephemeralKey: String?
        let publishableKey: String
    }

    private struct StripeErrorResponse: Decodable {
        struct StripeError: Decodable {
            let message: String?
            let type: String?
            let code: String?
            let param: String?
        }

        let error: StripeError?
    }

    private func logPaymentSheetDebug(_ message: String) {
        print("[CheckoutViewModel] \(message)")
    }

    func preparePaymentSheet(amount: Double, retryCount: Int = 0) {
        let maxRetries = 2
        if retryCount == 0 {
            DispatchQueue.main.async {
                self.paymentSheetErrorMessage = nil
                self.isPreparingPaymentSheet = true
            }
        }
        var urlsToTry = [backendCheckoutUrl, fallbackCheckoutUrl]
        urlsToTry.append(contentsOf: onrenderFallbackCheckoutUrls)
        urlsToTry.append(contentsOf: hardcodedFallbackCheckoutUrls)
        urlsToTry = dedupe(urlsToTry)
        requestPaymentSheet(amount: amount, urlsToTry: urlsToTry, retryCount: retryCount, maxRetries: maxRetries)
    }

    private func dedupe(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { seen.insert($0).inserted }
    }

    private func requestPaymentSheet(
        amount: Double,
        urlsToTry: [URL],
        retryCount: Int,
        maxRetries: Int
    ) {
        guard let checkoutURL = urlsToTry.first else {
            DispatchQueue.main.async {
                self.paymentSheetErrorMessage = "Payment setup failed. Checkout URL is missing."
                self.isPreparingPaymentSheet = false
            }
            return
        }

        var request = URLRequest(url: checkoutURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["amount": amount, "currency": "usd"] as [String: Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        logPaymentSheetDebug("Preparing payment sheet setup request.")
        logPaymentSheetDebug("Request URL: \(checkoutURL.absoluteString)")
        logPaymentSheetDebug("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        logPaymentSheetDebug("Request payload: \(payload)")

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
                self?.logPaymentSheetDebug("Request failed with Swift error: \(error.localizedDescription)")
                handleFailure("Payment setup failed. \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self?.logPaymentSheetDebug("Missing or invalid HTTP response object.")
                handleFailure("Payment setup failed. Invalid server response.")
                return
            }

            guard let data = data else {
                self?.logPaymentSheetDebug("HTTP \(httpResponse.statusCode) with empty response body.")
                handleFailure("Payment setup failed. Empty response.")
                return
            }

            let rawResponseBody = String(data: data, encoding: .utf8) ?? "<non-utf8 body length=\(data.count)>"
            self?.logPaymentSheetDebug("Response status: \(httpResponse.statusCode)")
            self?.logPaymentSheetDebug("Raw response body: \(rawResponseBody)")

            guard (200...299).contains(httpResponse.statusCode) else {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Server error."
                if let stripeError = try? JSONDecoder().decode(StripeErrorResponse.self, from: data).error {
                    let decodedMessage = stripeError.message ?? "Unknown Stripe error"
                    self?.logPaymentSheetDebug("Decoded Stripe error: message=\(decodedMessage), type=\(stripeError.type ?? "nil"), code=\(stripeError.code ?? "nil"), param=\(stripeError.param ?? "nil")")
                } else {
                    self?.logPaymentSheetDebug("Stripe error could not be decoded from response.")
                }
                if httpResponse.statusCode == 404, urlsToTry.count > 1 {
                    self?.requestPaymentSheet(
                        amount: amount,
                        urlsToTry: Array(urlsToTry.dropFirst()),
                        retryCount: retryCount,
                        maxRetries: maxRetries
                    )
                    return
                }
                handleFailure("Payment setup failed. \(serverMessage)")
                return
            }

            do {
                let response = try JSONDecoder().decode(CheckoutResponse.self, from: data)
                self?.logPaymentSheetDebug("Decoded response values: paymentIntent=\(response.paymentIntent), customer=\(response.customer), customerSessionClientSecret=\(response.customerSessionClientSecret ?? "nil"), ephemeralKey=\(response.ephemeralKey ?? "nil"), publishableKey=\(response.publishableKey)")
                STPAPIClient.shared.publishableKey = response.publishableKey

                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Soirée"
                if let customerSessionClientSecret = response.customerSessionClientSecret {
                    configuration.customer = .init(
                        id: response.customer,
                        customerSessionClientSecret: customerSessionClientSecret
                    )
                } else if let ephemeralKey = response.ephemeralKey {
                    configuration.customer = .init(
                        id: response.customer,
                        ephemeralKeySecret: ephemeralKey
                    )
                } else {
                    self?.logPaymentSheetDebug("Missing customerSessionClientSecret and ephemeralKey in checkout response.")
                    handleFailure("Payment setup failed. Missing customer authentication.")
                    return
                }
                configuration.allowsDelayedPaymentMethods = true
                configuration.returnURL = "sioree://stripe-redirect"

                DispatchQueue.main.async {
                    self?.logPaymentSheetDebug("Initializing PaymentSheet with client secret and configuration.")
                    self?.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: response.paymentIntent,
                        configuration: configuration
                    )
                    self?.paymentSheetErrorMessage = nil
                    self?.isPreparingPaymentSheet = false
                }
            } catch {
                self?.logPaymentSheetDebug("JSON decode failed with Swift error: \(error.localizedDescription)")
                handleFailure("Payment setup failed. \(error.localizedDescription)")
            }
        }.resume()
    }

    func onPaymentCompletion(result: PaymentSheetResult) {
        paymentResult = result
    }
}
