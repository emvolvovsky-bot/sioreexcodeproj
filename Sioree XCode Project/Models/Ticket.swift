//
//  Ticket.swift
//  Sioree
//
//  Ticket model for events
//

import Foundation

struct Ticket: Identifiable, Codable {
    let id: String
    let eventId: String
    let userId: String
    let eventTitle: String
    let eventDate: Date
    let eventLocation: String
    let hostName: String
    let price: Double
    let purchaseDate: Date
    let status: TicketStatus
    let qrCodeData: String? // QR code string for validation
    
    enum TicketStatus: String, Codable {
        case valid
        case used
        case cancelled
        case expired
    }
    
    init(id: String = UUID().uuidString,
         eventId: String,
         userId: String,
         eventTitle: String,
         eventDate: Date,
         eventLocation: String,
         hostName: String,
         price: Double,
         purchaseDate: Date = Date(),
         status: TicketStatus = .valid,
         qrCodeData: String? = nil) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.eventTitle = eventTitle
        self.eventDate = eventDate
        self.eventLocation = eventLocation
        self.hostName = hostName
        self.price = price
        self.purchaseDate = purchaseDate
        self.status = status
        self.qrCodeData = qrCodeData
    }
}


