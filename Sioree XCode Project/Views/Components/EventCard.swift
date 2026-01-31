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
    private let cardCornerRadius: CGFloat = 18
    private let imageHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image - Cover photo ONLY, no fallback
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: imageHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                            .stroke(Color.sioreeWhite.opacity(0.12), lineWidth: 0.5)
                    )
                
                CoverPhotoView(imageURL: event.images.first, height: imageHeight)
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Action buttons (save/bookmark only)
                HStack(spacing: Theme.Spacing.s) {
                    Button(action: onSave) {
                        Image(systemName: event.isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(event.isSaved ? Color.sioreeIcyBlue : Color.sioreeWhite)
                            .padding(Theme.Spacing.s)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(Theme.Spacing.m)
            }
            .frame(height: imageHeight)
            
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
                
                HStack(spacing: Theme.Spacing.xs) {
                    Text("View event")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                }
                .font(.sioreeCaption)
                .foregroundColor(Color.sioreeIcyBlue)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.m)
            .background(Color.sioreeWhite.opacity(0.04))
        }
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color.sioreeWhite.opacity(0.06))
                .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.sioreeWhite.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .padding(.horizontal, Theme.Spacing.m)
        .onTapGesture(perform: onTap)
        .accessibilityAddTraits(.isButton)
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

