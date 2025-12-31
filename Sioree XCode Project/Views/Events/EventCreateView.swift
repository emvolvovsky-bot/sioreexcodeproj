//
//  EventCreateView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit

struct EventCreateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EventViewModel(eventId: "")
    var onEventCreated: ((Event) -> Void)? = nil
    var currentUserLocation: String? = nil
    
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var location = ""
    @State private var showMap = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String?
    @State private var ticketPrice: Double?
    @State private var showPriceInput = false
  @State private var capacity: String = ""
    @State private var isPublishing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var selectedLookingForTalents: Set<TalentCategory> = []
    @State private var lookingForNotes: String = ""
    @State private var isRequestingTalent = true
    @State private var showTalentBrowser = false
    private let availableTalentCategories: [TalentCategory] = TalentCategory.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.sioreeWhite.ignoresSafeArea()
                
                Form {
                    Section("Event Details") {
                        CustomTextField(placeholder: "Event Title", text: $title)
                        CustomTextField(placeholder: "Additional Info", text: $description)
                    }
                    
                    Section("Date & Time") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    
                    Section("Location") {
                        CustomTextField(placeholder: "Location", text: $location)
                        
                        Button(action: {
                            showMap = true
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text("Select on Map")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.sioreeBody)
                                Spacer()
                                if let coord = selectedCoordinate {
                                    Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedAddress) { newValue in
                        if let address = newValue, !address.isEmpty {
                            location = address
                        }
                    }
                    
                    Section("Pricing") {
                        Toggle("Ticket Price", isOn: $showPriceInput)
                        if showPriceInput {
                            TextField("Price", value: $ticketPrice, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        }

                      TextField("Capacity (optional)", text: $capacity)
                        .keyboardType(.numberPad)
                    }

                    // Request talent section
                    Section("Request Talent") {
                        Button {
                            showTalentBrowser = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text("Browse & Request Talent")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.sioreeBody)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(.plain)

                        Text("Select specific talent to send direct requests to work your event.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Looking for talent section
                    Section("Looking For Talent") {
                        Text(isRequestingTalent ?
                            "Specify the talent roles you need. Your event will be highlighted to matching talent." :
                            "Specify the talent roles you need. Talent can browse and find your event.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common Roles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(availableTalentCategories, id: \.self) { category in
                                        Button {
                                            toggle(category, in: &selectedLookingForTalents)
                                        } label: {
                                            tagChip(category.rawValue, color: selectedLookingForTalents.contains(category) ? .sioreeIcyBlue : .sioreeCharcoal.opacity(0.4))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Notes for talent (optional)", text: $lookingForNotes, axis: .vertical)
                                .lineLimit(1...3)
                                .autocorrectionDisabled(false)
                                .textInputAutocapitalization(.sentences)
                        }
                        
                        if !lookingForRolesPayload.isEmpty {
                            tagChip("Roles: \(lookingForRolesPayload.joined(separator: ", "))", color: .sioreeIcyBlue.opacity(0.85))
                        }
                        if let notes = lookingForNotesPayload, !notes.isEmpty {
                            tagChip("Notes: \(notes)", color: .sioreeLightGrey)
                        }
                        if isRequestingTalent {
                            tagChip("🎯 Actively Requesting Talent", color: .green.opacity(0.8))
                        }
                    }
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPublishing = true
                        let capacityValue = Int(capacity.trimmingCharacters(in: .whitespacesAndNewlines))
                        viewModel.createEvent(
                            title: title,
                            description: description,
                            date: date,
                            time: time,
                            location: location,
                            images: [],
                            ticketPrice: ticketPrice,
                            capacity: capacityValue,
                            talentIds: [],
                            lookingForRoles: lookingForRolesPayload,
                            lookingForNotes: lookingForNotesPayload,
                            lookingForTalentType: lookingForTalentTypePayload
                        ) { result in
                            DispatchQueue.main.async {
                                isPublishing = false
                                switch result {
                                case .success(let event):
                                    onEventCreated?(event)
                                    dismiss()
                                case .failure(let error):
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    } label: {
                        if isPublishing {
                            ProgressView()
                        } else {
                            Text("Publish")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(title.isEmpty || location.isEmpty || isPublishing)
                }
            }
            .fullScreenCover(isPresented: $showMap) {
                EventLocationMapView(selectedLocation: $selectedCoordinate, selectedAddress: $selectedAddress, initialUserLocation: currentUserLocation)
            }
            .fullScreenCover(isPresented: $showTalentBrowser) {
                TalentBrowserView(event: nil, onTalentRequested: { talent in
                    // Handle talent request callback
                    print("Requested talent: \(talent.name)")
                    // In a real implementation, this would create a booking request
                    // and send a notification to the talent
                })
            }
            .alert("Event Publish Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage.isEmpty ? "Please try again." : errorMessage)
            }
        }
    }
    
    private var lookingForRolesPayload: [String] {
        let categoryRoles = selectedLookingForTalents.map { $0.rawValue.trimmingCharacters(in: .whitespacesAndNewlines) }
        return Array(Set(categoryRoles)).filter { !$0.isEmpty }
    }
    
    private var lookingForNotesPayload: String? {
        let trimmed = lookingForNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private var lookingForTalentTypePayload: String {
        if !lookingForRolesPayload.isEmpty {
            return lookingForRolesPayload.joined(separator: ", ")
        }
        if let notes = lookingForNotesPayload, !notes.isEmpty {
            return notes
        }
        return "General talent"
    }
    
    private var lookingForSummary: String? {
        var parts: [String] = []
        if !lookingForRolesPayload.isEmpty {
            parts.append(lookingForRolesPayload.joined(separator: ", "))
        }
        if let notes = lookingForNotesPayload {
            parts.append(notes)
        }
        let combined = parts.joined(separator: " — ")
        return combined.isEmpty ? nil : combined
    }
    
    @ViewBuilder
    private func tagChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.sioreeWhite)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.85))
            .cornerRadius(12)
    }
    
    private func toggle(_ category: TalentCategory, in set: inout Set<TalentCategory>) {
        if set.contains(category) {
            set.remove(category)
        } else {
            set.insert(category)
        }
    }
    
}


// Talent Type Picker View
struct TalentTypePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedType: TalentCategory?
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedType = nil
                    dismiss()
                }) {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedType == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(TalentCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedType = category
                        dismiss()
                    }) {
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            if selectedType == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Talent Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EventCreateView()
}

