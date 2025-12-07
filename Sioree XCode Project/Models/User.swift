//
//  User.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

enum UserType: String, Codable {
    case host
    case partier
    case talent
    case brand
}

struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var username: String
    var name: String
    var bio: String?
    var avatar: String?
    var userType: UserType
    var location: String?
    var verified: Bool
    var createdAt: Date
    var followerCount: Int
    var followingCount: Int
    var eventCount: Int
    var badges: [Badge]
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case name
        case bio
        case avatar
        case userType
        case location
        case verified
        case createdAt
        case followerCount
        case followingCount
        case eventCount
        case badges
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as String or Int
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }
        
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        name = try container.decode(String.self, forKey: .name)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        
        // Handle userType as string
        if let userTypeString = try? container.decode(String.self, forKey: .userType),
           let type = UserType(rawValue: userTypeString) {
            userType = type
        } else {
            userType = .partier
        }
        
        location = try container.decodeIfPresent(String.self, forKey: .location)
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
        
        // Handle date decoding
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? Date()
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            createdAt = Date()
        }
        
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        eventCount = try container.decodeIfPresent(Int.self, forKey: .eventCount) ?? 0
        badges = try container.decodeIfPresent([Badge].self, forKey: .badges) ?? []
    }
    
    init(id: String = UUID().uuidString,
         email: String,
         username: String,
         name: String,
         bio: String? = nil,
         avatar: String? = nil,
         userType: UserType,
         location: String? = nil,
         verified: Bool = false,
         createdAt: Date = Date(),
         followerCount: Int = 0,
         followingCount: Int = 0,
         eventCount: Int = 0,
         badges: [Badge] = []) {
        self.id = id
        self.email = email
        self.username = username
        self.name = name
        self.bio = bio
        self.avatar = avatar
        self.userType = userType
        self.location = location
        self.verified = verified
        self.createdAt = createdAt
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.eventCount = eventCount
        self.badges = badges
    }
    
    // MARK: - Equatable
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.username == rhs.username &&
               lhs.name == rhs.name &&
               lhs.bio == rhs.bio &&
               lhs.avatar == rhs.avatar &&
               lhs.userType == rhs.userType &&
               lhs.location == rhs.location &&
               lhs.verified == rhs.verified &&
               lhs.createdAt == rhs.createdAt &&
               lhs.followerCount == rhs.followerCount &&
               lhs.followingCount == rhs.followingCount &&
               lhs.eventCount == rhs.eventCount &&
               lhs.badges == rhs.badges
    }
}

