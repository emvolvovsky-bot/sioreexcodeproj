//
//  TalentProfileHeader.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct TalentProfileHeader: View {
    let user: User
    let followerCount: Int
    let followingCount: Int
    let onEditProfile: () -> Void
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    
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
                
                // Stats in horizontal row on right (Followers, Following)
                HStack(spacing: 0) {
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
            
            // Edit Profile button - Partiful style (more vibrant and rounded)
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

#Preview {
    ZStack {
        Color.sioreeBlack.ignoresSafeArea()
        
        TalentProfileHeader(
            user: User(
                email: "test@example.com",
                username: "testuser",
                name: "Test Talent",
                bio: "Professional DJ with 10+ years of experience",
                userType: .talent,
                location: "New York, NY"
            ),
            followerCount: 1200,
            followingCount: 300,
            onEditProfile: {},
            onFollowersTap: {},
            onFollowingTap: {}
        )
    }
}



