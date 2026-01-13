//
//  EventSignup.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct EventSignup: Identifiable, Codable {
    let id: String
    let signedUpAt: Date
    let eventId: String
    let eventTitle: String
    let eventDate: Date
    let userId: String
    let userName: String
    let userUsername: String
    let userAvatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case signedUpAt
        case eventId
        case eventTitle
        case eventDate
        case userId
        case userName
        case userUsername
        case userAvatar
    }
}

struct EventSignupsResponse: Codable {
    let signups: [EventSignup]
}

