//
//  CheckoutViewModel.swift
//  Sioree
//
//  Checkout view model placeholder - payments not implemented
//

import Foundation
import StripePaymentSheet
import StripeCore

class CheckoutViewModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var paymentSheetErrorMessage: String?
    @Published var isPreparingPaymentSheet = false
    @Published var lastBackendStatus: String?
    @Published var lastBackendBody: String?
    @Published var lastStripeError: String?

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
        #if DEBUG
        print("[CheckoutViewModel] \(message)")
        #endif
    }

    private func redactedValue(_ value: String, prefixLength: Int = 6, suffixLength: Int = 6) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > prefixLength + suffixLength else {
            return trimmed
        }
        let prefix = trimmed.prefix(prefixLength)
        let suffix = trimmed.suffix(suffixLength)
        return "\(prefix)...\(suffix)"
    }

    private func redactedJSONPayload(from data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        let redactedObject = redactSensitiveFields(in: jsonObject)
        guard let prettyData = try? JSONSerialization.data(withJSONObject: redactedObject, options: [.prettyPrinted]) else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }

    private func redactSensitiveFields(in jsonObject: Any) -> Any {
        if var dict = jsonObject as? [String: Any] {
            if let paymentIntent = dict["paymentIntent"] as? String {
                dict["paymentIntent"] = redactedValue(paymentIntent)
            }
            if let publishableKey = dict["publishableKey"] as? String {
                dict["publishableKey"] = redactedValue(publishableKey)
            }
            return dict
        }
        if let array = jsonObject as? [Any] {
            return array.map { redactSensitiveFields(in: $0) }
        }
        return jsonObject
    }

    private func redactedResponseBody(from data: Data) -> String {
        if let redactedJSON = redactedJSONPayload(from: data) {
            return redactedJSON
        }
        return String(data: data, encoding: .utf8) ?? "<non-utf8 body length=\(data.count)>"
    }

    private func publishableKeyMode(_ key: String) -> String {
        if key.hasPrefix("pk_test_") {
            return "test"
        }
        if key.hasPrefix("pk_live_") {
            return "live"
        }
        return "unknown"
    }

    private func preferredStripeMode() -> String? {
        let key = Constants.Stripe.publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.hasPrefix("pk_test_") {
            return "test"
        }
        if key.hasPrefix("pk_live_") {
            return "live"
        }
        return nil
    }

    private func validateCheckoutResponse(_ response: CheckoutResponse) -> String? {
        if response.paymentIntent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Missing paymentIntent."
        }
        if !response.paymentIntent.contains("_secret_") {
            return "paymentIntent is not a client secret."
        }
        if response.customer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Missing customer."
        }
        let hasEphemeralKey = !(response.ephemeralKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasCustomerSession = !(response.customerSessionClientSecret?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if !hasEphemeralKey && !hasCustomerSession {
            return "Missing ephemeralKey or customer session."
        }
        if response.publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Missing publishableKey."
        }
        let publishableKeyPrefixValid = response.publishableKey.hasPrefix("pk_test_") || response.publishableKey.hasPrefix("pk_live_")
        if !publishableKeyPrefixValid {
            return "publishableKey is not a Stripe publishable key."
        }
        return nil
    }

    func preparePaymentSheet(amount: Double, eventId: String? = nil, retryCount: Int = 0) {
        let maxRetries = 2
        if retryCount == 0 {
            DispatchQueue.main.async {
                self.paymentSheetErrorMessage = nil
                self.isPreparingPaymentSheet = true
                self.lastBackendStatus = nil
                self.lastBackendBody = nil
                self.lastStripeError = nil
            }
        }
        var urlsToTry = [backendCheckoutUrl, fallbackCheckoutUrl]
        urlsToTry.append(contentsOf: onrenderFallbackCheckoutUrls)
        urlsToTry.append(contentsOf: hardcodedFallbackCheckoutUrls)
        urlsToTry = dedupe(urlsToTry)
        requestPaymentSheet(amount: amount, eventId: eventId, urlsToTry: urlsToTry, retryCount: retryCount, maxRetries: maxRetries)
    }

    private func dedupe(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { seen.insert($0).inserted }
    }

    private func requestPaymentSheet(
        amount: Double,
        eventId: String?,
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

        var payload: [String: Any] = ["amount": amount, "currency": "usd"]
        if let eventId = eventId, !eventId.isEmpty {
            payload["eventId"] = eventId
        }
        if let mode = preferredStripeMode() {
            payload["mode"] = mode
        }
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
                        self.preparePaymentSheet(amount: amount, eventId: eventId, retryCount: retryCount + 1)
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

            let rawResponseBody = self?.redactedResponseBody(from: data) ?? "<unavailable>"
            let statusText = "HTTP \(httpResponse.statusCode)"
            DispatchQueue.main.async {
                self?.lastBackendStatus = statusText
                self?.lastBackendBody = rawResponseBody
            }
            self?.logPaymentSheetDebug("Response status: \(httpResponse.statusCode)")
            self?.logPaymentSheetDebug("Raw response body: \(rawResponseBody)")
            if let prettyJSON = self?.redactedJSONPayload(from: data) {
                self?.logPaymentSheetDebug("Decoded JSON body:\n\(prettyJSON)")
            }

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
                        eventId: eventId,
                        urlsToTry: Array(urlsToTry.dropFirst()),
                        retryCount: retryCount,
                        maxRetries: maxRetries
                    )
                    return
                }
                let snippet = String(serverMessage.prefix(500))
                handleFailure("Payment setup failed (HTTP \(httpResponse.statusCode)). Response: \(snippet)")
                return
            }

            do {
                let response = try JSONDecoder().decode(CheckoutResponse.self, from: data)
                let redactedPaymentIntent = self?.redactedValue(response.paymentIntent) ?? "<unavailable>"
                let redactedPublishableKey = self?.redactedValue(response.publishableKey) ?? "<unavailable>"
                self?.logPaymentSheetDebug("Decoded response values: paymentIntent=\(redactedPaymentIntent), customer=\(response.customer), customerSessionClientSecret=\(response.customerSessionClientSecret ?? "nil"), ephemeralKey=\(response.ephemeralKey ?? "nil"), publishableKey=\(redactedPublishableKey)")
                if let validationError = self?.validateCheckoutResponse(response) {
                    self?.logPaymentSheetDebug("Payment sheet payload validation failed: \(validationError)")
                    self?.logPaymentSheetDebug("Full payload (redacted): \(rawResponseBody)")
                    handleFailure("Payment setup failed. \(validationError)")
                    return
                }

                let mode = self?.publishableKeyMode(response.publishableKey) ?? "unknown"
                self?.logPaymentSheetDebug("Stripe mode from publishable key: \(mode)")
                if let preferredMode = self?.preferredStripeMode(),
                   mode != "unknown",
                   preferredMode != mode {
                    self?.logPaymentSheetDebug("Stripe mode mismatch: preferred=\(preferredMode), response=\(mode)")
                    handleFailure("Payment setup failed. Backend returned \(mode) publishable key but app expects \(preferredMode).")
                    return
                }
                if Constants.API.environment == .production, mode == "test" {
                    self?.logPaymentSheetDebug("Warning: Production environment using test publishable key.")
                } else if Constants.API.environment == .development, mode == "live" {
                    self?.logPaymentSheetDebug("Warning: Development environment using live publishable key.")
                } else if mode == "unknown" {
                    self?.logPaymentSheetDebug("Warning: Publishable key prefix is not recognized.")
                }

                StripeAPI.defaultPublishableKey = response.publishableKey
                STPAPIClient.shared.publishableKey = response.publishableKey

                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Soirée"
                configuration.apiClient = STPAPIClient.shared
                if let ephemeralKey = response.ephemeralKey {
                    configuration.customer = .init(
                        id: response.customer,
                        ephemeralKeySecret: ephemeralKey
                    )
                } else if response.customerSessionClientSecret != nil {
                    self?.logPaymentSheetDebug("Customer session provided but not used; presenting without customer.")
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
        switch result {
        case .completed:
            logPaymentSheetDebug("PaymentSheet result: completed")
            DispatchQueue.main.async {
                self.lastStripeError = nil
            }
        case .canceled:
            logPaymentSheetDebug("PaymentSheet result: canceled")
            DispatchQueue.main.async {
                self.lastStripeError = "Payment canceled."
            }
        case .failed(let error):
            logPaymentSheetDebug("PaymentSheet result: failed")
            logPaymentSheetDebug("Stripe error localizedDescription: \(error.localizedDescription)")
            logPaymentSheetDebug("Stripe error full: \(String(describing: error))")
            DispatchQueue.main.async {
                self.lastStripeError = "Payment failed: \(error.localizedDescription)"
            }
        }
    }
}
