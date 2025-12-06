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

