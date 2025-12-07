//
//  ProfileStatsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ProfileStatsView: View {
    let eventsHosted: Int
    let eventsAttended: Int
    let followers: Int
    let following: Int
    let username: String?
    let userType: UserType?
    let userId: String?
    
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var showEventsList = false
    
    init(eventsHosted: Int, eventsAttended: Int, followers: Int, following: Int, username: String? = nil, userType: UserType? = nil, userId: String? = nil) {
        self.eventsHosted = eventsHosted
        self.eventsAttended = eventsAttended
        self.followers = followers
        self.following = following
        self.username = username
        self.userType = userType
        self.userId = userId
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: 0) {
                // Always show Followers first
                StatItem(
                    value: Helpers.formatNumber(followers),
                    label: "Followers",
                    isClickable: true,
                    action: {
                        showFollowersList = true
                    }
                )
                Divider()
                    .frame(height: 40)
                
                // Always show Following second
                StatItem(
                    value: Helpers.formatNumber(following),
                    label: "Following",
                    isClickable: true,
                    action: {
                        showFollowingList = true
                    }
                )
                
                // Show Events Attended for partiers, Events Hosted for others
                if userType == .partier {
                    Divider()
                        .frame(height: 40)
                    StatItem(
                        value: Helpers.formatNumber(eventsAttended),
                        label: "Events Attended",
                        isClickable: true,
                        action: {
                            showEventsList = true
                        }
                    )
                } else {
                    // For non-partiers, show Events Hosted (even if 0)
                    Divider()
                        .frame(height: 40)
                    StatItem(
                        value: Helpers.formatNumber(eventsHosted),
                        label: "Events Hosted",
                        isClickable: true,
                        action: {
                            showEventsList = true
                        }
                    )
                }
                
                // Show username as a stat item
                if let username = username {
                    Divider()
                        .frame(height: 40)
                    StatItem(value: "@\(username)", label: "Username", isClickable: false)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.2))
        .cornerRadius(Theme.CornerRadius.medium)
        .padding(.horizontal, Theme.Spacing.m)
        .sheet(isPresented: $showFollowersList) {
            if let userId = userId {
                UserListListView(userId: userId, listType: .followers)
            }
        }
        .sheet(isPresented: $showFollowingList) {
            if let userId = userId {
                UserListListView(userId: userId, listType: .following)
            }
        }
        .sheet(isPresented: $showEventsList) {
            if let userId = userId {
                UserEventsListView(userId: userId, userType: userType)
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let isClickable: Bool
    var action: (() -> Void)? = nil
    
    init(value: String, label: String, isClickable: Bool = false, action: (() -> Void)? = nil) {
        self.value = value
        self.label = label
        self.isClickable = isClickable
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(value)
                    .font(.sioreeH4)
                    .foregroundColor(Color.sioreeWhite)
                
                Text(label)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(!isClickable)
        .buttonStyle(PlainButtonStyle())
        .opacity(isClickable ? 1.0 : 1.0)
    }
}

#Preview {
    ProfileStatsView(
        eventsHosted: 12,
        eventsAttended: 45,
        followers: 1234,
        following: 567,
        username: "testuser",
        userType: .host
    )
}

