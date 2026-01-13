//
//  PaymentService.swift
//  Sioree
//
//  Real payment processing - now uses StripePaymentService
//

import Foundation
import Combine

class PaymentService {
    private let stripeService = StripePaymentService.shared
    private let networkService = NetworkService()
    
    // MARK: - Process Payment (delegates to Stripe)
    func processPayment(amount: Double, method: PaymentMethod, bookingId: String?) -> AnyPublisher<Payment, Error> {
        switch method {
        case .applePay:
            return stripeService.processApplePay(
                amount: amount,
                hostStripeAccountId: nil as String?,
                description: "Sioree Payment",
                bookingId: bookingId
            )
            .map { clientSecret in
                // Return pending payment - actual confirmation happens in checkout view
                return Payment(
                    userId: StorageService.shared.getUserId() ?? "",
                    amount: amount,
                    method: method,
                    status: .pending,
                    transactionId: clientSecret.components(separatedBy
                                                           : "_secret_").first,
                    description: "Payment pending confirmation"
                )
            }
            .eraseToAnyPublisher()
        case .creditCard, .debitCard:
            // For card payments, use the checkout flow
            // This will be handled by PaymentCheckoutView
            return stripeService.createPaymentIntent(
                amount: amount,
                hostStripeAccountId: nil as String?,
                description: "Sioree Payment",
                bookingId: bookingId
            )
            .map { clientSecret in
                // Return a pending payment - actual confirmation happens in checkout view
                return Payment(
                    userId: StorageService.shared.getUserId() ?? "",
                    amount: amount,
                    method: method,
                    status: .pending,
                    transactionId: clientSecret.components(separatedBy: "_secret_").first,
                    description: "Payment pending confirmation"
                )
            }
            .eraseToAnyPublisher()
        default:
            // For other methods, use legacy endpoint
            var body: [String: Any] = [
                "amount": amount,
                "method": method.rawValue
            ]
            
            if let bookingId = bookingId {
                body["bookingId"] = bookingId
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
            }
            
            return networkService.request("/api/payments", method: "POST", body: jsonData)
        }
    }
    
    func getPaymentHistory() -> AnyPublisher<[Payment], Error> {
        return networkService.request("/api/payments")
    }
}

