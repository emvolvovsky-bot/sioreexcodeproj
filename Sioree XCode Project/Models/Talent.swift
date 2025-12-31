//
//  Talent.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

enum TalentCategory: String, Codable, CaseIterable {
    case dj = "DJ"
    case bartender = "Bartender"
    case photographer = "Photographer"
    case videographer = "Videographer"
    case dancer = "Dancer"
    case security = "Security"
    case staff = "Staff"
    case performer = "Performer"
    case other = "Other"
}

struct Talent: Identifiable, Codable {
    let id: String
    var userId: String
    var name: String
    var category: TalentCategory
    var bio: String?
    var avatar: String?
    var portfolio: [String]
    var rating: Double
    var reviewCount: Int
    var priceRange: PriceRange
    var availability: [Date]
    var verified: Bool
    var location: String?
    var isAvailable: Bool
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         name: String,
         category: TalentCategory,
         bio: String? = nil,
         avatar: String? = nil,
         portfolio: [String] = [],
         rating: Double = 0.0,
         reviewCount: Int = 0,
         priceRange: PriceRange = PriceRange(min: 0, max: 0),
         availability: [Date] = [],
         verified: Bool = false,
         location: String? = nil,
         isAvailable: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.category = category
        self.bio = bio
        self.avatar = avatar
        self.portfolio = portfolio
        self.rating = rating
        self.reviewCount = reviewCount
        self.priceRange = priceRange
        self.availability = availability
        self.verified = verified
        self.location = location
        self.isAvailable = isAvailable
        self.createdAt = createdAt
    }
}

struct PriceRange: Codable {
    var min: Double
    var max: Double
}

