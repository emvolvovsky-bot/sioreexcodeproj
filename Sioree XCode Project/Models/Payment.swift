//
//  Payment.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

enum PaymentMethod: String, Codable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case applePay = "apple_pay"
    case venmo = "venmo"
    case cash = "cash"
}

struct Payment: Identifiable, Codable {
    let id: String
    var userId: String
    var amount: Double
    var method: PaymentMethod
    var status: PaymentStatus
    var transactionId: String?
    var description: String?
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         amount: Double,
         method: PaymentMethod,
         status: PaymentStatus = .pending,
         transactionId: String? = nil,
         description: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.method = method
        self.status = status
        self.transactionId = transactionId
        self.description = description
        self.createdAt = createdAt
    }
}

