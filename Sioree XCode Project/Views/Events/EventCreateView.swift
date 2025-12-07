//
//  EventCreateView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct EventCreateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EventViewModel(eventId: "")
    
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var location = ""
    @State private var ticketPrice: Double?
    @State private var showPriceInput = false
    
    // Talent selection
    @State private var selectedTalentIds: [String] = []
    @State private var selectedTalentType: TalentCategory? = nil
    @State private var showTalentSearch = false
    @State private var showTalentTypePicker = false
    @StateObject private var talentViewModel = TalentViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.sioreeWhite.ignoresSafeArea()
                
                Form {
                    Section("Event Details") {
                        CustomTextField(placeholder: "Event Title", text: $title)
                        CustomTextField(placeholder: "Description", text: $description)
                    }
                    
                    Section("Date & Time") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    
                    Section("Location") {
                        CustomTextField(placeholder: "Location", text: $location)
                    }
                    
                    Section("Pricing") {
                        Toggle("Ticket Price", isOn: $showPriceInput)
                        if showPriceInput {
                            TextField("Price", value: $ticketPrice, format: .currency(code: "USD"))
                        }
                    }
                    
                    Section("Talent") {
                        // Option 1: Select specific talent
                        Button(action: {
                            showTalentSearch = true
                        }) {
                            HStack {
                                Text("Select Specific Talent")
                                    .foregroundColor(.primary)
                                Spacer()
                                if !selectedTalentIds.isEmpty {
                                    Text("\(selectedTalentIds.count) selected")
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Option 2: Looking for talent type
                        Button(action: {
                            showTalentTypePicker = true
                        }) {
                            HStack {
                                Text("Looking For Talent Type")
                                    .foregroundColor(.primary)
                                Spacer()
                                if let talentType = selectedTalentType {
                                    Text(talentType.rawValue)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("None")
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Show selected options
                        if !selectedTalentIds.isEmpty {
                            Text("\(selectedTalentIds.count) talent(s) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let talentType = selectedTalentType {
                            Text("Looking for: \(talentType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                    Button("Publish") {
                        viewModel.createEvent(
                            title: title,
                            description: description,
                            date: date,
                            time: time,
                            location: location,
                            images: [],
                            ticketPrice: ticketPrice,
                            talentIds: selectedTalentIds,
                            lookingForTalentType: selectedTalentType?.rawValue
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
            .sheet(isPresented: $showTalentSearch) {
                TalentSelectionView(selectedTalentIds: $selectedTalentIds)
            }
            .sheet(isPresented: $showTalentTypePicker) {
                TalentTypePickerView(selectedType: $selectedTalentType)
            }
        }
    }
}

// Talent Selection View
struct TalentSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTalentIds: [String]
    @StateObject private var talentViewModel = TalentViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(talentViewModel.talent) { talent in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(talent.name)
                                .font(.headline)
                            Text(talent.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedTalentIds.contains(talent.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedTalentIds.contains(talent.id) {
                            selectedTalentIds.removeAll { $0 == talent.id }
                        } else {
                            selectedTalentIds.append(talent.id)
                        }
                    }
                }
            }
            .navigationTitle("Select Talent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                talentViewModel.loadTalent()
            }
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

