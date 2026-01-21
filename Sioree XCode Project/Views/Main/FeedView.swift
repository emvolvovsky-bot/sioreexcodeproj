//
//  FeedView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showMap = false
    
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
                
                if showMap {
                    EventsMapView()
                        .transition(.opacity)
                } else {
                    Group {
                        if viewModel.isLoading && viewModel.events.isEmpty {
                            LoadingView()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: Theme.Spacing.m) {
                                    // Filter Chips
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Theme.Spacing.s) {
                                            ForEach(FeedFilter.allCases, id: \.self) { filter in
                                                FilterChip(
                                                    title: filter.rawValue,
                                                    isSelected: viewModel.selectedFilter == filter
                                                ) {
                                                    viewModel.selectedFilter = filter
                                                    viewModel.refreshFeed()
                                                }
                                            }
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                    }
                                    .padding(.vertical, Theme.Spacing.s)
                                    
                                    // Events with NavigationLink
                                    ForEach(viewModel.events) { event in
                                        NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                            EventCard(
                                                event: event,
                                                onTap: {
                                                    // Navigation handled by NavigationLink
                                                },
                                                onLike: {
                                                    viewModel.toggleLikeEvent(event)
                                                },
                                                onSave: {
                                                    viewModel.toggleSaveEvent(event)
                                                }
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .onAppear {
                                            if event.id == viewModel.events.last?.id {
                                                viewModel.loadMoreContent()
                                            }
                                        }
                                    }
                                    
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .padding()
                                    }
                                }
                                .padding(.vertical, Theme.Spacing.m)
                            }
                            .refreshable {
                                viewModel.refreshFeed()
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Soirée")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMap.toggle()
                        }
                    }) {
                        Image(systemName: showMap ? "list.bullet" : "map.fill")
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showMap)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sioreeBodySmall)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? Color.sioreeWhite : Color.sioreeWhite)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(isSelected ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.2))
                .cornerRadius(Theme.CornerRadius.large)
        }
    }
}

#Preview {
    FeedView()
}
