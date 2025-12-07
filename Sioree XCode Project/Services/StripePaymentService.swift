//
//  StripePaymentService.swift
//  Sioree
//
//  Real payment processing with Stripe
//

import Foundation
import Combine
import PassKit // For Apple Pay

struct StripePaymentIntent: Codable {
    let clientSecret: String
    let paymentIntentId: String
    
    init(clientSecret: String) {
        self.clientSecret = clientSecret
        // Extract payment intent ID from client secret (format: pi_xxx_secret_yyy)
        if let piIndex = clientSecret.range(of: "pi_") {
            let afterPi = clientSecret[piIndex.upperBound...]
            if let secretIndex = afterPi.range(of: "_secret_") {
                self.paymentIntentId = String(clientSecret[piIndex.lowerBound..<secretIndex.lowerBound])
            } else {
                self.paymentIntentId = ""
            }
        } else {
            self.paymentIntentId = ""
        }
    }
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

class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()
    private let networkService = NetworkService()
    
    // MARK: - Create Payment Intent
    func createPaymentIntent(amount: Double, hostStripeAccountId: String? = nil, description: String? = nil, bookingId: String? = nil) -> AnyPublisher<String, Error> {
        var body: [String: Any] = [
            "amount": amount // Send as dollars, backend will convert to cents
        ]
        
        if let hostStripeAccountId = hostStripeAccountId {
            body["hostStripeAccountId"] = hostStripeAccountId
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let clientSecret: String
        }
        
        return networkService.request("/api/payments/create-intent", method: "POST", body: jsonData)
            .map { (response: Response) in
                response.clientSecret
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Confirm Payment
    func confirmPayment(paymentIntentId: String, paymentMethodId: String) -> AnyPublisher<Payment, Error> {
        let body: [String: Any] = [
            "paymentIntentId": paymentIntentId,
            "paymentMethodId": paymentMethodId
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        struct PaymentResponse: Codable {
            let id: String
            let userId: String
            let amount: Double
            let method: String
            let status: String
            let transactionId: String?
            let description: String?
            let createdAt: String
        }
        
        return networkService.request("/api/payments/confirm", method: "POST", body: jsonData)
            .map { (response: PaymentResponse) -> Payment in
                // Convert response to Payment model
                let paymentMethod: PaymentMethod
                switch response.method {
                case "credit_card", "debit_card":
                    paymentMethod = response.method == "credit_card" ? .creditCard : .debitCard
                case "apple_pay":
                    paymentMethod = .applePay
                default:
                    paymentMethod = .creditCard
                }
                
                let paymentStatus: PaymentStatus
                switch response.status {
                case "paid":
                    paymentStatus = .paid
                case "pending":
                    paymentStatus = .pending
                case "failed":
                    paymentStatus = .failed
                case "refunded":
                    paymentStatus = .refunded
                default:
                    paymentStatus = .pending
                }
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let createdAt = dateFormatter.date(from: response.createdAt) ?? Date()
                
                return Payment(
                    id: response.id,
                    userId: response.userId,
                    amount: response.amount,
                    method: paymentMethod,
                    status: paymentStatus,
                    transactionId: response.transactionId,
                    description: response.description,
                    createdAt: createdAt
                )
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Process Apple Pay
    func processApplePay(amount: Double, hostStripeAccountId: String? = nil, description: String? = nil, bookingId: String? = nil) -> AnyPublisher<String, Error> {
        // Create payment intent and return clientSecret for Apple Pay
        return createPaymentIntent(amount: amount, hostStripeAccountId: hostStripeAccountId, description: description, bookingId: bookingId)
    }
    
    // MARK: - Save Payment Method
    func savePaymentMethod(paymentMethodId: String, setAsDefault: Bool = false) -> AnyPublisher<Bool, Error> {
        let body: [String: Any] = [
            "paymentMethodId": paymentMethodId,
            "setAsDefault": setAsDefault
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let success: Bool
        }
        
        return networkService.request("/api/payments/save-method", method: "POST", body: jsonData)
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Payment Methods
    func getPaymentMethods() -> AnyPublisher<[StripePaymentMethod], Error> {
        struct Response: Codable {
            let paymentMethods: [StripePaymentMethod]
        }
        
        return networkService.request("/api/payments/methods")
            .map { (response: Response) in response.paymentMethods }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Delete Payment Method
    func deletePaymentMethod(paymentMethodId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        
        return networkService.request("/api/payments/methods/\(paymentMethodId)", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Expose Network Service
    func getNetworkService() -> NetworkService {
        return networkService
    }
}

