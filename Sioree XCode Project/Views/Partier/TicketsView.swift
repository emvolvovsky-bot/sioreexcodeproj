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
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control
                    Picker("", selection: $selectedSegment) {
                        Text("Upcoming").tag(0)
                        Text("Past").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(Theme.Spacing.m)
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            if viewModel.isLoading && selectedSegment == 1 {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.xxl)
                            } else {
                                let events = selectedSegment == 0 ? viewModel.upcomingEvents : viewModel.pastEvents
                                
                                if events.isEmpty {
                                    VStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: selectedSegment == 0 ? "ticket" : "ticket.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                                        Text(selectedSegment == 0 ? "No upcoming tickets" : "No past tickets")
                                            .font(.sioreeH3)
                                            .foregroundColor(Color.sioreeWhite)
                                        Text(selectedSegment == 0 ? "RSVP to events to see them here" : "Attend events to see them here")
                                            .font(.sioreeBody)
                                            .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.xxl)
                                } else {
                                    ForEach(events) { event in
                                        TicketCard(event: event, isPast: selectedSegment == 1)
                                            .padding(.horizontal, Theme.Spacing.m)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Tickets")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadTickets()
            }
        }
    }
}

struct TicketCard: View {
    let event: Event
    let isPast: Bool
    @State private var showTicketDetail = false
    @State private var showReview = false
    
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
        VStack(spacing: Theme.Spacing.s) {
            // Main Ticket Card
            Button(action: {
                if !isPast {
                    showTicketDetail = true
                }
            }) {
                HStack(spacing: Theme.Spacing.m) {
                    // QR Code or Invalid Badge
                    if isPast {
                        ZStack {
                            Rectangle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                                Text("EXPIRED")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                        .cornerRadius(Theme.CornerRadius.small)
                    } else if let qrImage = QRCodeService.shared.generateTicketQRCode(
                        ticketId: ticket.id,
                        eventId: ticket.eventId,
                        userId: ticket.userId
                    ) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .background(Color.white)
                            .cornerRadius(Theme.CornerRadius.small)
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(Color.sioreeLightGrey.opacity(0.3))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(event.title)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)
                        
                        Text(event.hostName)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        if isPast {
                            Text("Event Ended")
                                .font(.sioreeCaption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                    
                    if !isPast {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                .padding(Theme.Spacing.m)
                .background(isPast ? Color.sioreeLightGrey.opacity(0.05) : Color.sioreeLightGrey.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(isPast ? Color.red.opacity(0.5) : Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                )
            }
            .disabled(isPast)
            
            // Review Section (only for past events)
            if isPast {
                VStack(spacing: Theme.Spacing.s) {
                    // Host Review Button - goes to host profile
                    NavigationLink(destination: UserProfileView(userId: event.hostId)) {
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.sioreeWarmGlow)
                            Text("Review Host: \(event.hostName)")
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeIcyBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.sioreeIcyBlue)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.sioreeIcyBlue.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.small)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Talent Review Buttons (only if talents exist) - goes to talent profile
                    if !event.talentIds.isEmpty {
                        ForEach(Array(event.talentIds.enumerated()), id: \.element) { index, talentId in
                            NavigationLink(destination: UserProfileView(userId: talentId)) {
                                HStack(spacing: Theme.Spacing.s) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.sioreeWarmGlow)
                                    Text("Review Talent")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeIcyBlue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.sioreeIcyBlue)
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(Color.sioreeIcyBlue.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.small)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
        .sheet(isPresented: $showTicketDetail) {
            TicketDetailView(ticket: ticket)
        }
    }
}

#Preview {
    TicketsView()
}

