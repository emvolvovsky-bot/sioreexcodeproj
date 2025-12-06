//
//  ProfileHeaderView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            AvatarView(
                imageURL: user.avatar,
                size: .large,
                showBorder: user.verified
            )
            
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(user.name)
                        .font(.sioreeH2)
                        .foregroundColor(Color.sioreeWhite)
                    
                    if user.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
                
                Text("@\(user.username)")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeLightGrey)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.xs)
                }
                
                if let location = user.location {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.sioreeCaption)
                        Text(location)
                            .font(.sioreeCaption)
                    }
                    .foregroundColor(Color.sioreeLightGrey)
                    .padding(.top, Theme.Spacing.xs)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.m)
    }
}

#Preview {
    ProfileHeaderView(
        user: User(
            email: "test@example.com",
            username: "testuser",
            name: "Test User",
            bio: "Nightlife enthusiast",
            userType: .partier,
            location: "New Orleans, LA"
        )
    )
}

