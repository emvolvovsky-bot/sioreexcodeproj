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
    @Published var event: Event? {
        didSet {
            // Update local RSVP status when event changes
            if let event = event {
                isRSVPed = event.isRSVPed
            }
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRSVPed = false
    @Published var eventBookings: [Booking] = []
    @Published var isLoadingBookings = false

    // Remove unused published properties that were causing unnecessary re-renders
    var showPaymentCheckout = false
    var showRSVPSheet = false
    var rsvpQRCode: String?
    private var hasLoadedBookings = false
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    private let eventId: String
    private var hasLoadedEvent = false
    private let storageService = StorageService.shared
    
    init(eventId: String) {
        self.eventId = eventId
        // Avoid loading when creating a new event (empty id)
        if !eventId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loadEvent()
        }
    }
    
    func loadEvent() {
        guard !eventId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !hasLoadedEvent || event == nil else {
            return
        }
        isLoading = true
        errorMessage = nil

        // First attempt to load a locally cached copy to avoid network calls
        if let cached = storageService.getLocalEvent(eventId: eventId) {
            print("📦 Loaded cached event for id \(eventId): \(cached.title)")
            self.event = cached
            self.isRSVPed = cached.isRSVPed
            isLoading = false
            // Do not mark hasLoadedEvent so that callers can still request a fresh load if needed.
            return
        }

        hasLoadedEvent = true
        print("🔍 Loading event with ID: \(eventId) from network")

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
                    // Cache the fetched event locally so subsequent loads are fast
                    StorageService.shared.saveLocalEvent(event)
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
    
    func createEvent(title: String,
                    description: String,
                    date: Date,
                    time: Date,
                    location: String,
                    images: [String],
                    ticketPrice: Double?,
                    capacity: Int? = nil,
                    talentIds: [String] = [],
                    lookingForRoles: [String] = [],
                    lookingForNotes: String? = nil,
                    lookingForTalentType: String? = nil,
                    completion: ((Result<Event, Error>) -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        networkService.createEvent(
            title: title,
            description: description,
            date: date,
            time: time,
            location: location,
            images: images,
            ticketPrice: ticketPrice,
        capacity: capacity,
            talentIds: talentIds,
            lookingForRoles: lookingForRoles,
            lookingForNotes: lookingForNotes,
            lookingForTalentType: lookingForTalentType
        )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = error.localizedDescription
                        completion?(.failure(error))
                    }
                },
                receiveValue: { [weak self] event in
                    self?.event = event
                    // Always post notification when event is created so it appears on home screen
                    NotificationCenter.default.post(
                        name: NSNotification.Name("EventCreated"),
                        object: nil,
                        userInfo: ["event": event]
                    )
                    // Persist created event locally so it shows up instantly without reloading from server
                    StorageService.shared.saveLocalEvent(event)
                    // If event is in the future and has a QR code, it will also appear in tickets
                    completion?(.success(event))
                }
            )
            .store(in: &cancellables)
    }
    
    func trackImpression() {
        networkService.trackEventImpression(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to track impression: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    print("✅ Impression tracked")
                }
            )
            .store(in: &cancellables)
    }
    
    func rsvpToEvent(completion: ((String?) -> Void)? = nil) {
        guard var event = event else { return }
        // Optimistically update UI
        isRSVPed = true
        event.isRSVPed = true
        event.attendeeCount += 1
        self.event = event
        // Update cached copy immediately
        StorageService.shared.saveLocalEvent(event)
        
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
                receiveValue: { [weak self] response in
                    // RSVP saved successfully - keep the optimistic update
                    // Don't reload immediately to avoid flickering
                    print("✅ RSVP saved successfully")
                    
                    // Capture QR code from backend if provided
                    if var event = self?.event {
                        if let qr = response.qrCode {
                            event.qrCode = qr
                            self?.rsvpQRCode = qr
                        }
                        self?.event = event
                    }
                    
                    // Call completion with QR code
                    completion?(response.qrCode)

                    // Update event with QR code if provided
                    if let qrCode = response.qrCode, var event = self?.event {
                        event.qrCode = qrCode
                        self?.event = event
                    }
                    
                    // Notify that event was RSVPed - remove from nearby/featured and add to upcoming
                    if let event = self?.event {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("EventRSVPed"),
                            object: nil,
                            userInfo: ["eventId": event.id, "event": event, "qrCode": response.qrCode ?? ""]
                        )
                        
                        // Post a notification to dismiss the detail view (optional, can be handled by the view)
                        NotificationCenter.default.post(
                            name: NSNotification.Name("EventRSVPSuccess"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                    }
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

    func fetchEventBookings() {
        guard let event = event, !hasLoadedBookings else { return }

        isLoadingBookings = true
        hasLoadedBookings = true

        networkService.fetchEventBookings(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingBookings = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load event bookings: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] bookings in
                    self?.eventBookings = bookings
                    print("✅ Loaded \(bookings.count) bookings for event")
                }
            )
            .store(in: &cancellables)
    }
}

