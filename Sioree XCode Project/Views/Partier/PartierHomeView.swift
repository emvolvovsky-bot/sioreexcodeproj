//
//  PartierHomeView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PartierHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        if viewModel.isLoading && !viewModel.hasLoaded {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xxl)
                        } else if viewModel.nearbyEvents.isEmpty && viewModel.featuredEvents.isEmpty && viewModel.hasLoaded {
                            // Empty State
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 64))
                                    .foregroundColor(Color.sioreeLightGrey)
                                Text("No events nearby")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                Text("Check back later for new parties")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.xxl)
                        } else {
                            // Featured Events (promoted by brands) - Horizontal Scroll
                            // Always show Featured section if we have events or placeholders
                            if !viewModel.featuredEvents.isEmpty || viewModel.hasLoaded {
                                if viewModel.featuredEvents.isEmpty {
                                    // Show placeholders for Featured
                                    let placeholderFeatured = HomeViewModel().generatePlaceholderFeaturedEvents()
                                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                        HStack {
                                            Text("Featured")
                                                .font(.sioreeH2)
                                                .foregroundColor(Color.sioreeWhite)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: Theme.Spacing.xs) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.sioreeWarmGlow)
                                                Text("Brand Promoted")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: Theme.Spacing.m) {
                                                ForEach(placeholderFeatured) { event in
                                                    AppEventCard(event: event) {}
                                                        .frame(width: 320)
                                                }
                                            }
                                            .padding(.horizontal, Theme.Spacing.m)
                                        }
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                        HStack {
                                            Text("Featured")
                                                .font(.sioreeH2)
                                                .foregroundColor(Color.sioreeWhite)
                                            
                                            Spacer()
                                            
                                            // Badge indicating these are brand promotions
                                            HStack(spacing: Theme.Spacing.xs) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.sioreeWarmGlow)
                                                Text("Brand Promoted")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: Theme.Spacing.m) {
                                                ForEach(viewModel.featuredEvents) { event in
                                                    AppEventCard(event: event) {
                                                        // Navigation handled by AppEventCard's sheet
                                                    }
                                                    .frame(width: 320)
                                                }
                                            }
                                            .padding(.horizontal, Theme.Spacing.m)
                                        }
                                    }
                                }
                            }
                            
                            // Near You - Horizontal Scroll (always show, with placeholders if empty)
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                Text("Near You")
                                    .font(.sioreeH2)
                                    .foregroundColor(Color.sioreeWhite)
                                    .padding(.horizontal, Theme.Spacing.m)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Spacing.m) {
                                        ForEach(viewModel.nearbyEvents.isEmpty ? viewModel.generatePlaceholderNearbyEvents() : viewModel.nearbyEvents) { event in
                                            AppEventCard(event: event) {
                                                // Navigation handled by AppEventCard's sheet
                                            }
                                            .frame(width: 320)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !viewModel.hasLoaded {
                    viewModel.loadEvents()
                }
            }
        }
    }
}

#Preview {
    PartierHomeView()
}


