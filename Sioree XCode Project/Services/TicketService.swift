//
//  TicketService.swift
//  Sioree
//
//  Ticket purchase and management service
//

import Foundation
import Combine

// MARK: - Ticket Models
struct Ticket: Codable, Identifiable {
    let id: String
    let eventId: String
    let buyerId: String
    let quantity: Int
    let ticketAmountCents: Int
    let feesAmountCents: Int
    let totalAmountCents: Int
    let stripePaymentIntentId: String?
    let stripeChargeId: String?
    let status: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, quantity, status
        case eventId = "event_id"
        case buyerId = "buyer_id"
        case ticketAmountCents = "ticket_amount_cents"
        case feesAmountCents = "fees_amount_cents"
        case totalAmountCents = "total_amount_cents"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case stripeChargeId = "stripe_charge_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TicketPurchase: Codable {
    let tickets: [Ticket]
    let totalPaid: Int
    let paymentIntentId: String
}

// MARK: - TicketService
class TicketService: ObservableObject {
    static let shared = TicketService()

    private let networkService = NetworkService()
    private init() {}

    // MARK: - Get User's Tickets
    func getMyTickets() -> AnyPublisher<[Ticket], Error> {
        return networkService.request("/api/tickets/my-tickets", method: "GET", body: nil)
    }

    // MARK: - Get Event Tickets (for host)
    func getEventTickets(eventId: String) -> AnyPublisher<[Ticket], Error> {
        return networkService.request("/api/tickets/event/\(eventId)", method: "GET", body: nil)
    }

    // MARK: - Validate Ticket (for check-in)
    func validateTicket(ticketId: String) -> AnyPublisher<Ticket, Error> {
        return networkService.request("/api/tickets/\(ticketId)/validate", method: "POST", body: nil)
    }
}
