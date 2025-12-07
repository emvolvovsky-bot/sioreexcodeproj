//
//  EventViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class EventViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRSVPed = false
    @Published var showPaymentCheckout = false
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    private let eventId: String
    
    init(eventId: String) {
        self.eventId = eventId
        loadEvent()
    }
    
    func loadEvent() {
        isLoading = true
        errorMessage = nil
        print("🔍 Loading event with ID: \(eventId)")
        
        networkService.fetchEvent(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load event: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    } else {
                        print("✅ Event loaded successfully")
                    }
                },
                receiveValue: { [weak self] event in
                    print("✅ Received event: \(event.title)")
                    self?.event = event
                    // RSVP status is now included in the event response from backend
                    self?.isRSVPed = event.isRSVPed
                }
            )
            .store(in: &cancellables)
    }
    
    private func checkRSVPStatus() {
        // RSVP status is now included in the event response from backend
        // The backend checks if the user is in event_attendees table
        if let event = event {
            // Check if event has isRSVPed property (if backend returns it)
            // For now, we'll rely on the backend response
            // The backend should include isRSVPed in the event object
        }
    }
    
    func createEvent(title: String, description: String, date: Date, time: Date, location: String, images: [String], ticketPrice: Double?, talentIds: [String] = [], lookingForTalentType: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        networkService.createEvent(title: title, description: description, date: date, time: time, location: location, images: images, ticketPrice: ticketPrice, talentIds: talentIds, lookingForTalentType: lookingForTalentType)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] event in
                    self?.event = event
                }
            )
            .store(in: &cancellables)
    }
    
    func rsvpToEvent() {
        guard var event = event else { return }
        // Optimistically update UI
        isRSVPed = true
        event.isRSVPed = true
        event.attendeeCount += 1
        self.event = event
        
        networkService.rsvpToEvent(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert on failure
                        self?.isRSVPed = false
                        if var event = self?.event {
                            event.isRSVPed = false
                            if event.attendeeCount > 0 {
                                event.attendeeCount -= 1
                            }
                            self?.event = event
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    // RSVP saved successfully - keep the optimistic update
                    // Don't reload immediately to avoid flickering
                    print("✅ RSVP saved successfully")
                }
            )
            .store(in: &cancellables)
    }
    
    func cancelRSVP() {
        guard var event = event else { return }
        // Optimistically update UI
        isRSVPed = false
        event.isRSVPed = false
        if event.attendeeCount > 0 {
            event.attendeeCount -= 1
        }
        self.event = event
        
        networkService.cancelRSVP(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert on failure
                        self?.isRSVPed = true
                        if var event = self?.event {
                            event.isRSVPed = true
                            event.attendeeCount += 1
                            self?.event = event
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    // RSVP cancelled successfully - keep the optimistic update
                    // Don't reload immediately to avoid flickering
                    print("✅ RSVP cancelled successfully")
                }
            )
            .store(in: &cancellables)
    }
}

