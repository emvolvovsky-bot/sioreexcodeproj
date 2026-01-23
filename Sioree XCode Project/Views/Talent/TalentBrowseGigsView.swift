//
//  TalentBrowseGigsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentBrowseGigsView: View {
    @StateObject private var viewModel = TalentBrowseGigsViewModel()
    @State private var selectedFilter: String = "All"
    @State private var searchText: String = ""
    @State private var searchWorkItem: DispatchWorkItem?
    @State private var selectedEvent: Event?
    @State private var showEventDetail = false
    @Environment(\.dismiss) var dismiss

    private var availableFilters: [String] {
        ["All", "DJ", "Bartender", "Photographer", "Videographer", "Dancer", "Security", "Staff", "Performer"]
    }

    private var filteredEvents: [Event] {
        var events = viewModel.events

        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            events = events.filter { event in
                event.title.lowercased().contains(searchLower) ||
                event.description.lowercased().contains(searchLower) ||
                event.hostName.lowercased().contains(searchLower) ||
                event.location.lowercased().contains(searchLower)
            }
        }

        // Filter by selected category
        if selectedFilter != "All" {
            events = events.filter { event in
                if !event.lookingForRoles.isEmpty {
                    let selectedCategory = selectedFilter.lowercased()
                    return event.lookingForRoles.contains { role in
                        role.lowercased().contains(selectedCategory) ||
                        selectedCategory.contains(role.lowercased())
                    }
                }
                return false
            }
        }

        return events
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
                                Text("Browse Gigs")
                                    .font(.sioreeH2)
                                    .foregroundColor(.white)

                                Text("Events looking for your talent")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            }

                            Spacer()

                            // Placeholder for symmetry
                            Color.clear.frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.m)

                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                .font(.system(size: 16))

                            TextField("Search events...", text: $searchText)
                                .font(.sioreeBody)
                                .foregroundColor(.white)
                                .tint(.sioreeWarning)
                                .onChange(of: searchText) { newValue in
                                    searchWorkItem?.cancel()
                                    let workItem = DispatchWorkItem {
                                        // Debounced search
                                    }
                                    searchWorkItem = workItem
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
                                }

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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, Theme.Spacing.m)

                        // Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.s) {
                                ForEach(availableFilters, id: \.self) { filter in
                                    FilterPill(
                                        title: filter,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                    .padding(.top, Theme.Spacing.l)
                    .background(Color.sioreeBlack.opacity(0.8))

                    // Events List
                    ScrollView {
                        if viewModel.isLoading {
                            VStack(spacing: Theme.Spacing.m) {
                                ForEach(0..<3, id: \.self) { _ in
                                    EventCardSkeleton()
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        } else if filteredEvents.isEmpty {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))

                                Text("No events found")
                                    .font(.sioreeH4)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                Text("Try adjusting your search or check back later")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.l)
                        } else {
                            LazyVStack(spacing: Theme.Spacing.s) {
                                ForEach(filteredEvents) { event in
                                    TalentGigEventCard(event: event) {
                                        selectedEvent = event
                                        showEventDetail = true
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
            .sheet(isPresented: $showEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(eventId: event.id, isTalentMapMode: true)
                }
            }
            .onAppear {
                viewModel.fetchEvents()
            }
        }
    }
}

struct TalentGigEventCard: View {
    let event: Event
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // Event Image
                ZStack {
                    if let imageUrl = event.images.first,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.sioreeCharcoal.opacity(0.3)
                        }
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Color.sioreeCharcoal.opacity(0.3)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                }

                // Event Details
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(event.title)
                        .font(.sioreeH4)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            .font(.system(size: 12))

                        Text(event.hostName)
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                    }

                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "calendar")
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            .font(.system(size: 12))

                        Text(event.date.formattedEventDate())
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                        Text("•")
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                        Image(systemName: "mappin")
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            .font(.system(size: 12))

                        Text(event.location)
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            .lineLimit(1)
                    }

                    // Looking for talent
                    if let lookingFor = event.lookingForSummary {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "person.3.sequence.fill")
                                .foregroundColor(.sioreeIcyBlue)
                                .font(.system(size: 12))

                            Text("Looking for \(lookingFor)")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeIcyBlue)
                                .lineLimit(1)
                        }
                    }
                }

                // Apply Button
                HStack {
                    Spacer()

                    Text("Apply")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeBlack)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Color.sioreeWarning)
                        .clipShape(Capsule())
                }
            }
            .padding(Theme.Spacing.m)
            .background(Color.sioreeCharcoal.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // Image placeholder
            Color.sioreeCharcoal.opacity(0.3)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Text placeholders
            Color.sioreeCharcoal.opacity(0.3)
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Color.sioreeCharcoal.opacity(0.3)
                .frame(width: 150, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Color.sioreeCharcoal.opacity(0.3)
                .frame(width: 200, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            // Button placeholder
            HStack {
                Spacer()
                Color.sioreeCharcoal.opacity(0.3)
                    .frame(width: 60, height: 32)
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

class TalentBrowseGigsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()

    func fetchEvents() {
        isLoading = true
        errorMessage = nil

        // Fetch events that are looking for talent
        let publisher = networkService.fetchEventsLookingForTalent(talentType: "")
            .receive(on: DispatchQueue.main)

        let cancellable = publisher.sink(
            receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    print("❌ Failed to load events: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] (events: [Event]) in
                guard let self = self else { return }
                // Filter to only show published events
                let publishedEvents = events.filter { event in
                    event.status == .published
                }
                self.events = publishedEvents
                print("✅ Loaded \(publishedEvents.count) events looking for talent")
            }
        )

        cancellable.store(in: &cancellables)
    }
}
