//
//  NotificationsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if notifications.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.3))
                        
                        Text("No Notifications")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct NotificationItem: Identifiable {
    let id: String
    let type: NotificationType
    let message: String
    let timestamp: Date
    let isRead: Bool
    let userId: String?
    let eventId: String?
}

enum NotificationType {
    case follow
    case event
    case booking
    case mention
}

struct NotificationRow: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Circle()
                .fill(notification.isRead ? Color.clear : Color.sioreeIcyBlue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(notification.message)
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeWhite)
                
                Text(notification.timestamp.formattedRelative())
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey)
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.s)
    }
}

#Preview {
    NotificationsView()
}

