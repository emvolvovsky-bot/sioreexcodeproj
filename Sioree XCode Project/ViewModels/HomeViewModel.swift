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
    @Published var nearbyEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    @Published var selectedDate: Date? = nil
    @Published var lastKnownCoordinate: CLLocationCoordinate2D?
    @Published var lastRadiusMiles: Int = 30
    // Cached IDs for events the current user is attending (to keep them out of the home feed)
    private var attendingIds: Set<String> = []
    
    // Store all loaded events before filtering
    private var allNearbyEvents: [Event] = []
    
    let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for RSVP notifications to remove events from lists
        NotificationCenter.default.publisher(for: NSNotification.Name("EventRSVPed"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let eventId = notification.userInfo?["eventId"] as? String {
                    self?.removeEventFromLists(eventId: eventId)
                    // Track as attending so future server loads filter it out
                    self?.attendingIds.insert(eventId)
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

        // Load current user's attending IDs so we can filter home feed immediately
        loadAttendingIds()
    }

    private func loadAttendingIds() {
        guard StorageService.shared.getUserId() != nil else { return }
        networkService.fetchUpcomingAttendingEvents()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to load attending IDs: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] events in
                guard let self = self else { return }
                let ids = Set(events.map { $0.id })
                self.attendingIds = ids
                // Immediately remove any attending events from the displayed lists
                if !ids.isEmpty {
                    self.allNearbyEvents.removeAll { ids.contains($0.id) }
                    self.applyDateFilter()
                }
            })
            .store(in: &cancellables)
    }
    
    private func removeEventFromLists(eventId: String) {
        // Remove from displayed nearby events
        nearbyEvents.removeAll { $0.id == eventId }
        // Remove from stored nearby events
        allNearbyEvents.removeAll { $0.id == eventId }

        print("✅ Removed event \(eventId) from nearby events list")
    }

    private func addNewEventToLists(event: Event) {
        // Check if event already exists to avoid duplicates
        let eventExists = allNearbyEvents.contains { $0.id == event.id }
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

        // Add to nearby events
        // If the current user is attending/RSVPed for this event, don't add it to the public home feed.
        if StorageService.shared.getUserId() != nil && completeEvent.isRSVPed {
            print("ℹ️ Skipping adding event \(completeEvent.id) to home feed because user has a ticket/RSVP")
            return
        }

        allNearbyEvents.insert(completeEvent, at: 0) // Add to beginning
        print("✅ Added new event: \(completeEvent.title)")

        // Only apply date filter if we have loaded events before
        // This prevents filtering out the new event before the user sees it
        if hasLoaded {
            applyDateFilter()
        } else {
            // If not loaded yet, just update the display array
            nearbyEvents = allNearbyEvents
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

        // Load nearby events
        if skipNearby {
            // No location available; clear nearby events
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
                    self?.allNearbyEvents = []
                    self?.applyDateFilter()
                    self?.hasLoaded = true
                } else {
                    self?.hasLoaded = true
                }
            },
            receiveValue: { [weak self] events in
                guard let self = self else { return }

                // Filter out events the user is attending (use cached attendingIds)
                let filteredByAttendance: [Event]
                if !self.attendingIds.isEmpty {
                    filteredByAttendance = events.filter { !self.attendingIds.contains($0.id) }
                } else {
                    // No cached attending ids yet - optimistic include all and rely on loadAttendingIds to update soon
                    filteredByAttendance = events
                }

                // Merge server events with locally created events that might not be in server response yet
                if filteredByAttendance.isEmpty {
                    self.allNearbyEvents = []
                } else {
                    let serverEventIds = Set(filteredByAttendance.map { $0.id })
                    let existingLocalEvents = self.allNearbyEvents.filter { !serverEventIds.contains($0.id) }
                    self.allNearbyEvents = filteredByAttendance + existingLocalEvents
                    print("✅ Loaded \(filteredByAttendance.count) events from server, kept \(existingLocalEvents.count) local events")
                }

                // Apply date filter if one is selected
                self.applyDateFilter()
                self.isLoading = false
                self.hasLoaded = true
            }
        )
        .store(in: &cancellables)
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
                isSaved: false
            )
        }
    }
    
    // Legacy method for backward compatibility
    func loadNearbyEvents() {
        loadEvents()
    }

    // Deterministic coordinate generator used when events don't include lat/lng.
    // Mirrors the fallback logic used in EventsMapView so map pins and distance filtering align.
    static func coordinateForEvent(_ event: Event) -> CLLocationCoordinate2D {
        let hash = abs(event.location.hashValue)
        let lat = 34.0522 + Double(hash % 100) / 1000.0 - 0.05
        let lon = -118.2437 + Double((hash / 100) % 100) / 1000.0 - 0.05
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // Computed property for backward compatibility
    var events: [Event] {
        nearbyEvents
    }

    // Expose total loaded events count (before client-side filtering) for UI decisions
    var totalLoadedEventsCount: Int {
        allNearbyEvents.count
    }
    
    // Filter events by selected date - ONLY show events for that specific day
    func applyDateFilter() {
        // Apply both date and radius filters together so the user sees only events that match both constraints.
        let calendar = Calendar.current

        // Date filtering (if selectedDate is set)
        var results = allNearbyEvents
        if let selectedDate = selectedDate {
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            results = results.filter { event in
                let eventDate = calendar.startOfDay(for: event.date)
                return eventDate >= startOfDay && eventDate < endOfDay
            }
            print("📅 Filtered events for date: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
        } else {
            print("📅 No date filter applied")
        }

        // Radius filtering (if lastRadiusMiles > 0 and we have a known coordinate)
        if lastRadiusMiles > 0, let center = lastKnownCoordinate {
            results = results.filter { event in
                // Compute coordinates using the same deterministic hash fallback used by map view
                let coord = Self.coordinateForEvent(event)
                let eventLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
                let distanceMeters = eventLocation.distance(from: centerLocation)
                let distanceMiles = distanceMeters / 1609.34
                return distanceMiles <= Double(lastRadiusMiles)
            }
            print("📍 Applied radius filter: \(lastRadiusMiles) mi from \(String(describing: lastKnownCoordinate))")
        } else {
            print("📍 No radius filter applied (showing all distances)")
        }

        nearbyEvents = results
        print("   Events after filters: \(nearbyEvents.count) / \(allNearbyEvents.count)")
    }
    
    // Clear date filter
    func clearDateFilter() {
        selectedDate = nil
        applyDateFilter()
    }
    
    // Toggle save event
    func toggleSaveEvent(_ event: Event) {
        // Optimistic update
        if let index = nearbyEvents.firstIndex(where: { $0.id == event.id }) {
            nearbyEvents[index].isSaved.toggle()
        }

        // Also update in all events array
        if let index = allNearbyEvents.firstIndex(where: { $0.id == event.id }) {
            allNearbyEvents[index].isSaved.toggle()
        }

        // favorite change notification removed

        networkService.toggleEventSave(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert optimistic update
                        if let index = self?.nearbyEvents.firstIndex(where: { $0.id == event.id }) {
                            self?.nearbyEvents[index].isSaved.toggle()
                        }
                        if let index = self?.allNearbyEvents.firstIndex(where: { $0.id == event.id }) {
                            self?.allNearbyEvents[index].isSaved.toggle()
                        }
                        // favorite change notification removed
                    }
                },
                receiveValue: { [weak self] _ in
                    // Persist change to local saved-events cache so it survives app restarts
                    guard let self = self, let currentUserId = StorageService.shared.getUserId() else { return }
                    var cached = StorageService.shared.getSavedEvents(forUserId: currentUserId)
                    // Determine updated event from local arrays
                    if let updated = self.nearbyEvents.first(where: { $0.id == event.id }) ?? self.allNearbyEvents.first(where: { $0.id == event.id }) {
                        if updated.isSaved {
                            // Add if missing
                            if !cached.contains(where: { $0.id == updated.id }) {
                                cached.insert(updated, at: 0)
                            } else {
                                // update existing entry
                                if let idx = cached.firstIndex(where: { $0.id == updated.id }) {
                                    cached[idx] = updated
                                }
                            }
                        } else {
                            // Remove if present
                            cached.removeAll(where: { $0.id == updated.id })
                        }
                        StorageService.shared.saveSavedEvents(cached, forUserId: currentUserId)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // favorite notification helper removed
    
}


