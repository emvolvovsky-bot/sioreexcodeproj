//
//  BrandProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BrandProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @State private var showRoleSelection = false
    @State private var showSettings = false
    
    private var currentUser: User? {
        authViewModel.currentUser
    }
    
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
                
                Group {
                    if currentUser == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.Spacing.l) {
                                // Profile Header
                                if let user = currentUser {
                                    ProfileHeaderView(user: user)
                                    
                                    // Stats - Followers, Following, Events, and Username
                                    ProfileStatsView(
                                        eventsHosted: user.eventCount,
                                        eventsAttended: 0,
                                        followers: user.followerCount,
                                        following: user.followingCount,
                                        username: user.username,
                                        userType: user.userType,
                                        userId: user.id
                                    )
                                }
                                
                                // Role Switch Button
                                Button(action: {
                                    showRoleSelection = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 16))
                                        Text("Feeling different?")
                                            .font(.sioreeBody)
                                    }
                                    .foregroundColor(Color.sioreeIcyBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showRoleSelection) {
                RoleSelectionView(selectedRole: Binding(
                    get: { UserRole(rawValue: selectedRoleRaw) },
                    set: { newValue in
                        if let role = newValue {
                            selectedRoleRaw = role.rawValue
                        }
                    }
                ), isChangingRole: true)
            }
        }
    }
}

#Preview {
    BrandProfileView()
        .environmentObject(AuthViewModel())
}

