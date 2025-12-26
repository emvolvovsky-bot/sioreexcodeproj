//
//  ProfileStatsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ProfileStatsView: View {
    let followers: Int
    let following: Int
    let username: String?
    let userId: String?
    
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    
    init(followers: Int, following: Int, username: String? = nil, userId: String? = nil) {
        self.followers = followers
        self.following = following
        self.username = username
        self.userId = userId
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: 0) {
                // Followers
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
                
                // Following
                StatItem(
                    value: Helpers.formatNumber(following),
                    label: "Following",
                    isClickable: true,
                    action: {
                        showFollowingList = true
                    }
                )
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
        followers: 1234,
        following: 567,
        username: "testuser"
    )
}

