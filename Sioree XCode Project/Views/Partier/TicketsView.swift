//
//  TicketsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct TicketsView: View {
    @StateObject private var viewModel = TicketsViewModel()
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    customSegmentedControl
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.s)
                    
                    // Content
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            if viewModel.isLoading && selectedSegment == 1 {
                                ProgressView()
                                    .tint(.sioreeIcyBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.xxl)
                            } else {
                                let events = selectedSegment == 0 ? viewModel.upcomingEvents : viewModel.pastEvents
                                
                                if events.isEmpty {
                                    emptyStateView
                                } else {
                                    ForEach(events) { event in
                                        TicketCard(event: event, isPast: selectedSegment == 1)
                                            .padding(.horizontal, Theme.Spacing.l)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.loadTickets()
            }
        }
    }
    
    private var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeBlack,
                    Color.sioreeBlack.opacity(0.98),
                    Color.sioreeCharcoal.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -120, y: -320)
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: 160, y: 220)
        }
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: Theme.Spacing.xs) {
            segmentButton(title: "Upcoming", isSelected: selectedSegment == 0) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedSegment = 0
                }
            }
            
            segmentButton(title: "Past", isSelected: selectedSegment == 1) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedSegment = 1
                }
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sioreeBody)
                .fontWeight(.semibold)
                .foregroundColor(.sioreeWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Group {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.sioreeIcyBlue.opacity(0.35), radius: 12, x: 0, y: 6)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: selectedSegment == 0 ? "ticket" : "ticket.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                .shadow(color: Color.sioreeIcyBlue.opacity(0.3), radius: 16)
            
            Text(selectedSegment == 0 ? "No upcoming tickets" : "No past tickets")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
            
            Text(selectedSegment == 0 ? "RSVP to events to see them here" : "Attend events to see them here")
                .font(.sioreeBody)
                .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }
}

struct TicketCard: View {
    let event: Event
    let isPast: Bool
    @State private var showTicketDetail = false
    
    // Create ticket from event
    private var ticket: Ticket {
        Ticket(
            eventId: event.id,
            userId: StorageService.shared.getUserId() ?? "user1",
            eventTitle: event.title,
            eventDate: event.date,
            eventLocation: event.location,
            hostName: event.hostName,
            price: event.ticketPrice ?? 0.0
        )
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            // Main Ticket Card
            Button(action: {
                if !isPast {
                    showTicketDetail = true
                }
            }) {
                ZStack {
                    // Glass morphism background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(isPast ? Color.red.opacity(0.3) : Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: isPast ? Color.red.opacity(0.1) : Color.sioreeIcyBlue.opacity(0.16), radius: 24, x: 0, y: 12)
                    
                    HStack(spacing: Theme.Spacing.m) {
                        // Ticket Icon Badge
                        ticketIconSection
                        
                        // Event Info
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(event.title)
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                                .lineLimit(2)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.8))
                                Text(event.hostName)
                                    .font(.sioreeBodySmall)
                                    .foregroundColor(.sioreeLightGrey)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.8))
                                Text(event.location)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                                    .lineLimit(1)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.8))
                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                            }
                            
                            if isPast {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red.opacity(0.8))
                                        .frame(width: 6, height: 6)
                                    Text("Event Ended")
                                        .font(.sioreeCaption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red.opacity(0.9))
                                }
                                .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                        
                        if !isPast {
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                        }
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .disabled(isPast)
            
            // Review Section (only for past events)
            // (Removed review UI for past events)
        }
        .sheet(isPresented: $showTicketDetail) {
            TicketDetailView(ticket: ticket)
        }
    }
    
    private var ticketIconSection: some View {
        ZStack {
            if isPast {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: 90, height: 90)
                
                VStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                    Text("EXPIRED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                }
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.sioreeIcyBlue.opacity(0.2),
                                Color.sioreeIcyBlue.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.sioreeIcyBlue.opacity(0.4), lineWidth: 1.5)
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.2), radius: 12, x: 0, y: 6)
                
                Image(systemName: "ticket.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.sioreeIcyBlue,
                                Color.sioreeIcyBlue.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    private var reviewSection: some View {
        EmptyView()
    }
}

#Preview {
    TicketsView()
}

