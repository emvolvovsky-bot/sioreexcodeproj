//
//  StripePaymentService.swift
//  Sioree
//
//  Stripe payment processing service
//

import Foundation
import Combine

// MARK: - Stripe Models
struct StripePaymentIntent: Codable {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: String
}

struct StripePaymentMethod: Codable {
    let id: String
    let type: String
    let card: StripeCard?
}

struct StripeCard: Codable {
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int
}

// MARK: - StripePaymentService
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()

    private let networkService = NetworkService()
    private let baseURL = "https://api.stripe.com/v1"

    private init() {}

    // MARK: - Apple Pay Processing
    func processApplePay(amount: Double, hostStripeAccountId: String?, description: String, bookingId: String?) -> AnyPublisher<String, Error> {
        let body: [String: Any] = [
            "amount": Int(amount * 100), // Convert to cents
            "currency": "usd",
            "description": description,
            "bookingId": bookingId,
            "hostStripeAccountId": hostStripeAccountId
        ].compactMapValues { $0 }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        return networkService.request("/api/payments/apple-pay", method: "POST", body: jsonData)
            .map { (response: [String: String]) in
                response["clientSecret"] ?? ""
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Payment Intent Creation
    func createPaymentIntent(amount: Double, hostStripeAccountId: String?, description: String, bookingId: String?) -> AnyPublisher<String, Error> {
        let body: [String: Any] = [
            "amount": Int(amount * 100), // Convert to cents
            "currency": "usd",
            "description": description,
            "bookingId": bookingId,
            "hostStripeAccountId": hostStripeAccountId
        ].compactMapValues { $0 }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        return networkService.request("/api/payments/create-intent", method: "POST", body: jsonData)
            .map { (response: [String: String]) in
                response["clientSecret"] ?? ""
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Payment Confirmation
    func confirmPayment(clientSecret: String, paymentMethodId: String?) -> AnyPublisher<Payment, Error> {
        let body: [String: Any] = [
            "clientSecret": clientSecret,
            "paymentMethodId": paymentMethodId
        ].compactMapValues { $0 }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        return networkService.request("/api/payments/confirm", method: "POST", body: jsonData)
    }

    // MARK: - Alternative Payment Confirmation (for compatibility)
    func confirmPayment(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<Payment, Error> {
        // Stub implementation - payments not implemented yet
        return Fail(error: NSError(domain: "StripePaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payments not implemented yet"]))
            .eraseToAnyPublisher()
    }

    // MARK: - Network Service Access
    func getNetworkService() -> NetworkService {
        return networkService
    }
}
