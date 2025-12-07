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
    
    enum ProfileTab: String, CaseIterable {
        case events = "Events"
        case posts = "Posts"
        case saved = "Saved"
    }
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    private let userId: String?
    
    init(userId: String? = nil) {
        self.userId = userId
        loadProfile()
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
                        self?.loadUserContent()
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
                        self?.loadUserContent()
                        self?.checkFollowStatus()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func loadUserContent() {
        guard let userId = userId ?? StorageService.shared.getUserId() else { return }
        
        networkService.fetchUserEvents(userId: userId)
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
        let wasFollowing = isFollowing
        isFollowing.toggle()
        
        networkService.toggleFollow(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert on error
                        self?.isFollowing = wasFollowing
                    } else {
                        // On success, refresh follow status to ensure it persists
                        self?.checkFollowStatus()
                    }
                },
                receiveValue: { [weak self] _ in
                    if let user = self?.user, let isFollowing = self?.isFollowing {
                        self?.user?.followerCount += isFollowing ? 1 : -1
                    }
                    // Refresh follow status to ensure it persists
                    self?.checkFollowStatus()
                }
            )
            .store(in: &cancellables)
    }
    
    func checkFollowStatus() {
        guard let userId = userId else { return }
        
        struct Response: Codable {
            let following: Bool
        }
        
        networkService.request("/api/users/\(userId)/following")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] (response: Response) in
                    self?.isFollowing = response.following
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProfile(name: String?, bio: String?, location: String?) {
        isLoading = true
        
        networkService.updateProfile(name: name, bio: bio, location: location)
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

