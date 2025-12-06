//
//  AppModels.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI

// MARK: - UserRole
enum UserRole: String, CaseIterable, Identifiable {
    case host
    case partier
    case talent
    case brand
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .host: return "Host"
        case .partier: return "Partier"
        case .talent: return "Talent"
        case .brand: return "Brand"
        }
    }
    
    var iconName: String {
        switch self {
        case .host: return "house.fill"
        case .partier: return "person.2.fill"
        case .talent: return "music.note"
        case .brand: return "tag.fill"
        }
    }
}

// MARK: - Event
struct AppEvent: Identifiable {
    let id: String
    let hostId: String
    let title: String
    let hostName: String
    let date: Date
    let location: String
    let priceText: String
    let imageName: String
    let tags: [String]
    let isFeatured: Bool
    let images: [String]
    
    init(id: String = UUID().uuidString,
         hostId: String = "h1",
         title: String,
         hostName: String,
         date: Date,
         location: String,
         priceText: String,
         imageName: String = "party.popper.fill",
         tags: [String] = [],
         isFeatured: Bool = false,
         images: [String] = []) {
        self.id = id
        self.hostId = hostId
        self.title = title
        self.hostName = hostName
        self.date = date
        self.location = location
        self.priceText = priceText
        self.imageName = imageName
        self.tags = tags
        self.isFeatured = isFeatured
        self.images = images
    }
}

// MARK: - TalentListing
struct TalentListing: Identifiable {
    let id: String
    let name: String
    let roleText: String
    let rateText: String
    let location: String
    let rating: Double
    let imageName: String
    
    init(id: String = UUID().uuidString,
         name: String,
         roleText: String,
         rateText: String,
         location: String,
         rating: Double,
         imageName: String = "person.circle.fill") {
        self.id = id
        self.name = name
        self.roleText = roleText
        self.rateText = rateText
        self.location = location
        self.rating = rating
        self.imageName = imageName
    }
}

// MARK: - BrandCampaign
struct BrandCampaign: Identifiable {
    let id: String
    let brandName: String
    let headline: String
    let budgetText: String
    let goalText: String
    let statusText: String
    
    init(id: String = UUID().uuidString,
         brandName: String,
         headline: String,
         budgetText: String,
         goalText: String,
         statusText: String) {
        self.id = id
        self.brandName = brandName
        self.headline = headline
        self.budgetText = budgetText
        self.goalText = goalText
        self.statusText = statusText
    }
}

// MARK: - MockData
struct MockData {
    static let sampleEvents: [AppEvent] = [
        AppEvent(
            hostId: "h1",
            title: "Halloween Mansion Party",
            hostName: "LindaFlora",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            location: "Bel Air, CA",
            priceText: "$75",
            imageName: "party.popper.fill",
            tags: ["House Party", "Halloween", "Mansion"],
            isFeatured: true,
            images: ["Getty_515070156_EDITORIALONLY_LosAngeles_HollywoodBlvd_Web72DPI_0.jpg"]
        ),
        AppEvent(
            hostId: "h2",
            title: "Rooftop Sunset Sessions",
            hostName: "Skyline Events",
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            location: "Downtown LA",
            priceText: "$50",
            imageName: "sunset.fill",
            tags: ["Rooftop", "Sunset", "Electronic"],
            isFeatured: true,
            images: ["Lights_of_Rockefeller_Center_during_sunset.jpg"]
        ),
        AppEvent(
            hostId: "h3",
            title: "Underground Rave Warehouse",
            hostName: "Midnight Collective",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            location: "Arts District, LA",
            priceText: "$40",
            imageName: "music.note.list",
            tags: ["Rave", "Warehouse", "Techno"],
            isFeatured: false,
            images: ["iStock-528897870.jpg.webp"]
        ),
        AppEvent(
            hostId: "h4",
            title: "Corporate Holiday Mixer",
            hostName: "TechCorp Events",
            date: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            location: "Beverly Hills, CA",
            priceText: "Free",
            imageName: "briefcase.fill",
            tags: ["Corporate", "Networking", "Holiday"],
            isFeatured: false,
            images: ["images.jpeg"]
        ),
        AppEvent(
            hostId: "h5",
            title: "Beachside Bonfire",
            hostName: "Coastal Vibes",
            date: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            location: "Malibu, CA",
            priceText: "$30",
            imageName: "flame.fill",
            tags: ["Beach", "Bonfire", "Casual"],
            isFeatured: true,
            images: ["cruise-to-los-angeles-usa.webp"]
        ),
        AppEvent(
            hostId: "h6",
            title: "VIP Lounge Experience",
            hostName: "Elite Nights",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            location: "Hollywood, CA",
            priceText: "$150",
            imageName: "star.fill",
            tags: ["VIP", "Lounge", "Exclusive"],
            isFeatured: false,
            images: ["download (2).jpeg"]
        ),
        AppEvent(
            hostId: "h7",
            title: "Jazz Night at The Loft",
            hostName: "Smooth Sounds",
            date: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date(),
            location: "West Hollywood, CA",
            priceText: "$45",
            imageName: "music.mic",
            tags: ["Jazz", "Live Music", "Intimate"],
            isFeatured: false,
            images: ["download (3).jpeg"]
        ),
        AppEvent(
            hostId: "h8",
            title: "Day Party Poolside",
            hostName: "Sunshine Social",
            date: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
            location: "Venice Beach, CA",
            priceText: "$35",
            imageName: "sun.max.fill",
            tags: ["Day Party", "Pool", "Daytime"],
            isFeatured: true,
            images: ["cruise-to-los-angeles-usa.webp"]
        )
    ]
    
