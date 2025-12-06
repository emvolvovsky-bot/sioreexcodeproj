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
                // Event Image with enhanced gradient
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.sioreeIcyBlue.opacity(0.4),
                            Color.sioreeWarmGlow.opacity(0.3),
                            Color.sioreeIcyBlue.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    
                    // Animated party icon
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                        .shadow(color: .sioreeIcyBlue.opacity(0.5), radius: 10)
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack {
                        Text(event.title)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
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
                .background(Color.sioreeBlack.opacity(0.8))
            }
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

