//
//  PlaceholderEventCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PlaceholderEventCard: View {
    let index: Int
    var isVertical: Bool
    
    init(index: Int, isVertical: Bool = false) {
        self.index = index
        self.isVertical = isVertical
    }
    
    private var placeholderTitles = [
        "Summer Music Festival",
        "Rooftop Party NYC",
        "Underground Rave",
        "Jazz Night Downtown",
        "Electronic Dance Party"
    ]
    
    private var placeholderHosts = [
        "DJ MixMaster",
        "Event Pro",
        "Party Central",
        "Nightlife Co",
        "Music Collective"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // Placeholder image
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.sioreeIcyBlue.opacity(0.3),
                            Color.sioreeWarmGlow.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: isVertical ? 200 : 180)
                .overlay(
                    VStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundColor(.sioreeIcyBlue.opacity(0.5))
                    }
                )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(placeholderTitles[index % placeholderTitles.count])
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)
                    .lineLimit(2)
                
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.sioreeLightGrey)
                    
                    Text(placeholderHosts[index % placeholderHosts.count])
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
                
                HStack(spacing: Theme.Spacing.m) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.sioreeIcyBlue)
                        Text("Sat, Dec 15")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.sioreeIcyBlue)
                        Text("9:00 PM")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.sioreeIcyBlue)
                        Text("NYC")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                
                HStack {
                    Spacer()
                    Text("$25")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    PlaceholderEventCard(index: 0)
        .padding()
}

