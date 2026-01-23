//
//  TalentEventsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct TalentEventsView: View {
    let events: [Event]
    @State private var selectedSegment: EventSegment = .upcoming
    
    enum EventSegment: String, CaseIterable {
        case upcoming = "Upcoming"
        case completed = "Completed"
    }
    
    var upcomingEvents: [Event] {
        let now = Date()
        return events.filter { event in
            event.date >= now
        }
    }
    
    var completedEvents: [Event] {
        let now = Date()
        return events.filter { event in
            event.date < now
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            // Segment Control
            Picker("", selection: $selectedSegment) {
                ForEach(EventSegment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.m)
            
            // Events List
            LazyVStack(spacing: Theme.Spacing.m) {
                let displayEvents = selectedSegment == .upcoming ? upcomingEvents : completedEvents
                
                if displayEvents.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: selectedSegment == .upcoming ? "calendar.badge.plus" : "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                        
                        Text(selectedSegment == .upcoming ? "No upcoming events" : "No completed events")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                        
                        Text(selectedSegment == .upcoming ? "Your upcoming events will appear here" : "Your completed events will appear here")
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
                } else {
                    ForEach(displayEvents) { event in
                        EventCard(
                            event: event,
                            onTap: {},
                            onLike: {},
                            onSave: {}
                        )
                    }
                }
            }
            .padding(.top, Theme.Spacing.m)
        }
    }
}

#Preview {
    TalentEventsView(events: [])
}

