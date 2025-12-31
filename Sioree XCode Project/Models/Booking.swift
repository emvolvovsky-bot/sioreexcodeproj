//
//  Booking.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

enum BookingStatus: String, Codable {
    case requested
    case accepted
    case awaiting_payment
    case confirmed
    case declined
    case expired
    case canceled
    case completed
}

enum PaymentStatus: String, Codable {
    case pending
    case paid
    case refunded
    case failed
}

struct Booking: Identifiable, Codable {
    let id: String
    var eventId: String?
    var talentId: String
    var hostId: String
    var date: Date
    var time: Date
    var duration: Int // in hours
    var status: BookingStatus
    var price: Double
    var paymentStatus: PaymentStatus
    var notes: String?
    var createdAt: Date
    var talent: Talent?
    
    init(id: String = UUID().uuidString,
         eventId: String? = nil,
         talentId: String,
         hostId: String,
         date: Date,
         time: Date,
         duration: Int = 4,
         status: BookingStatus = .requested,
         price: Double,
         paymentStatus: PaymentStatus = .pending,
         notes: String? = nil,
         createdAt: Date = Date(),
         talent: Talent? = nil) {
        self.id = id
        self.eventId = eventId
        self.talentId = talentId
        self.hostId = hostId
        self.date = date
        self.time = time
        self.duration = duration
        self.status = status
        self.price = price
        self.paymentStatus = paymentStatus
        self.notes = notes
        self.createdAt = createdAt
        self.talent = talent
    }
}

