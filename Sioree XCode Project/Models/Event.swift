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

struct Event: Identifiable, Codable, Hashable {
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
    var lookingForRoles: [String]
    var lookingForNotes: String?
    var status: EventStatus
    var createdAt: Date
    var likes: Int
    var isLiked: Bool
    var isSaved: Bool
    var isFeatured: Bool
    var isRSVPed: Bool // Whether the current user has RSVPed to this event
    var qrCode: String? // Unique QR code for the event
    var lookingForTalentType: String? // Type of talent the host is looking for (e.g., "DJ", "Bartender")
    var isPrivate: Bool // Whether the event requires an access code
    var accessCode: String? // Access code required for private events
    
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
        case isRSVPed = "isRSVPed"
        case qrCode = "qrCode"
        case lookingForTalentType = "lookingForTalentType"
        case lookingForTalentTypeSnake = "looking_for_talent_type"
        case talentNeeded = "talentNeeded"
        case lookingForRoles = "lookingForRoles"
        case lookingForRolesSnake = "looking_for_roles"
        case lookingForNotes = "lookingForNotes"
        case lookingForNotesSnake = "looking_for_notes"
        case isPrivate = "isPrivate"
        case isPrivateSnake = "is_private"
        case accessCode = "accessCode"
        case accessCodeSnake = "access_code"
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
        let camelRoles = try container.decodeIfPresent([String].self, forKey: .lookingForRoles) ?? []
        let snakeRoles = try container.decodeIfPresent([String].self, forKey: .lookingForRolesSnake) ?? []
        lookingForRoles = camelRoles.isEmpty ? snakeRoles : camelRoles
        if let primaryNotes = try container.decodeIfPresent(String.self, forKey: .lookingForNotes) {
            lookingForNotes = primaryNotes
        } else if let snakeNotes = try container.decodeIfPresent(String.self, forKey: .lookingForNotesSnake) {
            lookingForNotes = snakeNotes
        } else {
            lookingForNotes = nil
        }
        status = try container.decodeIfPresent(EventStatus.self, forKey: .status) ?? .published
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        isRSVPed = try container.decodeIfPresent(Bool.self, forKey: .isRSVPed) ?? false
        qrCode = try container.decodeIfPresent(String.self, forKey: .qrCode)
        let camelCaseIsPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate)
        let snakeCaseIsPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivateSnake)
        isPrivate = camelCaseIsPrivate ?? snakeCaseIsPrivate ?? false
        let camelCaseAccessCode = try container.decodeIfPresent(String.self, forKey: .accessCode)
        let snakeCaseAccessCode = try container.decodeIfPresent(String.self, forKey: .accessCodeSnake)
        accessCode = camelCaseAccessCode ?? snakeCaseAccessCode
        let camelCaseLookingFor = try container.decodeIfPresent(String.self, forKey: .lookingForTalentType)
        let snakeCaseLookingFor = try container.decodeIfPresent(String.self, forKey: .lookingForTalentTypeSnake)
        let talentNeeded = try container.decodeIfPresent(String.self, forKey: .talentNeeded)
        let baseLookingFor = camelCaseLookingFor ?? snakeCaseLookingFor ?? talentNeeded
        lookingForTalentType = Event.resolveLookingForSummary(
            roles: lookingForRoles,
            label: baseLookingFor,
            notes: lookingForNotes
        )
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
         lookingForRoles: [String] = [],
         lookingForNotes: String? = nil,
         status: EventStatus = .draft,
         createdAt: Date = Date(),
         likes: Int = 0,
         isLiked: Bool = false,
         isSaved: Bool = false,
         isFeatured: Bool = false,
        isRSVPed: Bool = false,
        qrCode: String? = nil,
        lookingForTalentType: String? = nil,
        isPrivate: Bool = false,
        accessCode: String? = nil) {
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
        self.lookingForRoles = lookingForRoles
        self.lookingForNotes = lookingForNotes
        self.status = status
        self.createdAt = createdAt
        self.likes = likes
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.isFeatured = isFeatured
        self.isRSVPed = isRSVPed
        self.qrCode = qrCode
        self.isPrivate = isPrivate
        self.accessCode = accessCode
        self.lookingForTalentType = Event.resolveLookingForSummary(
            roles: lookingForRoles,
            label: lookingForTalentType,
            notes: lookingForNotes
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(hostId, forKey: .hostId)
        try container.encode(hostName, forKey: .hostName)
        try container.encodeIfPresent(hostAvatar, forKey: .hostAvatar)
        try container.encode(date, forKey: .date)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(locationDetails, forKey: .locationDetails)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(ticketPrice, forKey: .ticketPrice)
        try container.encodeIfPresent(capacity, forKey: .capacity)
        try container.encode(attendeeCount, forKey: .attendeeCount)
        try container.encode(talentIds, forKey: .talentIds)
        if !lookingForRoles.isEmpty {
            try container.encode(lookingForRoles, forKey: .lookingForRoles)
            try container.encode(lookingForRoles, forKey: .lookingForRolesSnake)
        }
        if let notes = lookingForNotes, !notes.isEmpty {
            try container.encode(notes, forKey: .lookingForNotes)
            try container.encode(notes, forKey: .lookingForNotesSnake)
        }
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(likes, forKey: .likes)
        try container.encode(isLiked, forKey: .isLiked)
        try container.encode(isSaved, forKey: .isSaved)
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encode(isRSVPed, forKey: .isRSVPed)
        try container.encodeIfPresent(qrCode, forKey: .qrCode)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(isPrivate, forKey: .isPrivateSnake)
        if let code = accessCode, !code.isEmpty {
            try container.encode(code, forKey: .accessCode)
            try container.encode(code, forKey: .accessCodeSnake)
        }
        
        // Write the looking-for field using multiple key shapes for compatibility
        if let lookingFor = lookingForSummary, !lookingFor.isEmpty {
            try container.encode(lookingFor, forKey: .lookingForTalentType)
            try container.encode(lookingFor, forKey: .lookingForTalentTypeSnake)
            try container.encode(lookingFor, forKey: .talentNeeded)
        }
    }
    
    // Combined, display-ready summary of the looking-for information
    var lookingForSummary: String? {
        Event.resolveLookingForSummary(roles: lookingForRoles, label: lookingForTalentType, notes: lookingForNotes)
    }
    
    private static func resolveLookingForSummary(roles: [String], label: String?, notes: String?) -> String? {
        let trimmedRoles = roles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var parts: [String] = []
        if !trimmedRoles.isEmpty {
            parts.append(trimmedRoles.joined(separator: ", "))
        } else if let label = label?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            parts.append(label)
        }
        
        if let notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            parts.append(notes)
        }
        
        let combined = parts.joined(separator: " — ")
        return combined.isEmpty ? nil : combined
    }
    
    // Generate unique QR code for event
    static func generateEventQRCode(eventId: String) -> String {
        // Create a unique QR code string for the event
        let qrData = "sioree:event:\(eventId):\(UUID().uuidString)"
        return qrData
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}

