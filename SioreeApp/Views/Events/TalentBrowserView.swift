//
//  TalentBrowserView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentBrowserView: View {
    @Environment(\.dismiss) var dismiss
    let event: Event? // Optional - if called from event creation, might not have event yet
    let onTalentRequested: ((Talent) -> Void)? // Callback when talent is requested

    @StateObject private var viewModel = TalentBrowserViewModel()
    @State private var selectedTalent: Talent?
    @State private var showTalentProfile = false
    @State private var selectedCategory: TalentCategory?
    @State private var searchText = ""

    private var filteredTalent: [Talent] {
        var talent = viewModel.talent

        // Filter by search text
        if !searchText.isEmpty {
            talent = talent.filter { t in
                t.name.lowercased().contains(searchText.lowercased()) ||
                t.category.rawValue.lowercased().contains(searchText.lowercased()) ||
                (t.bio?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (t.location?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }

        // Filter by category
        if let category = selectedCategory {
            talent = talent.filter { $0.category == category }
        }

        return talent
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: Theme.Spacing.s) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("Request Talent")
                                    .font(.sioreeH2)
                                    .foregroundColor(.white)

                                if let event = event {
                                    Text("for \(event.title)")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                        .lineLimit(1)
                                } else {
                                    Text("Browse available talent")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                }
                            }

                            Spacer()

                            // Placeholder for symmetry
                            Color.clear.frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.m)

                        // Search and Filter
                        VStack(spacing: Theme.Spacing.s) {
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                    .font(.system(size: 16))

                                TextField("Search talent...", text: $searchText)
                                    .font(.sioreeBody)
                                    .foregroundColor(.white)
                                    .tint(.sioreeIcyBlue)
                                    .textInputAutocapitalization(.never)

                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.s)
                            .background(Color.sioreeCharcoal.opacity(0.3))
                            .cornerRadius(Theme.CornerRadius.medium)
                            .padding(.horizontal, Theme.Spacing.m)

                            // Category Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.s) {
                                    CategoryFilterButton(
                                        title: "All",
                                        isSelected: selectedCategory == nil
                                    ) {
                                        selectedCategory = nil
                                    }

                                    ForEach(TalentCategory.allCases, id: \.self) { category in
                                        CategoryFilterButton(
                                            title: category.rawValue,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.l)
                    .background(Color.sioreeBlack.opacity(0.8))

                    // Talent List
                    ScrollView {
                        if viewModel.isLoading {
                            VStack(spacing: Theme.Spacing.m) {
                                ForEach(0..<5, id: \.self) { _ in
                                    TalentBrowserCardSkeleton()
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        } else if filteredTalent.isEmpty {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))

                                Text("No talent found")
                                    .font(.sioreeH4)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                Text("Try adjusting your search or filters")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.l)
                        } else {
                            LazyVStack(spacing: Theme.Spacing.s) {
                                ForEach(filteredTalent) { talent in
                                    TalentBrowserCard(talent: talent) {
                                        selectedTalent = talent
                                        showTalentProfile = true
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTalentProfile) {
                if let talent = selectedTalent {
                    TalentRequestView(talent: talent, event: event, onTalentRequested: { requestedTalent in
                        onTalentRequested?(requestedTalent)
                        dismiss()
                    })
                }
            }
            .onAppear {
                viewModel.loadTalent()
            }
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sioreeCaption)
                .foregroundColor(isSelected ? .sioreeBlack : .white)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.xs)
                .background(isSelected ? Color.sioreeIcyBlue : Color.sioreeCharcoal.opacity(0.3))
                .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

struct TalentBrowserCard: View {
    let talent: Talent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(spacing: Theme.Spacing.m) {
                    // Talent Avatar
                    ZStack {
                        if let avatar = talent.avatar,
                           let url = URL(string: avatar) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                .frame(width: 50, height: 50)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(talent.name)
                                .font(.sioreeH4)
                                .foregroundColor(.white)

                            if talent.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.system(size: 12))
                            }
                        }

                        Text(talent.category.rawValue)
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.sioreeIcyBlue)
                                .font(.system(size: 12))

                            Text(String(format: "%.1f", talent.rating))
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))

                            Text("(\(talent.reviewCount))")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))

                            if let location = talent.location {
                                Text("•")
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                Text(location)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(Int(talent.priceRange.min))-\(Int(talent.priceRange.max))")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeIcyBlue)

                        Text("/hour")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                    }
                }

                if let bio = talent.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeCharcoal.opacity(0.8))
                        .lineLimit(2)
                }

                // View Profile Button
                HStack {
                    Spacer()
                    Text("View Profile")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeIcyBlue)
                        .padding(.horizontal, Theme.Spacing.s)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Color.sioreeIcyBlue.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.small)
                }
            }
            .padding(Theme.Spacing.m)
            .background(Color.sioreeCharcoal.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TalentBrowserCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.m) {
                Circle()
                    .fill(Color.sioreeCharcoal.opacity(0.3))
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sioreeCharcoal.opacity(0.3))
                        .frame(width: 120, height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sioreeCharcoal.opacity(0.3))
                        .frame(width: 80, height: 12)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sioreeCharcoal.opacity(0.3))
                        .frame(width: 60, height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sioreeCharcoal.opacity(0.3))
                        .frame(width: 40, height: 12)
                }
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.sioreeCharcoal.opacity(0.3))
                .frame(height: 40)
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

class TalentBrowserViewModel: ObservableObject {
    @Published var talent: [Talent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()

    func loadTalent() {
        isLoading = true
        errorMessage = nil

        // Load all talent for browsing
        networkService.fetchTalent(category: nil, searchQuery: nil)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load talent: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] talent in
                    guard let self = self else { return }
                    self.talent = talent
                    print("✅ Loaded \(talent.count) talent profiles")
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    TalentBrowserView(event: nil, onTalentRequested: nil)
}
