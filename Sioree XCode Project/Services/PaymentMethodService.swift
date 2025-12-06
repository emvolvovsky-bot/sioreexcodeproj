//
//  PaymentMethodService.swift
//  Sioree
//
//  Service for managing saved payment methods
//

import Foundation
import Combine

struct SavedPaymentMethod: Identifiable, Codable {
    let id: String
    let type: String // "card", "apple_pay", "bank_account"
    let last4: String?
    let brand: String? // "visa", "mastercard", etc.
    let expMonth: Int?
    let expYear: Int?
    let isDefault: Bool
    let createdAt: Date
}

struct PaymentMethodListResponse: Codable {
    let paymentMethods: [SavedPaymentMethod]
}

class PaymentMethodService: ObservableObject {
    static let shared = PaymentMethodService()
    private let networkService = NetworkService()
    
    // MARK: - Get Saved Payment Methods
    func getSavedPaymentMethods() -> AnyPublisher<[SavedPaymentMethod], Error> {
        struct Response: Codable {
            let paymentMethods: [SavedPaymentMethod]
        }
        return networkService.request("/api/payments/methods", method: "GET")
            .map { (response: Response) in response.paymentMethods }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Save Payment Method
    func savePaymentMethod(paymentMethodId: String, setAsDefault: Bool = false) -> AnyPublisher<SavedPaymentMethod, Error> {
        let body: [String: Any] = [
            "paymentMethodId": paymentMethodId,
            "setAsDefault": setAsDefault
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request("/api/payments/save-method", method: "POST", body: jsonData)
    }
    
    // MARK: - Delete Payment Method
    func deletePaymentMethod(_ methodId: String) -> AnyPublisher<Bool, Error> {
        return networkService.request("/api/payments/methods/\(methodId)", method: "DELETE")
            .map { (_: EmptyResponse) in true }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Set Default Payment Method
    func setDefaultPaymentMethod(_ methodId: String) -> AnyPublisher<Bool, Error> {
        let body: [String: Any] = ["paymentMethodId": methodId]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request("/api/payments/set-default", method: "POST", body: jsonData)
            .map { (_: EmptyResponse) in true }
            .eraseToAnyPublisher()
    }
}

struct EmptyResponse: Codable {}


