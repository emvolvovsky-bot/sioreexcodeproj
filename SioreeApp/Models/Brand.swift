//
//  Brand.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct Brand: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var logo: String?
    var website: String?
    var category: String?
    var verified: Bool
    var followerCount: Int
    var eventCount: Int
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String? = nil,
         logo: String? = nil,
         website: String? = nil,
         category: String? = nil,
         verified: Bool = false,
         followerCount: Int = 0,
         eventCount: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.logo = logo
        self.website = website
        self.category = category
        self.verified = verified
        self.followerCount = followerCount
        self.eventCount = eventCount
        self.createdAt = createdAt
    }
}

