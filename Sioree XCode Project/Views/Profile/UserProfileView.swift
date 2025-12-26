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
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    private let networkService = NetworkService()
    
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
                        VStack(spacing: 0) {
                            // Instagram-style profile header
                            InstagramStyleProfileHeader(
                                user: user,
                                postsCount: viewModel.posts.count,
                                followerCount: viewModel.followerCount,
                                followingCount: viewModel.followingCount,
                                onEditProfile: {},
                                onFollowersTap: {
                                    showFollowersList = true
                                },
                                onFollowingTap: {
                                    showFollowingList = true
                                },
                                showEventsStat: false,
                                showEditButton: isCurrentUser
                            )
                            .padding(.top, 8)
                            
                            // Action Buttons (if not current user)
                            if !isCurrentUser {
                                HStack(spacing: Theme.Spacing.m) {
                                    // Follow/Unfollow Button
                                    Button(action: {
                                        viewModel.toggleFollow()
                                    }) {
                                        Text(viewModel.isFollowing ? "Following" : "Follow")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(viewModel.isFollowing ? .sioreeWhite : .sioreeWhite)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background {
                                                if viewModel.isFollowing {
                                                    Color.sioreeLightGrey.opacity(0.2)
                                                } else {
                                                    LinearGradient(
                                                        colors: [Color.sioreeIcyBlue.opacity(0.8), Color.sioreeIcyBlue],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                }
                                            }
                                            .cornerRadius(18)
                                    }
                                    
                                    // Message Button
                                    Button(action: {
                                        startConversation()
                                    }) {
                                        Text("Message")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.sioreeWhite)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(Color.sioreeLightGrey.opacity(0.2))
                                            .cornerRadius(18)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }
                            
                            // Posts Grid (Instagram-style)
                            if viewModel.posts.isEmpty {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                    Text("No posts yet")
                                        .font(.sioreeH3)
                                        .foregroundColor(.sioreeWhite)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xxl)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2)
                                ], spacing: 2) {
                                    ForEach(viewModel.posts) { post in
                                        NavigationLink(destination: PostDetailView(post: post)) {
                                            PostGridItem(post: post)
                                        }
                                    }
                                }
                                .padding(.top, Theme.Spacing.m)
                            }
                        }
                        .padding(.bottom, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle(viewModel.user?.name ?? "Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
            .onAppear {
            }
            .onChange(of: viewModel.user?.id) { _ in
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { notification in
                // Refresh posts when a new post is created
                if let postUserId = notification.userInfo?["userId"] as? String,
                   postUserId == userId {
                    viewModel.loadUserContent()
                }
            }
            .sheet(isPresented: $showFollowersList) {
                UserListListView(userId: userId, listType: .followers, userType: getUserTypeFromRole())
            }
            .sheet(isPresented: $showFollowingList) {
                UserListListView(userId: userId, listType: .following, userType: getUserTypeFromRole())
            }
        }
    }
    
    private func getUserTypeFromRole() -> UserType? {
        guard let role = UserRole(rawValue: selectedRoleRaw) else { 
            // If no role selected, try to get from current user
            return authViewModel.currentUser?.userType
        }
        switch role {
        case .partier: return .partier
        case .host: return .host
        case .talent: return .talent
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

