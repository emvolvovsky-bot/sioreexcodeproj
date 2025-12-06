//
//  StatusChip.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct StatusChip: View {
    let statusText: String
    let statusColor: Color
    
    init(status: EventStatus) {
        self.statusText = status.rawValue
        self.statusColor = StatusChip.colorForEventStatus(status)
    }
    
    init(status: GigStatus) {
        self.statusText = status.rawValue
        self.statusColor = StatusChip.colorForGigStatus(status)
    }
    
    init(status: String) {
        self.statusText = status
        self.statusColor = StatusChip.colorForStringStatus(status)
    }
    
    var body: some View {
        Text(statusText)
            .font(.sioreeCaption)
            .fontWeight(.semibold)
            .foregroundColor(statusColor)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .cornerRadius(Theme.CornerRadius.small)
    }
    
    private static func colorForEventStatus(_ status: EventStatus) -> Color {
        switch status {
        case .draft: return Color.sioreeLightGrey
        case .published: return Color.sioreeIcyBlue
        case .cancelled: return Color.red.opacity(0.7)
        case .completed: return Color.sioreeCharcoal
        }
    }
    
    private static func colorForGigStatus(_ status: GigStatus) -> Color {
        switch status {
        case .requested: return Color.sioreeLightGrey
        case .confirmed: return Color.sioreeIcyBlue
        case .paid: return Color.sioreeWarmGlow
        case .completed: return Color.green.opacity(0.7)
        }
    }
    
    private static func colorForStringStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "live", "on sale", "published": return Color.sioreeIcyBlue
        case "pending": return Color.sioreeWarmGlow
        case "draft": return Color.sioreeLightGrey
        case "ended", "completed": return Color.sioreeCharcoal
        case "cancelled": return Color.red.opacity(0.7)
        default: return Color.sioreeLightGrey
        }
    }
}

#Preview {
    HStack {
        StatusChip(status: EventStatus.draft)
        StatusChip(status: EventStatus.published)
        StatusChip(status: GigStatus.confirmed)
        StatusChip(status: "Live")
    }
    .padding()
    .background(Color.sioreeBlack)
}

