//
//  GroupChat.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct GroupChat: Identifiable, Codable {
    let id: String
    var title: String
    var members: [GroupMember]
    var createdAt: Date
    var lastMessage: String?
    var lastMessageTime: Date?
    var unreadCount: Int
    
    init(id: String = UUID().uuidString,
         title: String,
         members: [GroupMember] = [],
         createdAt: Date = Date(),
         lastMessage: String? = nil,
         lastMessageTime: Date? = nil,
         unreadCount: Int = 0) {
        self.id = id
        self.title = title
        self.members = members
        self.createdAt = createdAt
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}

struct GroupMember: Identifiable, Codable {
    let id: String
    var name: String
    var username: String
    var avatar: String?
    var role: GroupMemberRole
    
    enum GroupMemberRole: String, Codable {
        case admin
        case member
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         username: String = "",
         avatar: String? = nil,
         role: GroupMemberRole = .member) {
        self.id = id
        self.name = name
        self.username = username
        self.avatar = avatar
        self.role = role
    }
}








