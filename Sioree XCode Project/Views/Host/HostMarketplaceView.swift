//
//  HostMarketplaceView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

enum TalentFilter: String, CaseIterable {
    case all = "All"
    case djs = "DJs"
    case bartenders = "Bartenders"
    case security = "Security"
    case photoVideo = "Photo/Video"
}

struct HostMarketplaceView: View {
    @StateObject private var viewModel = TalentViewModel()
    @State private var selectedFilter: TalentFilter = .all
    
    // Convert Talent to TalentListing for display
    private var talentListings: [TalentListing] {
        viewModel.talent.map { talent in
            TalentListing(
                id: talent.userId, // Use userId for profile navigation
                name: talent.name,
                roleText: talent.category.rawValue,
                rateText: "$\(Int(talent.priceRange.min))/hour",
                location: talent.location ?? "Location TBD",
                rating: talent.rating,
                imageName: "person.circle.fill"
            )
        }
    }
    
    var filteredTalent: [TalentListing] {
        if selectedFilter == .all {
            return talentListings
        } else {
            return talentListings.filter { $0.roleText.lowercased().contains(selectedFilter.rawValue.lowercased()) }
        }
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
                
                VStack(spacing: 0) {
                    // Recommended Talent Section (Vertical ScrollView with Square Cards)
                    if !viewModel.isLoading && !talentListings.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Recommended")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: Theme.Spacing.m),
                                    GridItem(.flexible(), spacing: Theme.Spacing.m)
                                ], spacing: Theme.Spacing.m) {
                                    ForEach(Array(talentListings.prefix(6)), id: \.id) { talent in
                                        NavigationLink(destination: TalentDetailView(talent: talent)) {
                                            RecommendedTalentSquareCard(talent: talent)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                            .frame(height: 400) // Fixed height for vertical scroll
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.s) {
                            ForEach(TalentFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    selectedFilter = filter
                                }) {
                                    Text(filter.rawValue)
                                        .font(.sioreeBodySmall)
                                        .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                        .foregroundColor(Color.sioreeWhite)
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .padding(.vertical, Theme.Spacing.s)
                                        .background(selectedFilter == filter ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.2))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                    
                    // Talent List
                    if viewModel.isLoading {
                        LoadingView()
                    } else if filteredTalent.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.sioreeLightGrey.opacity(0.5))
                            Text("No talent available")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(filteredTalent) { talent in
                                    NavigationLink(destination: TalentDetailView(talent: talent)) {
                                        TalentCard(talent: talent) {
                                            // Navigation handled by NavigationLink
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: TalentMapView()) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .onAppear {
                viewModel.loadTalent()
            }
        }
    }
}

// Square Card for Recommended Talent
struct RecommendedTalentSquareCard: View {
    let talent: TalentListing
    
    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            // Square Image/Avatar
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.sioreeLightGrey.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                
                if talent.imageName.hasPrefix("http") {
                    AsyncImage(url: URL(string: talent.imageName)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                } else {
                    Image(systemName: talent.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                }
            }
            
            // Talent Info
            VStack(spacing: Theme.Spacing.xs) {
                Text(talent.name)
                    .font(.sioreeBody)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.sioreeWhite)
                    .lineLimit(1)
                
                Text(talent.roleText)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.sioreeWarmGlow)
                    Text(String(format: "%.1f", talent.rating))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                }
            }
        }
        .padding(Theme.Spacing.s)
        .background(Color.sioreeLightGrey.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HostMarketplaceView()
}

