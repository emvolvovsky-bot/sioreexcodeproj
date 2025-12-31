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
    @StateObject private var profileViewModel = ProfileViewModel(userId: nil, useAttendedEvents: false)
    @State private var showNewEvent = false
    @State private var showQRScanner = false
    @State private var selectedEventId: String?
    @State private var eventToDelete: String?
    @State private var showDeleteConfirmation = false
    @State private var selectedSegment: ProfileViewModel.HostProfileTab = .upcoming
    @State private var selectedEventForDetail: Event? = nil
    
    private var upcomingEvents: [Event] {
        profileViewModel.upcomingEvents
    }

    private var pastEvents: [Event] {
        profileViewModel.hostedEvents
    }

    private var visibleEvents: [Event] {
        selectedSegment == .upcoming ? upcomingEvents : pastEvents
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeLightGrey)
            Text(selectedSegment == .upcoming ? "No upcoming events" : "No past events")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
            Text(selectedSegment == .upcoming ? "Create your next event!" : "Completed events will appear here")
                .font(.sioreeBody)
                .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }
    
    private var eventsGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.m),
                GridItem(.flexible(), spacing: Theme.Spacing.m)
            ],
            spacing: Theme.Spacing.m
        ) {
            ForEach(visibleEvents) { event in
                HostEventCardGrid(event: event)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
    }
    
    private func eventRowView(for event: Event) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            Button(action: {
                selectedEventForDetail = event
            }) {
                HostEventCard(
                    event: event,
                    status: eventStatusString(for: event),
                    onTap: {
                        selectedEventForDetail = event
                    }
                )
            }
            .buttonStyle(.plain)

            // Only show action buttons for upcoming events
            if event.date > Date() {
                eventActionButtons(for: event)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
    }
    
    private func eventActionButtons(for event: Event) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            // Delete Event Button
            deleteButton(for: event)
            
            // Scan Tickets Button (only for upcoming events)
            if event.date > Date() {
                scanTicketsButton(for: event)
            }
        }
    }
    
    private func deleteButton(for event: Event) -> some View {
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
    }
    
    private func scanTicketsButton(for event: Event) -> some View {
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
    
    private var segmentPicker: some View {
        Picker("Event Filter", selection: $selectedSegment) {
            ForEach(ProfileViewModel.HostProfileTab.allCases, id: \.self) { segment in
                Text(segment.rawValue)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.m)
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.m) {
                segmentPicker

                if profileViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxl)
                } else if visibleEvents.isEmpty {
                    emptyStateView
                } else {
                    // Vertical stack layout for My Events
                    VStack(spacing: Theme.Spacing.m) {
                        ForEach(visibleEvents) { event in
                            eventRowView(for: event)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 0.95))
                                ))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                }
            }
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.m)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                contentView
            }
            .onAppear {
                profileViewModel.setAuthViewModel(authViewModel)
                profileViewModel.loadProfile()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                profileViewModel.setAuthViewModel(authViewModel)
                profileViewModel.loadProfile()
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
                EventCreateView(onEventCreated: { event in
                    // Event will be added via EventCreated notification to ProfileViewModel
                    print("📡 MyEventsView received event creation callback: \(event.title)")
                }, currentUserLocation: authViewModel.currentUser?.location)
                .environmentObject(authViewModel)
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
            .navigationDestination(item: $selectedEventForDetail) { event in
                EventDetailView(eventId: event.id, isTalentMapMode: false)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func eventStatusString(for event: Event) -> String {
        if event.date < Date() {
            return "Ended"
        } else {
            return "Upcoming"
        }
    }
    
    
    private func deleteEvent(eventId: String) {
        print("🗑️ Deleting event: \(eventId)")

        let networkService = NetworkService()
        networkService.deleteEvent(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to delete event: \(error.localizedDescription)")
                        // Reload on failure
                        profileViewModel.loadProfile()
                    } else {
                        print("✅ Delete request completed")
                    }
                },
                receiveValue: { success in
                    print("✅ Delete response: \(success)")
                    if success {
                        // Post notification so all views can update
                        NotificationCenter.default.post(
                            name: NSNotification.Name("EventDeleted"),
                            object: nil,
                            userInfo: ["eventId": eventId]
                        )
                        // Remove from local ProfileViewModel
                        profileViewModel.events.removeAll { $0.id == eventId }
                        print("✅ Removed event from ProfileViewModel")
                    } else {
                        print("⚠️ Delete returned false - reloading")
                        profileViewModel.loadProfile()
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
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isFreeEntry = true
    
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
                print("✅ Event hostId: '\(event.hostId)'")
                print("✅ Event hostName: \(event.hostName)")
                print("✅ Event date: \(event.date)")
                print("✅ Current user ID: \(String(describing: StorageService.shared.getUserId()))")

                // Generate QR code for the event if it doesn't have one
                if event.qrCode == nil {
                    let qrCode = Event.generateEventQRCode(eventId: event.id)
                    print("✅ Generated QR code for event: \(qrCode)")
                    // TODO: Send QR code to backend to store with event
                    // For now, it's generated locally and can be used immediately
                }

                // Post notification so HomeViewModel and ProfileViewModel can add the event
                NotificationCenter.default.post(
                    name: NSNotification.Name("EventCreated"),
                    object: nil,
                    userInfo: ["event": event]
                )

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

