//
//  InstagramStyleProfileHeader.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct InstagramStyleProfileHeader: View {
    let user: User
    let postsCount: Int
    let followerCount: Int
    let followingCount: Int
    let onEditProfile: () -> Void
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    let showEventsStat: Bool
    let showEditButton: Bool
    
    init(
        user: User,
        postsCount: Int,
        followerCount: Int,
        followingCount: Int,
        onEditProfile: @escaping () -> Void,
        onFollowersTap: @escaping () -> Void,
        onFollowingTap: @escaping () -> Void,
        showEventsStat: Bool = false,
        showEditButton: Bool = true
    ) {
        self.user = user
        self.postsCount = postsCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.onEditProfile = onEditProfile
        self.onFollowersTap = onFollowersTap
        self.onFollowingTap = onFollowingTap
        self.showEventsStat = showEventsStat
        self.showEditButton = showEditButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile photo and stats row
            HStack(spacing: 20) {
                // Profile photo on left
                AvatarView(
                    imageURL: user.avatar,
                    size: .large,
                    showBorder: user.verified
                )
                .frame(width: 90, height: 90)
                
                // Stats in horizontal row on right (Instagram-style: evenly distributed)
                HStack(spacing: 0) {
                    // Posts
                    StatButton(
                        value: "\(postsCount)",
                        label: "Posts",
                        action: {}
                    )
                    
                    // Followers
                    StatButton(
                        value: "\(Helpers.formatNumber(followerCount))",
                        label: "Followers",
                        action: onFollowersTap
                    )
                    
                    // Following
                    StatButton(
                        value: "\(Helpers.formatNumber(followingCount))",
                        label: "Following",
                        action: onFollowingTap
                    )
                    
                    if showEventsStat {
                        StatButton(
                            value: "\(Helpers.formatNumber(user.eventCount))",
                            label: "Events",
                            action: {}
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Bio section
            VStack(alignment: .leading, spacing: 4) {
                if !user.name.isEmpty {
                    Text(user.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.sioreeWhite)
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(.sioreeWhite)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let location = user.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(location)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.sioreeLightGrey)
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Edit Profile button - only for current user
            if showEditButton {
                Button(action: onEditProfile) {
                    Text("Edit Profile")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.sioreeWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            LinearGradient(
                                colors: [Color.sioreeIcyBlue.opacity(0.8), Color.sioreeIcyBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color.sioreeIcyBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
}

struct StatButton: View {
    let value: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sioreeWhite)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.sioreeLightGrey)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.sioreeBlack.ignoresSafeArea()
        
        InstagramStyleProfileHeader(
            user: User(
                email: "test@example.com",
                username: "testuser",
                name: "Test User",
                bio: "This is a sample bio that can span multiple lines to show how the Instagram-style layout handles longer text content.",
                userType: .partier,
                location: "New York, NY"
            ),
            postsCount: 42,
            followerCount: 1500,
            followingCount: 200,
            onEditProfile: {},
            onFollowersTap: {},
            onFollowingTap: {},
            showEventsStat: false,
            showEditButton: true
        )
    }
}

