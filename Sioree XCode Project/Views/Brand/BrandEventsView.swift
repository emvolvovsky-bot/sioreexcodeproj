//
//  BrandEventsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BrandEventsView: View {
    @State private var events: [(event: String, city: String, reach: String, spend: String, date: String)] = [
        ("Halloween Mansion Party", "Los Angeles", "5,000", "$2,500", "Oct 31"),
        ("Rooftop Sunset Sessions", "Los Angeles", "3,200", "$1,800", "Nov 5"),
        ("Underground Rave Warehouse", "Los Angeles", "4,500", "$2,200", "Nov 12"),
        ("Beachside Bonfire", "Malibu", "2,100", "$1,200", "Nov 18")
    ]
    
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
                    LazyVStack(spacing: Theme.Spacing.m) {
                        ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                            BrandEventCard(event: event)
                                .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BrandEventCard: View {
    let event: (event: String, city: String, reach: String, spend: String, date: String)
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(event.event)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                    
                    HStack(spacing: Theme.Spacing.s) {
                        Label(event.city, systemImage: "location.fill")
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Text("•")
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                        
                        Text(event.date)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.sioreeLightGrey.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Est. Reach")
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                    Text(event.reach)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeWhite)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text("Est. Spend")
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                    Text(event.spend)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeIcyBlue)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    BrandEventsView()
}

