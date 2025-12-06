//
//  Review.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct Review: Identifiable, Codable {
    let id: String
    let reviewerId: String
    let reviewerName: String
    let reviewerUsername: String
    let reviewerAvatar: String?
    let reviewedUserId: String
    let rating: Int
    let comment: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case reviewerId
        case reviewerName
        case reviewerUsername
        case reviewerAvatar
        case reviewedUserId
        case rating
        case comment
        case createdAt
        case updatedAt
    }
}

struct ReviewsResponse: Codable {
    let reviews: [Review]
}

