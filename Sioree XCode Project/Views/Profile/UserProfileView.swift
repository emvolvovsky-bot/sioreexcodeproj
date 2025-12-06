//
//  UserProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showMessageView = false
    @State private var selectedConversation: Conversation?
    @State private var cancellables = Set<AnyCancellable>()
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    var isCurrentUser: Bool {
        authViewModel.currentUser?.id == userId
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
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let user = viewModel.user {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            // Profile Header
                            ProfileHeaderView(user: user)
                            
                            // Stats
                            ProfileStatsView(
                                eventsHosted: user.eventCount,
                                eventsAttended: 0,
                                followers: user.followerCount,
                                following: user.followingCount,
                                username: user.username,
                                userType: user.userType,
                                userId: user.id
                            )
                            
                            // Reviews Section (for hosts and talents)
                            if (user.userType == .host || user.userType == .talent) && !isCurrentUser {
                                NavigationLink(destination: ReviewsView(userId: user.id, userName: user.name)) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.sioreeWarmGlow)
                                        Text("View Reviews")
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeIcyBlue)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.sioreeIcyBlue)
                                    }
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                            
                            // Action Buttons
                            if !isCurrentUser {
                                VStack(spacing: Theme.Spacing.m) {
                                    HStack(spacing: Theme.Spacing.m) {
                                        // Follow/Unfollow Button
                                        CustomButton(
                                            title: viewModel.isFollowing ? "Following" : "Follow",
                                            variant: viewModel.isFollowing ? .secondary : .primary,
                                            size: .medium
                                        ) {
                                            viewModel.toggleFollow()
                                        }
                                        
                                        // Message Button
                                        CustomButton(
                                            title: "Message",
                                            variant: .secondary,
                                            size: .medium
                                        ) {
                                            startConversation()
                                        }
                                    }
                                    
                                    // Leave a Review Button (for hosts and talents)
                                    if user.userType == .host || user.userType == .talent {
                                        NavigationLink(destination: ReviewsView(userId: user.id, userName: user.name)) {
                                            HStack {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.sioreeWarmGlow)
                                                Text("Leave a Review")
                                                    .font(.sioreeBody)
                                                    .foregroundColor(.sioreeIcyBlue)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.sioreeIcyBlue)
                                            }
                                            .padding(Theme.Spacing.m)
                                            .background(Color.sioreeWarmGlow.opacity(0.1))
                                            .cornerRadius(Theme.CornerRadius.medium)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                            
                            // Content Tabs
                            Picker("", selection: $viewModel.selectedTab) {
                                ForEach(ProfileViewModel.ProfileTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Theme.Spacing.l)
                            
                            // Content
                            contentView
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle(viewModel.user?.name ?? "Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.selectedTab {
        case .events:
            if viewModel.events.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "calendar")
                        .font(.system(size: 50))
                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    Text("No events yet")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                }
                .padding(.vertical, Theme.Spacing.xl)
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(viewModel.events) { event in
                        NavigationLink(destination: EventDetailView(eventId: event.id)) {
                            AppEventCard(event: event) {
                                // Navigation handled by NavigationLink
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
        case .posts:
            if viewModel.posts.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    Text("No posts yet")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                }
                .padding(.vertical, Theme.Spacing.xl)
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(viewModel.posts) { post in
                        // Post card view
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            if let caption = post.caption {
                                Text(caption)
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                            }
                            if !post.images.isEmpty {
                                Text("\(post.images.count) image(s)")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                            }
                        }
                        .padding()
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
        case .saved:
            if viewModel.savedEvents.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 50))
                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    Text("No saved events")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                }
                .padding(.vertical, Theme.Spacing.xl)
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(viewModel.savedEvents) { event in
                        NavigationLink(destination: EventDetailView(eventId: event.id)) {
                            AppEventCard(event: event) {
                                // Navigation handled by NavigationLink
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
    }
    
    private func startConversation() {
        MessagingService.shared.getOrCreateConversation(with: self.userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to create conversation: \(error)")
                    }
                },
                receiveValue: { conversation in
                    selectedConversation = conversation
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    UserProfileView(userId: "1")
        .environmentObject(AuthViewModel())
}

