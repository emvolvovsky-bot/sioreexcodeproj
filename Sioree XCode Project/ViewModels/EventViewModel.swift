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
        guard let event = event else { return }
        isRSVPed = true
        event?.isRSVPed = true
        
        networkService.rsvpToEvent(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.isRSVPed = false
                        self?.event?.isRSVPed = false
                    }
                },
                receiveValue: { [weak self] _ in
                    // RSVP saved successfully - event will be removed from "Near Me" and appear in "Upcoming"
                    self?.event?.attendeeCount += 1
                    // Reload event to get updated status
                    self?.loadEvent()
                }
            )
            .store(in: &cancellables)
    }
    
    func cancelRSVP() {
        guard let event = event else { return }
        isRSVPed = false
        event?.isRSVPed = false
        
        networkService.cancelRSVP(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.isRSVPed = true
                        self?.event?.isRSVPed = true
                    }
                },
                receiveValue: { [weak self] _ in
                    // RSVP cancelled successfully - event will be removed from "Upcoming" and appear in "Near Me" again
                    if let count = self?.event?.attendeeCount, count > 0 {
                        self?.event?.attendeeCount -= 1
                    }
                    // Reload event to get updated status
                    self?.loadEvent()
                }
            )
            .store(in: &cancellables)
    }
}

