//
//  EventEditView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import Combine

struct EventEditView: View {
    let event: Event
    let onEventUpdated: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var date: Date
    @State private var time: Date
    @State private var location: String
    @State private var showMap = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedAddress: String?
    @State private var capacity: String
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var cancellables = Set<AnyCancellable>()
    
    init(event: Event, onEventUpdated: @escaping () -> Void) {
        self.event = event
        self.onEventUpdated = onEventUpdated
        
        // Initialize state with event data
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description)
        _date = State(initialValue: event.date)
        _time = State(initialValue: event.time)
        _location = State(initialValue: event.location)
        _capacity = State(initialValue: event.capacity.map { String($0) } ?? "")
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
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
                        CustomTextField(placeholder: "Event Name *", text: $title)
                        CustomTextField(placeholder: "Description *", text: $description)
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
                    
                    Section("Capacity") {
                        CustomTextField(placeholder: "Capacity (optional)", text: $capacity, keyboardType: .numberPad)
                    }
                    
                    Section("Pricing") {
                        HStack {
                            Text("Ticket Price")
                                .foregroundColor(.sioreeWhite)
                            Spacer()
                            if let price = event.ticketPrice, price > 0 {
                                Text(Helpers.formatCurrency(price))
                                    .foregroundColor(.sioreeLightGrey)
                            } else {
                                Text("Free")
                                    .foregroundColor(.sioreeLightGrey)
                            }
                        }
                        Text("Price cannot be changed after event creation")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey.opacity(0.7))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeWhite)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                    } else {
                        Button("Save") {
                            updateEvent()
                        }
                        .foregroundColor(isFormValid ? Color.sioreeIcyBlue : Color.sioreeLightGrey)
                        .disabled(!isFormValid || isUpdating)
                    }
                }
            }
            .fullScreenCover(isPresented: $showMap) {
                EventLocationMapView(selectedLocation: $selectedLocation, selectedAddress: $selectedAddress)
            }
            .alert("Error Updating Event", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateEvent() {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        isUpdating = true
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
        
        let networkService = NetworkService()
        let capacityValue = capacity.isEmpty ? nil : Int(capacity)
        
        // Update event via backend API (we'll need to add this method to NetworkService)
        networkService.updateEvent(
            eventId: event.id,
            title: title,
            description: description,
            date: combinedDate,
            time: combinedDate,
            location: location,
            capacity: capacityValue
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                isUpdating = false
                if case .failure(let error) = completion {
                    print("❌ Failed to update event: \(error)")
                    errorMessage = error.localizedDescription
                    showError = true
                }
            },
            receiveValue: { updatedEvent in
                print("✅ Event updated successfully: \(updatedEvent.title)")
                // Post notification so views can update
                NotificationCenter.default.post(
                    name: NSNotification.Name("EventUpdated"),
                    object: nil,
                    userInfo: ["eventId": event.id, "event": updatedEvent]
                )
                onEventUpdated()
                dismiss()
            }
        )
        .store(in: &cancellables)
    }
}

#Preview {
    EventEditView(
        event: Event(
            id: "1",
            title: "Sample Event",
            description: "A sample event",
            hostId: "h1",
            hostName: "Sample Host",
            date: Date(),
            time: Date(),
            location: "Sample Location",
            ticketPrice: 25.0
        ),
        onEventUpdated: {}
    )
    .environmentObject(AuthViewModel())
}

