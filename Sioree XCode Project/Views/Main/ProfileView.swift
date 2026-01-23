//
//  ProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGlow
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let user = viewModel.user {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            // Profile Header
                            ProfileHeaderView(user: user)
                            
                            // Stats - Followers, Following, Events, and Username
                            ProfileStatsView(
                                followers: viewModel.followerCount,
                                following: viewModel.followingCount,
                                username: user.username,
                                userId: user.id
                            )
                            
                            // Badges
                            if !user.badges.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                    Text("Badges")
                                        .font(.sioreeH4)
                                        .foregroundColor(Color.sioreeWhite)
                                        .padding(.horizontal, Theme.Spacing.m)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Theme.Spacing.s) {
                                            ForEach(user.badges) { badge in
                                                BadgeView(badge: badge)
                                            }
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                    }
                                }
                            }
                            
                            // Tabs
                            Picker("", selection: $viewModel.selectedTab) {
                                ForEach(ProfileViewModel.ProfileTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Theme.Spacing.m)
                            
                            // Content
                            contentView
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Profile") {
                            showEditProfile = true
                        }
                        Button("Settings") {
                            showSettings = true
                        }
                        Divider()
                        Button("Logout", role: .destructive) {
                            authViewModel.logout()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color.sioreeWhite)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditView(user: viewModel.user)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: authViewModel.currentUser?.avatar) { oldValue, newValue in
                // Refresh profile when avatar changes
                if newValue != oldValue {
                    viewModel.setAuthViewModel(authViewModel)
                    viewModel.loadProfile()
                }
            }
            .onAppear {
                // Refresh profile when view appears
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadProfile()
            }
        }
    }
    
    private var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeBlack,
                    Color.sioreeBlack.opacity(0.98),
                    Color.sioreeCharcoal.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -120, y: -320)
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: 160, y: 220)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.selectedTab {
        case .events:
            // For talent users, show Upcoming/Completed tabs
            if viewModel.user?.userType == .talent {
                TalentEventsView(events: viewModel.events)
            } else {
                // For other users, show regular events list
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(viewModel.events) { event in
                        EventCard(
                            event: event,
                            onTap: {},
                            onLike: {},
                            onSave: {}
                        )
                    }
                }
            }
        case .posts:
            LazyVStack(spacing: Theme.Spacing.m) {
                ForEach(viewModel.posts) { post in
                    // Post card view
                    Text(post.caption ?? "Post")
                        .padding()
                }
            }
        case .saved:
            LazyVStack(spacing: Theme.Spacing.m) {
                ForEach(viewModel.savedEvents) { event in
                    EventCard(
                        event: event,
                        onTap: {},
                        onLike: {},
                        onSave: {}
                    )
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

