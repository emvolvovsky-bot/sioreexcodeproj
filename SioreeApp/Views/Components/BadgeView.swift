//
//  BadgeView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: badge.icon)
                .font(.sioreeCaption)
                .foregroundColor(Color.sioreeIcyBlue)
            
            Text(badge.name)
                .font(.sioreeCaption)
                .foregroundColor(Color.sioreeCharcoal)
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Color.sioreeLightGrey)
        .cornerRadius(Theme.CornerRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    HStack {
        BadgeView(badge: Badge.eventsAttended10)
        BadgeView(badge: Badge.verifiedHost)
    }
    .padding()
}

