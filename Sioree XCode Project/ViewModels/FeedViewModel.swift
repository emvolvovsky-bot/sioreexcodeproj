//
//  FeedViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

enum FeedFilter: String, CaseIterable {
    case following = "Following"
    case nearby = "Nearby"
    case trending = "Trending"
    case all = "All"
}

class FeedViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: FeedFilter = .all
    @Published var hasMoreContent = true
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    
    init() {
        loadFeed()
    }
    
    func loadFeed() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        networkService.fetchFeed(filter: selectedFilter, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if self?.currentPage == 1 {
                        self?.events = response.events
                        self?.posts = response.posts
                    } else {
                        self?.events.append(contentsOf: response.events)
                        self?.posts.append(contentsOf: response.posts)
                    }
                    self?.hasMoreContent = !response.events.isEmpty || !response.posts.isEmpty
                    self?.currentPage += 1
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshFeed() {
        currentPage = 1
        loadFeed()
    }
    
    func loadMoreContent() {
        if hasMoreContent && !isLoading {
            loadFeed()
        }
    }
    
    func toggleLikeEvent(_ event: Event) {
        // Optimistic update
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isLiked.toggle()
            events[index].likes += events[index].isLiked ? 1 : -1
        }
        
        networkService.toggleEventLike(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert optimistic update
                        if let index = self?.events.firstIndex(where: { $0.id == event.id }) {
                            self?.events[index].isLiked.toggle()
                            self?.events[index].likes += self?.events[index].isLiked ?? false ? -1 : 1
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func toggleSaveEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isSaved.toggle()
        }
        
        networkService.toggleEventSave(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        if let index = self?.events.firstIndex(where: { $0.id == event.id }) {
                            self?.events[index].isSaved.toggle()
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

