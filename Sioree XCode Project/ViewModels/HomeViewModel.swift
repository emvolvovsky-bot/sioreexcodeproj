//
//  HomeViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var featuredEvents: [Event] = []
    @Published var nearbyEvents: [Event] = []
    @Published var events: [Event] = [] // All events (for MyEventsView)
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadEvents() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        // Load featured events (promoted by brands)
        networkService.fetchFeaturedEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load featured events: \(error)")
                        // Use placeholder featured events if API fails
                        self?.featuredEvents = self?.generatePlaceholderFeaturedEvents() ?? []
                    }
                },
                receiveValue: { [weak self] events in
                    // Always show placeholders for preview (can be removed later)
                    // Use real data if available, otherwise use placeholders
                    if events.isEmpty {
                        self?.featuredEvents = self?.generatePlaceholderFeaturedEvents() ?? []
                        print("📋 Using \(self?.featuredEvents.count ?? 0) placeholder featured events")
                    } else {
                        self?.featuredEvents = events
                        print("✅ Loaded \(events.count) featured events")
                    }
                    // Ensure nearby events also get placeholders if empty
                    if self?.nearbyEvents.isEmpty == true && self?.hasLoaded == false {
                        self?.nearbyEvents = self?.generatePlaceholderNearbyEvents() ?? []
                    }
                    // Update all events list
                    self?.updateAllEvents()
                }
            )
            .store(in: &cancellables)
        
        // Load nearby events
        networkService.fetchNearbyEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        // Use placeholder nearby events if API fails
                        self?.nearbyEvents = self?.generatePlaceholderNearbyEvents() ?? []
                        self?.hasLoaded = true
                    } else {
                        self?.hasLoaded = true
                    }
                },
                receiveValue: { [weak self] events in
                    // Always show placeholders for preview (can be removed later)
                    // Use real data if available, otherwise use placeholders
                    if events.isEmpty {
                        self?.nearbyEvents = self?.generatePlaceholderNearbyEvents() ?? []
                        print("📋 Using \(self?.nearbyEvents.count ?? 0) placeholder nearby events")
                    } else {
                        self?.nearbyEvents = events
                        print("✅ Loaded \(events.count) nearby events")
                    }
                    self?.isLoading = false
                    self?.hasLoaded = true
                }
            )
            .store(in: &cancellables)
    }
    
    // Generate realistic placeholder featured events (promoted by brands)
    func generatePlaceholderFeaturedEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        let featuredTitles = [
            "Summer Music Festival NYC",
            "Rooftop Party at The Highline",
            "Electronic Dance Night",
            "Jazz & Wine Tasting Experience",
            "Underground Rave Brooklyn"
        ]
        
        let featuredHosts = [
            "Red Bull Events",
            "Spotify Live",
            "Coachella Presents",
            "Live Nation",
            "AEG Presents"
        ]
        
        let featuredLocations = [
            "Brooklyn, NY",
            "Manhattan, NY",
            "Queens, NY",
            "Manhattan, NY",
            "Brooklyn, NY"
        ]
        
        let featuredDescriptions = [
            "Join us for an unforgettable night of music and dancing under the stars.",
            "Experience the best rooftop party in NYC with stunning city views.",
            "Electronic music meets underground culture in this exclusive event.",
            "Sip fine wines while enjoying live jazz performances.",
            "The most talked-about underground event in Brooklyn."
        ]
        
        return (0..<5).map { index in
            let daysFromNow = index + 1
            let eventDate = calendar.date(byAdding: .day, value: daysFromNow, to: now) ?? now
            let hour = 19 + (index % 4) // 7 PM to 10 PM
            let eventDateTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: eventDate) ?? eventDate
            
            return Event(
                id: "featured-\(index)",
                title: featuredTitles[index],
                description: featuredDescriptions[index],
                hostId: "brand-\(index)",
                hostName: featuredHosts[index],
                hostAvatar: nil,
                date: eventDateTime,
                time: eventDateTime,
                location: featuredLocations[index],
                locationDetails: nil,
                images: [],
                ticketPrice: Double.random(in: 25...150),
                capacity: Int.random(in: 100...500),
                attendeeCount: Int.random(in: 50...300),
                talentIds: [],
                status: .published,
                createdAt: now,
                likes: Int.random(in: 100...1000),
                isLiked: false,
                isSaved: false,
                isFeatured: true
            )
        }
    }
    
    // Generate realistic placeholder nearby events
    func generatePlaceholderNearbyEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        let nearbyTitles = [
            "Friday Night House Party",
            "Weekend Brunch & Beats",
            "Late Night DJ Set",
            "Sunday Funday",
            "Midweek Mixer",
            "Thursday Throwdown",
            "Saturday Night Live",
            "Weekend Warriors"
        ]
        
        let nearbyHosts = [
            "DJ MixMaster",
            "Party Central NYC",
            "Nightlife Collective",
            "Event Pro",
            "Music Collective",
            "Underground Sounds",
            "City Vibes",
            "Local Legends"
        ]
        
        let nearbyLocations = [
            "Lower East Side, NY",
            "Williamsburg, NY",
            "East Village, NY",
            "SoHo, NY",
            "Greenpoint, NY",
            "Chelsea, NY",
            "Astoria, NY",
            "Harlem, NY"
        ]
        
        let nearbyDescriptions = [
            "Come dance the night away at our weekly house party.",
            "Start your weekend right with brunch and beats.",
            "Late night vibes with top local DJs.",
            "Sunday fun day with friends and music.",
            "Midweek escape from the daily grind.",
            "Thursday night party to kick off the weekend.",
            "Saturday night special with live performances.",
            "Weekend warriors unite for an epic night."
        ]
        
        return (0..<8).map { index in
            let daysFromNow = index + 1
            let eventDate = calendar.date(byAdding: .day, value: daysFromNow, to: now) ?? now
            let hour = 18 + (index % 6) // 6 PM to 11 PM
            let eventDateTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: eventDate) ?? eventDate
            
            // Mix of free and paid events
            let isFree = index % 3 == 0
            let ticketPrice: Double? = isFree ? nil : Double.random(in: 15...75)
            
            return Event(
                id: "nearby-\(index)",
                title: nearbyTitles[index],
                description: nearbyDescriptions[index],
                hostId: "host-\(index)",
                hostName: nearbyHosts[index],
                hostAvatar: nil,
                date: eventDateTime,
                time: eventDateTime,
                location: nearbyLocations[index],
                locationDetails: nil,
                images: [],
                ticketPrice: ticketPrice,
                capacity: Int.random(in: 50...200),
                attendeeCount: Int.random(in: 20...150),
                talentIds: [],
                status: .published,
                createdAt: now,
                likes: Int.random(in: 10...500),
                isLiked: false,
                isSaved: false,
                isFeatured: false
            )
        }
    }
    
    // Legacy method for backward compatibility
    func loadNearbyEvents() {
        loadEvents()
    }
    
    // Computed property for backward compatibility
    var events: [Event] {
        nearbyEvents
    }
}


