//
//  HostEventCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

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

