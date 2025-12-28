//
//  ProfileViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var events: [Event] = []
    @Published var posts: [Post] = []
    @Published var savedEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFollowing = false
    @Published var selectedTab: ProfileTab = .events
    @Published var followerCount: Int = 0
    @Published var followingCount: Int = 0

    enum ProfileTab: String, CaseIterable {
        case events = "Events"
        case posts = "Posts"
        case saved = "Saved"
    }

    private let networkService = NetworkService()
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    private let userId: String?
    private let useAttendedEvents: Bool
    private weak var authViewModel: AuthViewModel?
    
    init(userId: String? = nil, useAttendedEvents: Bool = false) {
        self.userId = userId
        self.useAttendedEvents = useAttendedEvents

        // Use cached follow state immediately so the button reflects prior actions
        if let userId = userId {
            isFollowing = storageService.getFollowingIds().contains(userId)
        }
        loadProfile()

        // Listen for post creation to refresh posts
        NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Refresh posts if this is the current user's profile or viewing their own profile
                if let postUserId = notification.userInfo?["userId"] as? String,
                   let currentUserId = StorageService.shared.getUserId(),
                   postUserId == currentUserId || self?.userId == postUserId {
                    self?.loadUserContent()
                }
            }
            .store(in: &cancellables)
    }

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        // If no userId specified, fetch current user from /api/auth/me
        if userId == nil {
            let authService = AuthService()
            authService.getCurrentUser()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    },
                    receiveValue: { [weak self] user in
                        self?.user = user
                        self?.followerCount = user.followerCount
                        self?.followingCount = user.followingCount
                        self?.loadUserContent()
                        self?.loadFollowCounts()
                    }
                )
                .store(in: &cancellables)
        } else {
            // Fetch specific user profile
            networkService.fetchUserProfile(userId: userId!)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    },
                    receiveValue: { [weak self] user in
                        self?.user = user
                        self?.followerCount = user.followerCount
                        self?.followingCount = user.followingCount
                        self?.loadUserContent()
                        self?.loadFollowCounts()
                        self?.checkFollowStatus()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func loadUserContent() {
        guard let userId = userId ?? StorageService.shared.getUserId() else { return }
        
        let eventsPublisher: AnyPublisher<[Event], Error>
        if useAttendedEvents {
            eventsPublisher = networkService.fetchAttendedEvents(userId: userId)
        } else {
            eventsPublisher = networkService.fetchUserEvents(userId: userId)
        }
        
        eventsPublisher
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { [weak self] events in
                self?.events = events
            }
        )
        .store(in: &cancellables)
        
        networkService.fetchUserPosts(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] posts in
                    self?.posts = posts
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleFollow() {
        guard let userId = user?.id else { return }
        let shouldFollow = !isFollowing
        let action = shouldFollow ? networkService.follow(userId: userId) : networkService.unfollow(userId: userId)
        
        action
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure = completion {
                        // Fall back to cached state so UI stays consistent
                        isFollowing = storageService.getFollowingIds().contains(userId)
                    } else {
                        self.checkFollowStatus()
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self else { return }
                    isFollowing = response.following
                    
                    // Persist the follow choice locally until the user explicitly unfollows
                    if response.following {
                        storageService.addFollowingId(userId)
                    } else {
                        storageService.removeFollowingId(userId)
                    }
                    
                    if let followerCount = response.followerCount {
                        self.followerCount = followerCount
                        self.user?.followerCount = followerCount

                        // If this is the current user's profile, update AuthViewModel
                        if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                            self.authViewModel?.currentUser?.followerCount = followerCount
                        }
                    }
                    if let followingCount = response.followingCount {
                        self.followingCount = followingCount
                        self.user?.followingCount = followingCount

                        // If this is the current user's profile, update AuthViewModel
                        if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                            self.authViewModel?.currentUser?.followingCount = followingCount
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func checkFollowStatus() {
        guard let userId = userId else { return }
        
        // Show cached state immediately
        isFollowing = storageService.getFollowingIds().contains(userId)

        networkService.fetchMyFollowingIds()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] followingIds in
                    self?.isFollowing = followingIds.contains(userId)
                    self?.storageService.saveFollowingIds(followingIds)
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Follow counts
    func loadFollowCounts() {
        let targetUserId = userId ?? StorageService.shared.getUserId()
        guard let uid = targetUserId else { return }

        networkService.fetchFollowers(userId: uid, userType: nil)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }
                    self.followerCount = users.count
                    self.user?.followerCount = users.count

                    // If this is the current user's profile, update AuthViewModel
                    if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                        self.authViewModel?.currentUser?.followerCount = users.count
                    }
                }
            )
            .store(in: &cancellables)

        networkService.fetchFollowing(userId: uid, userType: nil)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }
                    self.followingCount = users.count
                    self.user?.followingCount = users.count

                    // If this is the current user's profile, update AuthViewModel
                    if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                        self.authViewModel?.currentUser?.followingCount = users.count
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProfile(name: String?, username: String?, bio: String?, location: String?) {
        isLoading = true
        
        networkService.updateProfile(name: name, username: username, bio: bio, location: location)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                }
            )
            .store(in: &cancellables)
    }
}

