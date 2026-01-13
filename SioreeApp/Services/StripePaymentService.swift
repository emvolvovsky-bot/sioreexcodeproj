//
//  StripePaymentService.swift
//  Sioree
//
//  Stripe payment processing service with Stripe Connect support
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

struct StripeConnectAccount: Codable {
    let account_id: String
}

struct StripeAccountLink: Codable {
    let url: String
    let expires_at: Int
}

struct StripeAccountStatus: Codable {
    let onboarding_complete: Bool
    let charges_enabled: Bool
    let payouts_enabled: Bool
    let needs_onboarding: Bool
    let account_id: String?
}

struct StripeCheckoutIntent: Codable {
    let paymentIntent: StripePaymentIntent
    let pricing: StripePricing
}

struct StripePricing: Codable {
    let ticket_price_cents: Int
    let quantity: Int
    let ticket_amount_cents: Int
    let fees_amount_cents: Int
    let total_amount_cents: Int
    let platform_fee_percentage: String
}

// MARK: - StripePaymentService
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()

    private let networkService = NetworkService()
    private let baseURL = "https://api.stripe.com/v1"

    private init() {}

    // MARK: - Stripe Connect Host Onboarding
    func createStripeConnectAccount() -> AnyPublisher<StripeConnectAccount, Error> {
        return networkService.request("/api/stripe/connect/create-account", method: "POST", body: nil)
    }

    func createAccountLink() -> AnyPublisher<StripeAccountLink, Error> {
        return networkService.request("/api/stripe/connect/create-account-link", method: "POST", body: nil)
    }

    func getAccountStatus() -> AnyPublisher<StripeAccountStatus, Error> {
        return networkService.request("/api/stripe/connect/status", method: "GET", body: nil)
    }

    // MARK: - Ticket Checkout with Stripe Connect
    func createTicketPaymentIntent(eventId: String, quantity: Int = 1) -> AnyPublisher<StripeCheckoutIntent, Error> {
        let body: [String: Any] = [
            "event_id": eventId,
            "quantity": quantity
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        return networkService.request("/api/stripe/checkout/create-payment-intent", method: "POST", body: jsonData)
    }

    // MARK: - Apple Pay Processing (Legacy - kept for compatibility)
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
