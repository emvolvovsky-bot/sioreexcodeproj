//
//  EventCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct EventCard: View {
    let event: Event
    let onTap: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image with enhanced visual
            ZStack(alignment: .topTrailing) {
                if let firstImage = event.images.first {
                    AsyncImage(url: URL(string: firstImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        // Enhanced placeholder with gradient
                        ZStack {
                            LinearGradient(
                                colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.sioreeIcyBlue.opacity(0.6))
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                } else {
                    // Enhanced empty state with gradient
                    ZStack {
                        LinearGradient(
                            colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.sioreeIcyBlue.opacity(0.6))
                    }
                    .frame(height: 200)
                }
                
                // Action buttons
                HStack(spacing: Theme.Spacing.s) {
                    Button(action: onSave) {
                        Image(systemName: event.isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(event.isSaved ? Color.sioreeIcyBlue : Color.sioreeWhite)
                            .padding(Theme.Spacing.s)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Button(action: onLike) {
                        Image(systemName: event.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(event.isLiked ? Color.red : Color.sioreeWhite)
                            .padding(Theme.Spacing.s)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(Theme.Spacing.m)
            }
            
            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(event.title)
                    .font(.sioreeH4)
                    .foregroundColor(Color.sioreeCharcoal)
                    .lineLimit(2)
                
                HStack(spacing: Theme.Spacing.s) {
                    AvatarView(imageURL: event.hostAvatar, size: .small)
                    Text(event.hostName)
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeCharcoal.opacity(0.7))
                }
                
                HStack(spacing: Theme.Spacing.m) {
                    Label(event.date.formattedEventDate(), systemImage: "calendar")
                    Label(event.time.formattedEventTime(), systemImage: "clock")
                }
                .font(.sioreeCaption)
                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                
                if let price = event.ticketPrice {
                    Text(Helpers.formatCurrency(price))
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.sioreeIcyBlue)
                }
            }
            .padding(Theme.Spacing.m)
            .background(Color.sioreeWhite.opacity(0.05))
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.sioreeWhite.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(Theme.CornerRadius.medium)
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    EventCard(
        event: Event(
            title: "Underground Rave",
            description: "An amazing night",
            hostId: "1",
            hostName: "Nightlife Collective",
            date: Date(),
            time: Date(),
            location: "Warehouse District"
        ),
        onTap: {},
        onLike: {},
        onSave: {}
    )
    .padding()
}

