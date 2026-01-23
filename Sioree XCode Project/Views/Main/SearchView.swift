//
//  SearchView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.sioreeLightGrey)
                            
                            TextField("Search events, hosts, talent...", text: $viewModel.searchQuery)
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeWhite)
                                .focused($isSearchFocused)
                                .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                                    viewModel.search(newValue)
                                }
                            
                            if !viewModel.searchQuery.isEmpty {
                                Button(action: {
                                    viewModel.searchQuery = ""
                                    viewModel.clearResults()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.sioreeLightGrey)
                                }
                            }
                        }
                        .padding(Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.medium)
                    }
                    .padding(Theme.Spacing.m)
                    
                    // Category Filter
                    if !viewModel.searchQuery.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.s) {
                                ForEach(SearchCategory.allCases, id: \.self) { category in
                                    FilterChip(
                                        title: category.rawValue,
                                        isSelected: viewModel.selectedCategory == category
                                    ) {
                                        viewModel.selectedCategory = category
                                        viewModel.search(viewModel.searchQuery)
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                    
                    // Results
                    if viewModel.isLoading {
                        LoadingView()
                    } else if viewModel.searchQuery.isEmpty {
                        // Show recent/trending searches
                        searchSuggestions
                    } else {
                        searchResults
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var searchSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                if !viewModel.trendingSearches.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text("Trending")
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        ForEach(viewModel.trendingSearches, id: \.self) { search in
                            Button(action: {
                                viewModel.searchQuery = search
                                viewModel.search(search)
                            }) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(Color.sioreeWarmGlow)
                                    Text(search)
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeWhite)
                                    Spacer()
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                }
                
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text("Recent")
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        ForEach(viewModel.recentSearches, id: \.self) { search in
                            Button(action: {
                                viewModel.searchQuery = search
                                viewModel.search(search)
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(Color.sioreeLightGrey)
                                    Text(search)
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeWhite)
                                    Spacer()
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.m)
        }
    }
    
    private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                if !viewModel.events.isEmpty {
                    sectionHeader("Events")
                    ForEach(viewModel.events) { event in
                        EventCard(
                            event: event,
                            onTap: {},
                            onLike: {},
                            onSave: {}
                        )
                    }
                }
                
                if !viewModel.hosts.isEmpty {
                    sectionHeader("Hosts")
                    ForEach(viewModel.hosts) { host in
                        // Host card view
                        Text(host.name)
                            .padding()
                    }
                }
                
                if !viewModel.talent.isEmpty {
                    sectionHeader("Talent")
                    ForEach(viewModel.talent) { talent in
                        // Talent card view
                        Text(talent.name)
                            .padding()
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.m)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.sioreeH4)
            .foregroundColor(Color.sioreeWhite)
            .padding(.horizontal, Theme.Spacing.m)
    }
}

#Preview {
    SearchView()
}

