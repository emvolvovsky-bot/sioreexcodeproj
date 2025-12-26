//
//  TicketsViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class TicketsViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var pastEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for RSVP notifications to refresh upcoming events
        NotificationCenter.default.publisher(for: NSNotification.Name("EventRSVPed"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Reload upcoming events to include the newly RSVPed event
                self?.loadUpcomingEvents()
            }
            .store(in: &cancellables)
        
        // Listen for event creation notifications (for hosts who create events)
        NotificationCenter.default.publisher(for: NSNotification.Name("EventCreated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Reload upcoming events to include newly created event
                self?.loadUpcomingEvents()
            }
            .store(in: &cancellables)
    }
    
    private func loadUpcomingEvents() {
        guard let userId = StorageService.shared.getUserId() else { return }
        
        networkService.fetchUpcomingAttendingEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to reload upcoming events: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] events in
                    self?.upcomingEvents = events
                    print("✅ Reloaded \(events.count) upcoming events")
                }
            )
            .store(in: &cancellables)
    }
    
    func loadTickets() {
        guard let userId = StorageService.shared.getUserId() else {
            // Add placeholder data if no user
            addPlaceholderData()
            return
        }
        
        isLoading = true
        
        // Fetch attended events (past events)
        networkService.fetchAttendedEvents(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load attended events: \(error.localizedDescription)")
                        // Add placeholder if fetch fails
                        self?.addPlaceholderData()
                    }
                },
                receiveValue: { [weak self] events in
                    self?.pastEvents = events
                    // Add placeholder if no events
                    if events.isEmpty {
                        self?.addPlaceholderData()
                    }
                }
            )
            .store(in: &cancellables)
        
        // Fetch upcoming events (events user RSVPed to that are in the future)
        loadUpcomingEvents()
    }
    
    private func addPlaceholderData() {
        // Add a placeholder past event for demonstration
        let eventDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let placeholderEvent = Event(
            id: "placeholder-past-1",
            title: "Summer Music Festival",
            description: "An amazing music festival with great vibes and amazing performances",
            hostId: "host-placeholder-1",
            hostName: "DJ Mike",
            hostAvatar: nil,
            date: eventDate,
            time: eventDate,
            location: "Central Park, New York, NY",
            images: [],
            ticketPrice: 50.0,
            capacity: 500,
            attendeeCount: 350,
            talentIds: ["talent-placeholder-1", "talent-placeholder-2"], // Add placeholder talent IDs
            status: .completed,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            likes: 120,
            isLiked: false,
            isSaved: false,
            isFeatured: false
        )
        
        if pastEvents.isEmpty {
            pastEvents = [placeholderEvent]
        }
    }
}

