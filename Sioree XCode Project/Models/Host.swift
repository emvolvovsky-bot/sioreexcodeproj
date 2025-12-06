//
//  Host.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct Host: Identifiable, Codable {
    let id: String
    var name: String
    var bio: String?
    var avatar: String?
    var verified: Bool
    var followerCount: Int
    var eventCount: Int
    var badges: [Badge]
    var location: String?
    var website: String?
    var socialLinks: [String: String]?
    
    init(id: String = UUID().uuidString,
         name: String,
         bio: String? = nil,
         avatar: String? = nil,
         verified: Bool = false,
         followerCount: Int = 0,
         eventCount: Int = 0,
         badges: [Badge] = [],
         location: String? = nil,
         website: String? = nil,
         socialLinks: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.avatar = avatar
        self.verified = verified
        self.followerCount = followerCount
        self.eventCount = eventCount
        self.badges = badges
        self.location = location
        self.website = website
        self.socialLinks = socialLinks
    }
}

