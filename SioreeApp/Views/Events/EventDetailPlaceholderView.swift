//
//  EventDetailPlaceholderView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct EventDetailPlaceholderView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        AppEventCard(event: event) {}
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        // Attendees Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Attendees")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            NavigationLink(destination: EventAttendeesView(eventId: event.id, eventName: event.title)) {
                                HStack {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.sioreeIcyBlue)
                                    
                                    Text("View All Attendees")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                                )
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                        
                        Text("Event details coming soon")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeIcyBlue)
                }
            }
        }
    }
}

#Preview {
    EventDetailPlaceholderView(
        event: Event(
            id: "1",
            title: "Sample Event",
            description: "A sample event",
            hostId: "h1",
            hostName: "Sample Host",
            date: Date(),
            time: Date(),
            location: "Sample Location"
        )
    )
}

