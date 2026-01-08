//
//  HomeViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class HomeViewModel: ObservableObject {
    @Published var featuredEvents: [Event] = []
    @Published var nearbyEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    @Published var selectedDate: Date? = nil
    @Published var lastKnownCoordinate: CLLocationCoordinate2D?
    @Published var lastRadiusMiles: Int = 30
    
    // Store all loaded events before filtering
    private var allFeaturedEvents: [Event] = []
    private var allNearbyEvents: [Event] = []
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for RSVP notifications to remove events from lists
        NotificationCenter.default.publisher(for: NSNotification.Name("EventRSVPed"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let eventId = notification.userInfo?["eventId"] as? String {
                    self?.removeEventFromLists(eventId: eventId)
                }
            }
            .store(in: &cancellables)
        
        // Listen for delete notifications to remove events from lists
        NotificationCenter.default.publisher(for: NSNotification.Name("EventDeleted"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let eventId = notification.userInfo?["eventId"] as? String {
                    self?.removeEventFromLists(eventId: eventId)
                }
            }
            .store(in: &cancellables)

        // Listen for new event creation to add event immediately
        NotificationCenter.default.publisher(for: NSNotification.Name("EventCreated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let event = notification.userInfo?["event"] as? Event {
                    print("📡 Received EventCreated notification, adding event: \(event.title)")
                    self?.addNewEventToLists(event: event)
                }
                // Don't do fallback refresh - let the event persist locally
            }
            .store(in: &cancellables)
    }
    
    private func removeEventFromLists(eventId: String) {
        // Remove from featured events
        featuredEvents.removeAll { $0.id == eventId }

        // Remove from nearby events
        nearbyEvents.removeAll { $0.id == eventId }

        print("✅ Removed event \(eventId) from nearby/featured lists")
    }

    private func addNewEventToLists(event: Event) {
        // Check if event already exists to avoid duplicates
        let eventExists = allFeaturedEvents.contains { $0.id == event.id } || allNearbyEvents.contains { $0.id == event.id }
        if eventExists {
            print("⚠️ Event \(event.id) already exists, skipping duplicate add")
            return
        }

        // Ensure event has required fields with proper defaults
        var completeEvent = event

        // Set default values for missing fields that might cause display issues
        if completeEvent.status == .draft {
            completeEvent.status = .published
        }
        if completeEvent.attendeeCount < 0 { // Allow 0 but not negative
            completeEvent.attendeeCount = 0
        }
        if completeEvent.likes < 0 {
            completeEvent.likes = 0
        }

        // Add to the appropriate list based on event properties
        if completeEvent.isFeatured {
            // Add to featured events
            allFeaturedEvents.insert(completeEvent, at: 0) // Add to beginning
            print("✅ Added new featured event: \(completeEvent.title)")
        } else {
            // Add to nearby events (default for new events)
            allNearbyEvents.insert(completeEvent, at: 0) // Add to beginning
            print("✅ Added new nearby event: \(completeEvent.title)")
        }

        // Only apply date filter if we have loaded events before
        // This prevents filtering out the new event before the user sees it
        if hasLoaded {
            applyDateFilter()
        } else {
            // If not loaded yet, just update the display arrays
            if completeEvent.isFeatured {
                featuredEvents = allFeaturedEvents
            } else {
                nearbyEvents = allNearbyEvents
            }
        }
    }
    
    func loadEvents(userLocation: CLLocationCoordinate2D? = nil, radiusMiles: Int = 30) {
        guard !isLoading || userLocation != nil else { return }
        isLoading = true
        errorMessage = nil
        if let userLocation {
            lastKnownCoordinate = userLocation
        }
        lastRadiusMiles = radiusMiles
        
        let skipNearby = lastKnownCoordinate == nil && userLocation == nil
        
        // Load featured events (promoted by brands)
        networkService.fetchFeaturedEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load featured events: \(error)")
                        // Use placeholder featured events if API fails
                        self?.allFeaturedEvents = self?.generatePlaceholderFeaturedEvents() ?? []
                        self?.applyDateFilter()
                    }
                },
                receiveValue: { [weak self] events in
                    // Always show placeholders for preview (can be removed later)
                    // Use real data if available, otherwise use placeholders
                    if events.isEmpty {
                        self?.allFeaturedEvents = self?.generatePlaceholderFeaturedEvents() ?? []
                        print("📋 Using \(self?.allFeaturedEvents.count ?? 0) placeholder featured events")
                    } else {
                        // Merge server events with locally created events that might not be in server response yet
                        let serverEventIds = Set(events.map { $0.id })
                        let existingLocalEvents = self?.allFeaturedEvents.filter { !serverEventIds.contains($0.id) } ?? []
                        self?.allFeaturedEvents = events + existingLocalEvents
                        print("✅ Loaded \(events.count) featured events from server, kept \(existingLocalEvents.count) local events")
                    }
                    // Apply date filter if one is selected
                    self?.applyDateFilter()
                    // Ensure nearby events also get placeholders if empty
                    if self?.nearbyEvents.isEmpty == true && self?.hasLoaded == false {
                        self?.allNearbyEvents = self?.generatePlaceholderNearbyEvents() ?? []
                        self?.applyDateFilter()
                    }
                }
            )
            .store(in: &cancellables)
        
        // Load nearby events
        if skipNearby {
            // No location available; clear nearby and finish loading featured only.
            allNearbyEvents = []
            nearbyEvents = []
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.hasLoaded = true
            }
            return
        }
        
        networkService.fetchNearbyEvents(
            latitude: lastKnownCoordinate?.latitude,
            longitude: lastKnownCoordinate?.longitude,
            radiusMiles: radiusMiles
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    // Use placeholder nearby events if API fails
                    self?.allNearbyEvents = self?.generatePlaceholderNearbyEvents() ?? []
                    self?.applyDateFilter()
                    self?.hasLoaded = true
                } else {
                    self?.hasLoaded = true
                }
            },
            receiveValue: { [weak self] events in
                // Always show placeholders for preview (can be removed later)
                // Use real data if available, otherwise use placeholders
                if events.isEmpty {
                    self?.allNearbyEvents = self?.generatePlaceholderNearbyEvents() ?? []
                    print("📋 Using \(self?.allNearbyEvents.count ?? 0) placeholder nearby events")
                } else {
                    // Merge server events with locally created events that might not be in server response yet
                    let serverEventIds = Set(events.map { $0.id })
                    let existingLocalEvents = self?.allNearbyEvents.filter { !serverEventIds.contains($0.id) } ?? []
                    self?.allNearbyEvents = events + existingLocalEvents
                    print("✅ Loaded \(events.count) nearby events from server, kept \(existingLocalEvents.count) local events")
                }
                // Apply date filter if one is selected
                self?.applyDateFilter()
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
        
        let featuredImages = ["party1", "party2", "party3", "party4", "party5"]
        
        return (0..<5).map { index in
            let daysFromNow = index + 1
            let eventDate = calendar.date(byAdding: .day, value: daysFromNow, to: now) ?? now
            let hour = 19 + (index % 4) // 7 PM to 10 PM
            let eventDateTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: eventDate) ?? eventDate
            
            // Make the first event (Summer Music Festival) private with access code
            let isPrivate = index == 0
            let accessCode = isPrivate ? "MUSIC2024" : nil
            
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
                images: [featuredImages[index % featuredImages.count]],
                ticketPrice: Double.random(in: 25...150),
                capacity: Int.random(in: 100...500),
                attendeeCount: Int.random(in: 50...300),
                talentIds: [],
                status: .published,
                createdAt: now,
                likes: Int.random(in: 100...1000),
                isLiked: false,
                isSaved: false,
                isFeatured: true,
                isPrivate: isPrivate,
                accessCode: accessCode
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
        
        let nearbyImages = ["party1", "party2", "party3", "party4", "party5"]
        
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
                images: [nearbyImages[index % nearbyImages.count]],
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
    
    // Filter events by selected date
    func applyDateFilter() {
        guard let selectedDate = selectedDate else {
            // No filter - show all events
            featuredEvents = allFeaturedEvents
            nearbyEvents = allNearbyEvents
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        // Filter featured events
        featuredEvents = allFeaturedEvents.filter { event in
            let eventDate = calendar.startOfDay(for: event.date)
            return eventDate >= startOfDay && eventDate < endOfDay
        }
        
        // Filter nearby events
        nearbyEvents = allNearbyEvents.filter { event in
            let eventDate = calendar.startOfDay(for: event.date)
            return eventDate >= startOfDay && eventDate < endOfDay
        }
        
        print("📅 Filtered events for date: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
        print("   Featured: \(featuredEvents.count) / \(allFeaturedEvents.count)")
        print("   Nearby: \(nearbyEvents.count) / \(allNearbyEvents.count)")
    }
    
    // Clear date filter
    func clearDateFilter() {
        selectedDate = nil
        applyDateFilter()
    }
    
}


