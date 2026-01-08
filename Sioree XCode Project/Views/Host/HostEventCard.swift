//
//  HostEventCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct HostEventCard: View {
    let event: Event
    let status: String
    let onTap: () -> Void
    @State private var showDetail = false
    
    private var priceText: String {
        if let price = event.ticketPrice, price > 0 {
            return String(format: "$%.0f", price)
        } else {
            return "FREE"
        }
    }
    
    var body: some View {
        Button(action: {
            showDetail = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Image placeholder with status badge
                ZStack {
                    Color.sioreeLightGrey.opacity(0.3)
                        .frame(height: 200)
                    
                    // Image icon centered
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                    
                    // Status badge in top right
                    VStack {
                        HStack {
                            Spacer()
                            StatusChip(status: status)
                                .padding(Theme.Spacing.s)
                        }
                        Spacer()
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(event.title)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                    
                    HStack {
                        Text(event.hostName)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Text("•")
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                        
                        Text(event.location)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                    
                    HStack {
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Spacer()
                        
                        Text(priceText)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
                .padding(Theme.Spacing.m)
                .background(Color.sioreeBlack)
            }
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
            )
        }
        .sheet(isPresented: $showDetail) {
            EventDetailPlaceholderView(event: event)
        }
    }
}

struct HostEventCardGrid: View {
    let event: Event
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Event cover photo (prioritized)
            ZStack {
                if let imageUrl = event.images.first, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(height: 180)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Event info overlay (same style as partier profile)
            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                Text(event.title)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeWhite)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.8), radius: 2)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                }
                .shadow(color: Color.black.opacity(0.8), radius: 2)

            }
            .padding(Theme.Spacing.s)
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeIcyBlue.opacity(0.3),
                    Color.sioreeCharcoal.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "party.popper.fill")
                .font(.system(size: 40))
                .foregroundColor(.sioreeIcyBlue.opacity(0.5))
        }
    }
}

struct HostUpcomingEventCard: View {
    let event: Event
    let authViewModel: AuthViewModel
    @State private var showAttendees = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event cover photo
            ZStack(alignment: .bottomLeading) {
                if let coverPhotoUrl = event.images.first, let url = URL(string: coverPhotoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Event info overlay
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Spacer()
                    Text(event.title)
                        .font(.sioreeH3)
                        .foregroundColor(.sioreeWhite)
                        .lineLimit(2)
                        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 2)
                    
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.sioreeLightGrey)
                        Text(event.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeLightGrey)
                        
                        Text("•")
                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.sioreeLightGrey)
                        Text(event.location)
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeLightGrey)
                            .lineLimit(1)
                    }
                    .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 2)
                }
                .padding(Theme.Spacing.m)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            
            // Attendee List Button
            Button(action: {
                showAttendees = true
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.sioreeIcyBlue)
                    Text("Attendee List")
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.sioreeIcyBlue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                }
                .padding(Theme.Spacing.m)
                .background(Color.sioreeCharcoal.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.sioreeCharcoal.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showAttendees) {
            NavigationStack {
                EventAttendeesView(eventId: event.id, eventName: event.title)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeIcyBlue.opacity(0.3),
                    Color.sioreeCharcoal.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "party.popper.fill")
                .font(.system(size: 60))
                .foregroundColor(.sioreeIcyBlue.opacity(0.5))
        }
    }
}

#Preview {
    HostEventCard(
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
        status: "On sale",
        onTap: {}
    )
    .padding()
    .background(Color.sioreeBlack)
}

#Preview("Grid Card") {
    HostEventCardGrid(
        event: Event(
            id: "1",
            title: "Summer Music Festival",
            description: "A sample event",
            hostId: "h1",
            hostName: "Sample Host",
            date: Date(),
            time: Date(),
            location: "Sample Location",
            ticketPrice: 25.0
        ),
        onTap: {}
    )
    .frame(width: 180, height: 220)
    .padding()
    .background(Color.sioreeBlack)
}

