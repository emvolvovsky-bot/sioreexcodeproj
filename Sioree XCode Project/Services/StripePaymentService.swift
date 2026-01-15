//
//  PaymentService.swift
//  Sioree
//
//  Payment processing service placeholder - payments not implemented
//

import Foundation
import Combine

// MARK: - Payment Models (simplified)
struct PaymentIntent {
    let id: String
    let clientSecret: String
    let amount: Double
    let currency: String
    let status: String
}

// MARK: - PaymentService (placeholder)
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()

    private init() {}

    // MARK: - All payment methods return errors (not implemented)
    func createStripeConnectAccount() -> AnyPublisher<Any, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func createAccountLink() -> AnyPublisher<Any, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func getAccountStatus() -> AnyPublisher<Any, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func createTicketPaymentIntent(eventId: String, quantity: Int = 1) -> AnyPublisher<Any, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func processApplePay(amount: Double, hostStripeAccountId: String?, description: String, bookingId: String?) -> AnyPublisher<String, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func createPaymentIntent(amount: Double, hostStripeAccountId: String?, description: String, bookingId: String?) -> AnyPublisher<String, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func confirmPayment(clientSecret: String, paymentMethodId: String?) -> AnyPublisher<Payment, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func confirmPayment(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<Payment, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func getNetworkService() -> NetworkService {
        return NetworkService()
    }
}
