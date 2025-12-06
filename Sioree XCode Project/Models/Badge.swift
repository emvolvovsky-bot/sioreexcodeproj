//
//  Badge.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct Badge: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var icon: String
    var earnedDate: Date?
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         icon: String,
         earnedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.earnedDate = earnedDate
    }
}

// Predefined badges
extension Badge {
    static let eventsAttended10 = Badge(
        name: "Events Attended 10+",
        description: "Attended 10 or more events",
        icon: "star.fill"
    )
    
    static let verifiedHost = Badge(
        name: "Verified Host",
        description: "Verified event host",
        icon: "checkmark.seal.fill"
    )
    
    static let topDJ = Badge(
        name: "Top DJ",
        description: "Top rated DJ",
        icon: "music.note"
    )
    
    static let earlyAdopter = Badge(
        name: "Early Adopter",
        description: "Joined Sioree in early days",
        icon: "sparkles"
    )
}

