//
//  Event.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

enum EventStatus: String, Codable {
    case draft
    case published
    case cancelled
    case completed
}

struct Event: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var hostId: String
    var hostName: String
    var hostAvatar: String?
    var date: Date
    var time: Date {
        get { date }
        set { date = newValue }
    }
    var location: String
    var locationDetails: String?
    var images: [String]
    var ticketPrice: Double?
    var capacity: Int?
    var attendeeCount: Int
    var talentIds: [String]
    var status: EventStatus
    var createdAt: Date
    var likes: Int
    var isLiked: Bool
    var isSaved: Bool
    var isFeatured: Bool
    var qrCode: String? // Unique QR code for the event
    var lookingForTalentType: String? // Type of talent the host is looking for (e.g., "DJ", "Bartender")
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, images, capacity, likes
        case hostId = "hostId"
        case hostName = "hostName"
        case hostAvatar = "hostAvatar"
        case date
        case locationDetails = "locationDetails"
        case ticketPrice = "ticketPrice"
        case attendeeCount = "attendees"
        case talentIds = "talentIds"
        case status
        case createdAt = "created_at"
        case isLiked = "isLiked"
        case isSaved = "isSaved"
        case isFeatured = "isFeatured"
        case qrCode = "qrCode"
        case lookingForTalentType = "lookingForTalentType"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        hostId = try container.decode(String.self, forKey: .hostId)
        hostName = try container.decode(String.self, forKey: .hostName)
        hostAvatar = try container.decodeIfPresent(String.self, forKey: .hostAvatar)
        date = try container.decode(Date.self, forKey: .date)
        location = try container.decode(String.self, forKey: .location)
        locationDetails = try container.decodeIfPresent(String.self, forKey: .locationDetails)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        // Handle ticketPrice as either Double or String
        if let price = try? container.decodeIfPresent(Double.self, forKey: .ticketPrice) {
            ticketPrice = price
        } else if let priceString = try? container.decodeIfPresent(String.self, forKey: .ticketPrice),
                  let price = Double(priceString), price > 0 {
            ticketPrice = price
        } else {
            ticketPrice = nil
        }
        capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        attendeeCount = try container.decodeIfPresent(Int.self, forKey: .attendeeCount) ?? 0
        talentIds = try container.decodeIfPresent([String].self, forKey: .talentIds) ?? []
        status = try container.decodeIfPresent(EventStatus.self, forKey: .status) ?? .published
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        qrCode = try container.decodeIfPresent(String.self, forKey: .qrCode)
        lookingForTalentType = try container.decodeIfPresent(String.self, forKey: .lookingForTalentType)
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         hostId: String,
         hostName: String,
         hostAvatar: String? = nil,
         date: Date,
         time: Date,
         location: String,
         locationDetails: String? = nil,
         images: [String] = [],
         ticketPrice: Double? = nil,
         capacity: Int? = nil,
         attendeeCount: Int = 0,
         talentIds: [String] = [],
         status: EventStatus = .draft,
         createdAt: Date = Date(),
         likes: Int = 0,
         isLiked: Bool = false,
         isSaved: Bool = false,
         isFeatured: Bool = false,
         qrCode: String? = nil,
         lookingForTalentType: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.hostId = hostId
        self.hostName = hostName
        self.hostAvatar = hostAvatar
        // Set date from time parameter (since time is a computed property that uses date)
        self.date = time
        self.location = location
        self.locationDetails = locationDetails
        self.images = images
        self.ticketPrice = ticketPrice
        self.capacity = capacity
        self.attendeeCount = attendeeCount
        self.talentIds = talentIds
        self.status = status
        self.createdAt = createdAt
        self.likes = likes
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.isFeatured = isFeatured
        self.qrCode = qrCode
        self.lookingForTalentType = lookingForTalentType
    }
    
    // Generate unique QR code for event
    static func generateEventQRCode(eventId: String) -> String {
        // Create a unique QR code string for the event
        let qrData = "sioree:event:\(eventId):\(UUID().uuidString)"
        return qrData
    }
}

