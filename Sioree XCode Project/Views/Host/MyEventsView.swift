//
//  MyEventsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MyEventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showNewEvent = false
    @State private var showQRScanner = false
    @State private var selectedEventId: String?
    @State private var eventToDelete: String?
    @State private var showDeleteConfirmation = false
    
    @State private var localEvents: [Event] = []
    
    private var events: [Event] {
        // Use local events if available, otherwise filter from homeViewModel
        if !localEvents.isEmpty {
            return localEvents
        }
        // Combine nearby and featured events, then filter by host
        let nearby = homeViewModel.nearbyEvents
        let featured = homeViewModel.featuredEvents
        let allEvents = nearby + featured
        let currentUserId = authViewModel.currentUser?.id
        return allEvents.filter { event in
            event.hostId == currentUserId
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.m) {
                        if homeViewModel.isLoading && !homeViewModel.hasLoaded {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xxl)
                        } else if events.isEmpty && homeViewModel.hasLoaded {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 64))
                                    .foregroundColor(Color.sioreeLightGrey)
                                Text("No events yet")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                Text("Create your first event to get started")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.xxl)
                        } else {
                            ForEach(events) { event in
                            VStack(spacing: Theme.Spacing.s) {
                                HostEventCard(
                                    event: event,
                                    status: eventStatusString(for: event),
                                    onTap: {
                                        // Navigate to event detail
                                    }
                                )
                                
                                HStack(spacing: Theme.Spacing.m) {
                                    // Delete Event Button (only for host's own events)
                                    Button(action: {
                                        eventToDelete = event.id
                                        showDeleteConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete Event")
                                                .font(.sioreeBody)
                                        }
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                    }
                                    
                                    // Scan Tickets Button (only for upcoming events)
                                    if event.date > Date() {
                                        Button(action: {
                                            selectedEventId = event.id
                                            showQRScanner = true
                                        }) {
                                            HStack {
                                                Image(systemName: "qrcode.viewfinder")
                                                Text("Scan Tickets")
                                                    .font(.sioreeBody)
                                            }
                                            .foregroundColor(.sioreeWhite)
                                            .frame(maxWidth: .infinity)
                                            .padding(Theme.Spacing.m)
                                            .background(Color.sioreeIcyBlue)
                                            .cornerRadius(Theme.CornerRadius.medium)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.s)
                    .padding(.bottom, Theme.Spacing.m)
                }
                .onAppear {
                    if !homeViewModel.hasLoaded {
                        homeViewModel.loadNearbyEvents()
                    }
                    // Update local events when homeViewModel events change
                    updateLocalEvents()
                }
                .onChange(of: homeViewModel.nearbyEvents) { _ in
                    updateLocalEvents()
                }
                .onChange(of: homeViewModel.featuredEvents) { _ in
                    updateLocalEvents()
                }
            }
            .navigationTitle("My Events")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    showNewEvent = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.sioreeWhite)
                        .frame(width: 56, height: 56)
                        .background(Color.sioreeIcyBlue)
                        .cornerRadius(Theme.CornerRadius.medium)
                }
                .padding(Theme.Spacing.m)
            }
            .sheet(isPresented: $showNewEvent) {
                NewEventPlaceholderView(onEventCreated: {
                    // Reload events after creation
                    homeViewModel.loadNearbyEvents()
                })
            }
            .sheet(isPresented: $showQRScanner) {
                if let eventId = selectedEventId {
                    QRCodeScannerView(eventId: eventId)
                }
            }
            .alert("Delete Event", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    eventToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let eventId = eventToDelete {
                        deleteEvent(eventId: eventId)
                    }
                    eventToDelete = nil
                }
            } message: {
                Text("This action is not recoverable. Are you sure you want to delete this event? It will be permanently removed and cannot be undone.")
            }
        }
    }
    
    private func eventStatusString(for event: Event) -> String {
        if event.date < Date() {
            return "Ended"
        } else if event.isFeatured {
            return "On sale"
        } else {
            return "Draft"
        }
    }
    
    private func updateLocalEvents() {
        // Combine nearby and featured events, then filter by host
        let allEvents = homeViewModel.nearbyEvents + homeViewModel.featuredEvents
        localEvents = allEvents.filter { $0.hostId == authViewModel.currentUser?.id }
    }
    
    private func deleteEvent(eventId: String) {
        print("🗑️ Deleting event: \(eventId)")
        
        // Optimistically remove from UI immediately
        localEvents.removeAll { $0.id == eventId }
        homeViewModel.nearbyEvents.removeAll { $0.id == eventId }
        homeViewModel.featuredEvents.removeAll { $0.id == eventId }
        
        let networkService = NetworkService()
        networkService.deleteEvent(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to delete event: \(error.localizedDescription)")
                        // Reload on failure to restore if delete failed
                        homeViewModel.loadNearbyEvents()
                    } else {
                        print("✅ Delete request completed")
                    }
                },
                receiveValue: { success in
                    print("✅ Delete response: \(success)")
                    if success {
                        // Event already removed optimistically, just reload to sync
                        homeViewModel.loadNearbyEvents()
                    } else {
                        print("⚠️ Delete returned false - reloading to restore")
                        // Reload to restore if delete failed
                        homeViewModel.loadNearbyEvents()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}


struct NewEventPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let onEventCreated: () -> Void
    @State private var name = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var venue = ""
    @State private var location = ""
    @State private var budget = ""
    @State private var ticketPrice = ""
    @State private var capacity = ""
    @State private var showMap = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedAddress: String?
    @State private var selectedTags: Set<String> = []
    @State private var isFeatured = false
    @State private var showFeatureInfo = false
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isFreeEntry = true
    
    let availableTags = ["Techno", "House", "Rave", "Underground", "Chill", "Lounge", "Sunset", "Party", "Pop", "Dance", "Networking", "Business", "Professional", "Jazz", "Live Music", "Cocktails", "Beach", "DJ", "Outdoor"]
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !description.isEmpty &&
        !venue.isEmpty &&
        !location.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section("Event Details") {
                        CustomTextField(placeholder: "Event Name *", text: $name)
                        CustomTextField(placeholder: "Description *", text: $description)
                        CustomTextField(placeholder: "Venue *", text: $venue)
                        DatePicker("Date *", selection: $date, displayedComponents: [.date])
                        DatePicker("Time *", selection: $time, displayedComponents: [.hourAndMinute])
                    }
                    
                    Section("Location") {
                        CustomTextField(placeholder: "Location Address *", text: $location)
                        
                        Button(action: {
                            showMap = true
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text("Select on Map")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeIcyBlue)
                            }
                        }
                        
                        if selectedLocation != nil {
                            Text("Location selected: \(selectedLocation!.latitude, specifier: "%.4f"), \(selectedLocation!.longitude, specifier: "%.4f")")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                    .onChange(of: selectedAddress) { newValue in
                        if let address = newValue, !address.isEmpty {
                            location = address
                        }
                    }
                    
                    Section("Pricing & Capacity") {
                        CustomTextField(placeholder: "Budget *", text: $budget, keyboardType: .decimalPad)
                        
                        // Free RSVP vs Paid Entry Toggle
                        Toggle("Free Entry (RSVP)", isOn: $isFreeEntry)
                            .foregroundColor(.sioreeWhite)
                            .onChange(of: isFreeEntry) { oldValue, newValue in
                                if newValue {
                                    // When toggled ON (free), clear the price
                                    ticketPrice = ""
                                }
                                // When toggled OFF (paid), user can enter price below
                            }
                        
                        if isFreeEntry {
                            Text("Attendees can RSVP for free")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        } else {
                            CustomTextField(placeholder: "Ticket Price ($)", text: $ticketPrice, keyboardType: .decimalPad)
                        }
                        
                        CustomTextField(placeholder: "Capacity (optional)", text: $capacity, keyboardType: .numberPad)
                    }
                    
                    Section("Tags") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.s) {
                                ForEach(availableTags, id: \.self) { tag in
                                    Button(action: {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }) {
                                        Text(tag)
                                            .font(.sioreeBodySmall)
                                            .foregroundColor(selectedTags.contains(tag) ? .sioreeWhite : .sioreeLightGrey)
                                            .padding(.horizontal, Theme.Spacing.m)
                                            .padding(.vertical, Theme.Spacing.s)
                                            .background(selectedTags.contains(tag) ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.2))
                                            .cornerRadius(Theme.CornerRadius.medium)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                    .stroke(selectedTags.contains(tag) ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.3), lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.s)
                        }
                    }
                    
                    Section {
                        HStack {
                            Toggle("Feature this event", isOn: $isFeatured)
                                .foregroundColor(.sioreeWhite)
                            
                            Button(action: {
                                showFeatureInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.sioreeIcyBlue)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeWhite)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                    } else {
                        Button("Create") {
                            createEvent()
                        }
                        .foregroundColor(isFormValid ? Color.sioreeIcyBlue : Color.sioreeLightGrey)
                        .disabled(!isFormValid || isCreating)
                    }
                }
            }
            .fullScreenCover(isPresented: $showMap) {
                EventLocationMapView(selectedLocation: $selectedLocation, selectedAddress: $selectedAddress)
            }
            .alert("Error Creating Event", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Feature This Event", isPresented: $showFeatureInfo) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("Featured events appear at the top of search results and in the main feed, giving your event more visibility to potential attendees.")
            }
        }
    }
    
    private func createEvent() {
        // Validate form
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        isCreating = true
        errorMessage = ""
        
        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        let combinedDate = calendar.date(from: combinedComponents) ?? date
        
        // Create event via backend API
        let networkService = NetworkService()
        // Only send ticket price if it's not free entry
        let ticketPriceValue: Double? = isFreeEntry ? nil : (Double(ticketPrice) ?? 0.0)
        let capacityValue = Int(capacity)
        
        print("🚀 Creating event: \(name)")
        print("📍 Location: \(location)")
        print("📅 Date: \(combinedDate)")
        print("💰 Ticket Price: \(ticketPriceValue?.description ?? "Free")")
        print("🆓 Is Free Entry: \(isFreeEntry)")
        
        // Call backend API to create event
        // Only send ticket price if it's a paid event (not free) and price > 0
        let finalTicketPrice: Double? = {
            if isFreeEntry {
                return nil
            }
            if let price = ticketPriceValue, price > 0 {
                return price
            }
            return nil
        }()
        
        networkService.createEvent(
            title: name,
            description: description,
            date: combinedDate,
            time: combinedDate,
            location: location,
            images: [],
            ticketPrice: finalTicketPrice,
            capacity: capacityValue
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                isCreating = false
                if case .failure(let error) = completion {
                    print("❌ Failed to create event: \(error)")
                    print("❌ Error type: \(type(of: error))")
                    
                    // Extract more detailed error message
                    var detailedError = error.localizedDescription
                    if let networkError = error as? NetworkError {
                        detailedError = networkError.errorDescription ?? detailedError
                    }
                    
                    if let decodingError = error as? DecodingError {
                        print("❌ Decoding error details:")
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("   Missing key: \(key.stringValue), path: \(context.codingPath)")
                            detailedError = "Missing field: \(key.stringValue)"
                        case .typeMismatch(let type, let context):
                            print("   Type mismatch: expected \(type), path: \(context.codingPath)")
                            detailedError = "Data type mismatch: \(type)"
                        case .valueNotFound(let type, let context):
                            print("   Value not found: \(type), path: \(context.codingPath)")
                            detailedError = "Missing value: \(type)"
                        case .dataCorrupted(let context):
                            print("   Data corrupted: \(context.debugDescription)")
                            detailedError = "Invalid data format"
                        @unknown default:
                            print("   Unknown decoding error")
                        }
                    }
                    
                    errorMessage = detailedError
                    showError = true
                } else {
                    print("✅ Event creation completed")
                }
            },
            receiveValue: { event in
                isCreating = false
                print("✅ Event created successfully: \(event.title)")
                print("✅ Event ID: \(event.id)")
                print("✅ Event hostId: \(event.hostId)")
                print("✅ Event hostName: \(event.hostName)")
                
                // Generate QR code for the event if it doesn't have one
                if event.qrCode == nil {
                    let qrCode = Event.generateEventQRCode(eventId: event.id)
                    print("✅ Generated QR code for event: \(qrCode)")
                    // TODO: Send QR code to backend to store with event
                    // For now, it's generated locally and can be used immediately
                }
                
                // Reload events list and dismiss
                onEventCreated()
                dismiss()
            }
        )
        .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    MyEventsView()
}

