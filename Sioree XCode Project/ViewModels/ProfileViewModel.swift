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
    @Published var selectedHostTab: HostProfileTab = .upcoming
    @Published var followerCount: Int = 0
    @Published var followingCount: Int = 0

    // Filtered events for host profile tabs
    var hostedEvents: [Event] {
        events.filter { event in
            event.date < Date() || event.status == .completed
        }
    }

    var upcomingEvents: [Event] {
        events.filter { event in
            event.date >= Date() && event.status != .completed
        }.sorted { $0.date < $1.date } // Soonest first
    }

    var filteredEvents: [Event] {
        switch selectedHostTab {
        case .hosted:
            return hostedEvents
        case .upcoming:
            return upcomingEvents
        }
    }

    enum ProfileTab: String, CaseIterable {
        case events = "Events"
        case posts = "Posts"
        case saved = "Saved"
    }

    enum HostProfileTab: String, CaseIterable {
        case upcoming = "Upcoming Events"
        case hosted = "Events Hosted"
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

        // Start polling server for follow counts every 5 minutes
        startFollowCountsPolling()

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

        // Listen for event creation to add event immediately
        NotificationCenter.default.publisher(for: NSNotification.Name("EventCreated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let event = notification.userInfo?["event"] as? Event {
                    print("📡 ProfileViewModel received EventCreated notification: \(event.title)")
                    print("📡 Event hostId: '\(event.hostId)', current userId: \(StorageService.shared.getUserId() ?? "nil")")

                    // Add the event if it's the current user's profile (userId is nil) or if hostId matches
                    let shouldAdd = self?.userId == nil || // Current user's profile
                                    (self?.userId != nil && event.hostId == self?.userId) || // Specific user's profile
                                    (event.hostId == StorageService.shared.getUserId()) // Event belongs to current user

                    if shouldAdd {
                        // Add the event to the beginning of the events array
                        self?.events.insert(event, at: 0)
                        print("✅ Added new event to ProfileViewModel: \(event.title)")
                    } else {
                        print("⚠️ Event not added - doesn't belong to this profile")
                    }
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
                        // Use locally cached counts immediately when available
                        if let uid = self?.user?.id,
                           let cachedFollowers = self?.storageService.getFollowerCount(forUserId: uid) {
                            self?.followerCount = cachedFollowers
                        } else {
                            self?.followerCount = user.followerCount
                        }
                        if let uid = self?.user?.id,
                           let cachedFollowing = self?.storageService.getFollowingCount(forUserId: uid) {
                            self?.followingCount = cachedFollowing
                        } else {
                            self?.followingCount = user.followingCount
                        }
                        // Persist initial counts
                        if let uid = self?.user?.id {
                            self?.storageService.saveFollowerCount(self?.followerCount ?? 0, forUserId: uid)
                            self?.storageService.saveFollowingCount(self?.followingCount ?? 0, forUserId: uid)
                        }
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
                        // Use locally cached counts immediately when available
                        if let uid = self?.user?.id,
                           let cachedFollowers = self?.storageService.getFollowerCount(forUserId: uid) {
                            self?.followerCount = cachedFollowers
                        } else {
                            self?.followerCount = user.followerCount
                        }
                        if let uid = self?.user?.id,
                           let cachedFollowing = self?.storageService.getFollowingCount(forUserId: uid) {
                            self?.followingCount = cachedFollowing
                        } else {
                            self?.followingCount = user.followingCount
                        }
                        // Persist initial counts
                        if let uid = self?.user?.id {
                            self?.storageService.saveFollowerCount(self?.followerCount ?? 0, forUserId: uid)
                            self?.storageService.saveFollowingCount(self?.followingCount ?? 0, forUserId: uid)
                        }
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
        
        // Preload any locally cached events for this user so they appear immediately
        let cached = storageService.getLocalEvents(forUserId: userId)
        if !cached.isEmpty {
            // Merge cached events with in-memory events but keep cached ones at front
            let existingIds = Set(self.events.map { $0.id })
            let newCached = cached.filter { !existingIds.contains($0.id) }
            self.events.insert(contentsOf: newCached, at: 0)
            print("📦 Loaded \(newCached.count) cached local events for user \(userId)")
        }

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
            receiveValue: { [weak self] serverEvents in
                // Merge server events with locally created events that might not be in server response yet
                let serverEventIds = Set(serverEvents.map { $0.id })
                    // Keep any in-memory events that are not present on the server (local-only)
                    let existingLocalEvents = self?.events.filter { !serverEventIds.contains($0.id) } ?? []
                    // Persist server events merged with existing local events (so cache stays current)
                    self?.events = serverEvents + existingLocalEvents
                    if let currentUserId = self?.userId ?? StorageService.shared.getUserId() {
                        // Update local cache for server events so future loads use them
                        StorageService.shared.saveLocalEvents(serverEvents, forUserId: currentUserId)
                    }
                    print("✅ ProfileViewModel loaded \(serverEvents.count) events from server, kept \(existingLocalEvents.count) local events. Total: \(self?.events.count ?? 0)")
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
                        // Update in-memory and local cache
                        let previous = self.followerCount
                        let delta = followerCount - previous
                        if delta != 0 {
                            self.followerCount += delta
                        }
                        self.user?.followerCount = followerCount
                        if let uid = self.user?.id {
                            self.storageService.saveFollowerCount(followerCount, forUserId: uid)
                        }

                        // If this is the current user's profile, update AuthViewModel
                        if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                            self.authViewModel?.currentUser?.followerCount = followerCount
                        }
                    }
                    if let followingCount = response.followingCount {
                        let previous = self.followingCount
                        let delta = followingCount - previous
                        if delta != 0 {
                            self.followingCount += delta
                        }
                        self.user?.followingCount = followingCount
                        if let uid = self.user?.id {
                            self.storageService.saveFollowingCount(followingCount, forUserId: uid)
                        }

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
                    let serverCount = users.count
                    // Only update if changed
                    if self.followerCount != serverCount {
                        self.followerCount = serverCount
                        self.user?.followerCount = serverCount
                        self.storageService.saveFollowerCount(serverCount, forUserId: uid)
                        if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                            self.authViewModel?.currentUser?.followerCount = serverCount
                        }
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
                    let serverCount = users.count
                    if self.followingCount != serverCount {
                        self.followingCount = serverCount
                        self.user?.followingCount = serverCount
                        self.storageService.saveFollowingCount(serverCount, forUserId: uid)
                        if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                            self.authViewModel?.currentUser?.followingCount = serverCount
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func startFollowCountsPolling() {
        // Poll every 5 minutes (300 seconds)
        let targetUserId = userId ?? StorageService.shared.getUserId()
        guard let uid = targetUserId else { return }

        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .flatMap { [weak self] _ -> AnyPublisher<User, Error> in
                guard let self = self else { return Empty<User, Error>().eraseToAnyPublisher() }
                return self.networkService.fetchUserProfile(userId: uid)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] profile in
                guard let self = self else { return }
                // Compare server counts with cached counts and update if changed (increment/decrement as needed)
                let serverFollower = profile.followerCount
                let cachedFollower = self.storageService.getFollowerCount(forUserId: uid) ?? self.followerCount
                if serverFollower != cachedFollower {
                    let delta = serverFollower - cachedFollower
                    self.followerCount += delta
                    self.user?.followerCount = serverFollower
                    self.storageService.saveFollowerCount(serverFollower, forUserId: uid)
                    if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                        self.authViewModel?.currentUser?.followerCount = serverFollower
                    }
                }

                let serverFollowing = profile.followingCount
                let cachedFollowing = self.storageService.getFollowingCount(forUserId: uid) ?? self.followingCount
                if serverFollowing != cachedFollowing {
                    let delta = serverFollowing - cachedFollowing
                    self.followingCount += delta
                    self.user?.followingCount = serverFollowing
                    self.storageService.saveFollowingCount(serverFollowing, forUserId: uid)
                    if self.userId == nil || self.userId == StorageService.shared.getUserId() {
                        self.authViewModel?.currentUser?.followingCount = serverFollowing
                    }
                }
            })
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

