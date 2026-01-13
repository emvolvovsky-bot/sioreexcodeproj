//
//  AppEventCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct AppEventCard: View {
    let event: Event
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
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Event Image - Cover photo ONLY, no fallback
                CoverPhotoView(imageURL: event.images.first, height: 200)
                
                // Content - Fixed height container
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack {
                        Text(event.title)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(height: 44) // Fixed height for title
                        
                        Spacer()
                        
                        if event.isFeatured {
                            Text("FEATURED")
                                .font(.sioreeCaption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.sioreeIcyBlue)
                                .padding(.horizontal, Theme.Spacing.s)
                                .padding(.vertical, 2)
                                .background(Color.sioreeIcyBlue.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.small)
                        }
                    }
                    
                    HStack {
                        Text(event.hostName)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Text("•")
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                        
                        Text(event.location)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                            .lineLimit(1)
                    }
                    .frame(height: 20) // Fixed height for host/location
                    
                    HStack {
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Spacer()
                        
                        Text(priceText)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                    .frame(height: 24) // Fixed height for date/price
                }
                .padding(Theme.Spacing.m)
                .frame(height: 120) // Fixed total content height
                .background(Color.sioreeBlack.opacity(0.8))
            }
            .frame(height: 320) // Fixed total card height
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.sioreeBlack.opacity(0.8))
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(
                        LinearGradient(
                            colors: [Color.sioreeIcyBlue.opacity(0.5), Color.sioreeWarmGlow.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                EventDetailView(eventId: event.id)
            }
        }
    }
}

#Preview {
    AppEventCard(
        event: Event(
            id: "1",
            title: "Sample Event",
            description: "A sample event",
            hostId: "h1",
            hostName: "Sample Host",
            date: Date(),
            time: Date(),
            location: "Sample Location",
            isFeatured: true
        ),
        onTap: {}
    )
    .padding()
    .background(Color.sioreeBlack)
}

