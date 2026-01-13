//
//  Post.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct Post: Identifiable, Codable {
    let id: String
    var userId: String
    var userName: String
    var userAvatar: String?
    var images: [String]
    var caption: String?
    var likes: Int
    var comments: Int
    var isLiked: Bool
    var isSaved: Bool
    var location: String?
    var eventId: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName = "name"
        case userAvatar = "avatar"
        case images
        case caption
        case likes
        case comments
        case isLiked
        case isSaved
        case location
        case eventId
        case createdAt
        case username
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
        
        // Handle userId as String or Int
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = userIdString
        } else if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = String(userIdInt)
        } else {
            userId = ""
        }
        
        // Handle userName - try "name" first, then "userName", then "username"
        if let name = try? container.decode(String.self, forKey: .userName) {
            userName = name
        } else if let name = try? container.decode(String.self, forKey: .username) {
            userName = name
        } else {
            userName = ""
        }
        
        userAvatar = try container.decodeIfPresent(String.self, forKey: .userAvatar)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        comments = try container.decodeIfPresent(Int.self, forKey: .comments) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
        location = try container.decodeIfPresent(String.self, forKey: .location)
        eventId = try container.decodeIfPresent(String.self, forKey: .eventId)
        
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
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        // Encode userName as "name" (matching the CodingKeys mapping)
        try container.encode(userName, forKey: .userName)
        // Encode userAvatar as "avatar" (matching the CodingKeys mapping)
        try container.encodeIfPresent(userAvatar, forKey: .userAvatar)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(caption, forKey: .caption)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(isLiked, forKey: .isLiked)
        try container.encode(isSaved, forKey: .isSaved)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(eventId, forKey: .eventId)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         userName: String,
         userAvatar: String? = nil,
         images: [String] = [],
         caption: String? = nil,
         likes: Int = 0,
         comments: Int = 0,
         isLiked: Bool = false,
         isSaved: Bool = false,
         location: String? = nil,
         eventId: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.images = images
        self.caption = caption
        self.likes = likes
        self.comments = comments
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.location = location
        self.eventId = eventId
        self.createdAt = createdAt
    }
}