    static let sampleTalent: [TalentListing] = [
        TalentListing(
            name: "DJ Midnight",
            roleText: "DJ",
            rateText: "$500/night",
            location: "Los Angeles, CA",
            rating: 4.8,
            imageName: "music.note"
        ),
        TalentListing(
            name: "Sarah Mixwell",
            roleText: "DJ",
            rateText: "$750/night",
            location: "Beverly Hills, CA",
            rating: 4.9,
            imageName: "music.note.list"
        ),
        TalentListing(
            name: "Marcus BarTender",
            roleText: "Bartender",
            rateText: "$200/event",
            location: "Hollywood, CA",
            rating: 4.7,
            imageName: "wineglass.fill"
        ),
        TalentListing(
            name: "Elite Security Team",
            roleText: "Security",
            rateText: "$150/hour",
            location: "Los Angeles, CA",
            rating: 4.9,
            imageName: "shield.fill"
        ),
        TalentListing(
            name: "Capture Moments",
            roleText: "Photographer",
            rateText: "$400/event",
            location: "West Hollywood, CA",
            rating: 4.8,
            imageName: "camera.fill"
        ),
        TalentListing(
            name: "Video Vision",
            roleText: "Videographer",
            rateText: "$600/event",
            location: "Santa Monica, CA",
            rating: 4.7,
            imageName: "video.fill"
        ),
        TalentListing(
            name: "Mix Master Pro",
            roleText: "DJ",
            rateText: "$450/night",
            location: "Venice Beach, CA",
            rating: 4.6,
            imageName: "music.note"
        ),
        TalentListing(
            name: "Cocktail Crafters",
            roleText: "Bartender",
            rateText: "$250/event",
            location: "Malibu, CA",
            rating: 4.9,
            imageName: "wineglass.fill"
        )
    ]
    
    static let sampleCampaigns: [BrandCampaign] = [
        BrandCampaign(
            brandName: "Nightlife Energy",
            headline: "Summer Festival Activation",
            budgetText: "$25,000",
            goalText: "10,000 impressions",
            statusText: "Live"
        ),
        BrandCampaign(
            brandName: "Luxury Spirits Co",
            headline: "VIP Lounge Sponsorship",
            budgetText: "$50,000",
            goalText: "5,000 attendees",
            statusText: "Pending"
        ),
        BrandCampaign(
            brandName: "Fashion Forward",
            headline: "Rooftop Launch Event",
            budgetText: "$15,000",
            goalText: "3,000 reach",
            statusText: "Draft"
        ),
        BrandCampaign(
            brandName: "Tech Startup Hub",
            headline: "Corporate Networking Series",
            budgetText: "$30,000",
            goalText: "15,000 impressions",
            statusText: "Live"
        )
    ]
}

