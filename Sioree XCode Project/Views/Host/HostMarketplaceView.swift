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
    @State private var searchText: String = ""
    @State private var searchWorkItem: DispatchWorkItem?
    
    // Convert Talent to TalentListing for display
    private func toListing(_ talent: Talent) -> TalentListing {
        TalentListing(
            id: talent.userId, // Use userId for profile navigation
            name: talent.name,
            roleText: talent.category.rawValue,
            rateText: "$\(Int(talent.priceRange.min))/hour",
            location: talent.location ?? "Location TBD",
            rating: talent.rating,
            imageName: talent.avatar ?? "person.circle.fill"
        )
    }
    
    private var filteredTalent: [TalentListing] {
        let filteredTalents: [Talent] = viewModel.talent.filter { talent in
            switch selectedFilter {
            case .all:
                return true
            case .djs:
                return talent.category == .dj
            case .bartenders:
                return talent.category == .bartender
            case .security:
                return talent.category == .security
            case .photoVideo:
                return talent.category == .photographer || talent.category == .videographer
            }
        }
        return filteredTalents.map { toListing($0) }
    }
    
    private var featuredTalent: [TalentListing] {
        Array(filteredTalent.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.sioreeBlack,
                        Color.sioreeBlack.opacity(0.92),
                        Color.sioreeCharcoal.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        searchAndFilters
                        
                        if !featuredTalent.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                sectionHeader(title: "Spotlight talent", subtitle: "Best fit based on your recent bookings")
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Spacing.m) {
                                        ForEach(featuredTalent, id: \.id) { talent in
                                            NavigationLink(destination: TalentDetailView(talent: talent)) {
                                                SpotlightTalentCard(talent: talent)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.xs)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            sectionHeader(
                                title: "All talent",
                                subtitle: "\(filteredTalent.count) available"
                            )
                            
                            if viewModel.isLoading {
                                LoadingView()
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            } else if filteredTalent.isEmpty {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                    Text("No talent found for this filter")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                .frame(maxWidth: .infinity, minHeight: 220)
                            } else {
                                LazyVStack(spacing: Theme.Spacing.m) {
                                    ForEach(filteredTalent) { talent in
                                        NavigationLink(destination: TalentDetailView(talent: talent)) {
                                            MarketplaceTalentCard(talent: talent)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.l)
                }
                .refreshable {
                    viewModel.loadTalent()
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                searchText = viewModel.searchQuery
                if viewModel.talent.isEmpty {
                    viewModel.loadTalent()
                }
            }
        }
    }
    
    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.sioreeLightGrey)
                
                TextField("Search roles, names, vibes", text: $searchText)
                    .foregroundColor(.sioreeWhite)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { newValue in
                        debounceSearch(newValue)
                    }
                    .onSubmit {
                        viewModel.search(searchText)
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.search("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(Color.sioreeLightGrey.opacity(0.12))
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(TalentFilter.allCases, id: \.self) { filter in
                        MarketplaceFilterPill(
                            title: filter.rawValue,
                            icon: filterIcon(filter),
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xs)
            }
        }
    }
    
    private func debounceSearch(_ text: String) {
        searchWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            viewModel.search(text)
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }
    
    private func sectionHeader(title: String, subtitle: String? = nil) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.sioreeH4)
                    .foregroundColor(.sioreeWhite)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
            }
            Spacer()
        }
    }
    
    private func filterIcon(_ filter: TalentFilter) -> String {
        switch filter {
        case .all:
            return "sparkles"
        case .djs:
            return "music.note"
        case .bartenders:
            return "wineglass"
        case .security:
            return "shield.lefthalf.filled"
        case .photoVideo:
            return "camera.aperture"
        }
    }
}

private struct MarketplaceFilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.sioreeBodySmall)
            .foregroundColor(isSelected ? Color.sioreeBlack : Color.sioreeWhite)
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(isSelected ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.14))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.sioreeIcyBlue.opacity(isSelected ? 0.4 : 0.2), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.large)
        }
    }
}

private struct SpotlightTalentCard: View {
    let talent: TalentListing
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.sioreeIcyBlue.opacity(0.25),
                                Color.sioreeLightGrey.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 140)
                    .overlay(
                        Group {
                            if talent.imageName.hasPrefix("http") {
                                AsyncImage(url: URL(string: talent.imageName)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.sioreeLightGrey.opacity(0.1)
                                }
                            } else {
                                Image(systemName: talent.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.4))
                                    .padding(Theme.Spacing.l)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                    )
                
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text(String(format: "%.1f", talent.rating))
                        .font(.sioreeCaption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.sioreeBlack)
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.vertical, 6)
                .background(Color.sioreeWhite)
                .cornerRadius(Theme.CornerRadius.medium)
                .offset(x: -Theme.Spacing.m, y: Theme.Spacing.m)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(talent.name)
                    .font(.sioreeBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.sioreeWhite)
                    .lineLimit(1)
                
                Text(talent.roleText)
                    .font(.sioreeCaption)
                    .foregroundColor(.sioreeLightGrey)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(talent.location)
                    Spacer()
                    Text(talent.rateText)
                        .fontWeight(.semibold)
                        .foregroundColor(.sioreeIcyBlue)
                }
                .font(.sioreeCaption)
                .foregroundColor(.sioreeLightGrey)
            }
        }
        .frame(width: 220)
    }
}

private struct MarketplaceTalentCard: View {
    let talent: TalentListing
    
    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            avatar
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(talent.name)
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                    Spacer()
                    Text(talent.rateText)
                        .font(.sioreeBodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.sioreeIcyBlue)
                }
                
                Text(talent.roleText)
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
                
                HStack(spacing: Theme.Spacing.s) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(talent.location)
                    }
                    
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "star.fill")
                        Text(String(format: "%.1f", talent.rating))
                    }
                }
                .font(.sioreeCaption)
                .foregroundColor(.sioreeLightGrey)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Color.sioreeIcyBlue.opacity(0.16), lineWidth: 1)
        )
    }
    
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color.sioreeLightGrey.opacity(0.18))
                .frame(width: 64, height: 64)
            
            if talent.imageName.hasPrefix("http") {
                AsyncImage(url: URL(string: talent.imageName)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .foregroundColor(.sioreeLightGrey)
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
            } else {
                Image(systemName: talent.imageName)
                    .font(.system(size: 28))
                    .foregroundColor(.sioreeIcyBlue)
            }
        }
    }
}

#Preview {
    HostMarketplaceView()
}

