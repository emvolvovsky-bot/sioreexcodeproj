//
//  PaymentService.swift
//  Sioree
//
//  Payment service placeholder - payments not implemented
//

import Foundation
import Combine

class PaymentService {
    // MARK: - Process Payment (placeholder - returns error)
    func processPayment(amount: Double, method: String, bookingId: String?) -> AnyPublisher<Payment, Error> {
        return Fail(error: NSError(domain: "PaymentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment processing is not implemented"])).eraseToAnyPublisher()
    }

    func getPaymentHistory() -> AnyPublisher<[Payment], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

