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
                            ticketPrice: ticketPrice
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
        }
    }
}

#Preview {
    EventCreateView()
}

