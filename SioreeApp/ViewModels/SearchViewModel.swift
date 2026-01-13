//
//  SearchViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

enum SearchCategory: String, CaseIterable {
    case all = "All"
    case events = "Events"
    case hosts = "Hosts"
    case talent = "Talent"
    case posts = "Posts"
}

class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var events: [Event] = []
    @Published var hosts: [Host] = []
    @Published var talent: [Talent] = []
    @Published var posts: [Post] = []
    @Published var recentSearches: [String] = []
    @Published var trendingSearches: [String] = []
    @Published var selectedCategory: SearchCategory = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceTimer: Timer?
    
    init() {
        loadRecentSearches()
        loadTrendingSearches()
    }
    
    func search(_ query: String) {
        searchQuery = query
        
        // Debounce search
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performSearch()
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            clearResults()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkService.search(query: searchQuery, category: selectedCategory)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] results in
                    self?.events = results.events
                    self?.hosts = results.hosts
                    self?.talent = results.talent
                    self?.posts = results.posts
                    self?.saveRecentSearch(self?.searchQuery ?? "")
                }
            )
            .store(in: &cancellables)
    }
    
    func clearResults() {
        events = []
        hosts = []
        talent = []
        posts = []
    }
    
    private func loadRecentSearches() {
        recentSearches = StorageService.shared.getRecentSearches()
    }
    
    private func loadTrendingSearches() {
        networkService.fetchTrendingSearches()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] searches in
                    self?.trendingSearches = searches
                }
            )
            .store(in: &cancellables)
    }
    
    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        if let index = searches.firstIndex(of: query) {
            searches.remove(at: index)
        }
        searches.insert(query, at: 0)
        searches = Array(searches.prefix(10))
        recentSearches = searches
        StorageService.shared.saveRecentSearches(searches)
    }
}

