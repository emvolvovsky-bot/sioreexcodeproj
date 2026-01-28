//
//  HostTalentRequestsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

enum TalentRequestTab: String, CaseIterable {
    case pending = "Pending"
    case accepted = "Accepted"
    case all = "All"
}

struct HostTalentRequestsView: View {
    @StateObject private var viewModel = TalentRequestsViewModel()
    @State private var selectedTab: TalentRequestTab = .pending
    @State private var selectedConversation: Conversation?
    @State private var showCreateConversation = false
    @State private var selectedTalentIdForComposer: String? = nil
    @State private var selectedTalentNameForComposer: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow

                VStack(spacing: 0) {
                    // Custom Segmented Control
                    customSegmentedControl
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.s)

                    // Content
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.sioreeIcyBlue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredRequests.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(filteredRequests) { request in
                                    TalentRequestListItem(request: request) {
                                        // Start conversation with talent
                                        startConversation(with: request.talentId, talentName: request.talentName ?? "Talent")
                                    }
                                    .padding(.horizontal, Theme.Spacing.l)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
            .sheet(isPresented: $showCreateConversation) {
                if let uid = selectedTalentIdForComposer, let name = selectedTalentNameForComposer {
                    CreateConversationView(userId: uid, userName: name)
                } else {
                    // Fallback empty view
                    EmptyView()
                }
            }
            .onAppear {
                viewModel.loadTalentRequests()
            }
            .onChange(of: selectedTab) { _ in
                // Refresh data when tab changes
                viewModel.loadTalentRequests()
            }
        }
    }

    private var filteredRequests: [TalentRequest] {
        switch selectedTab {
        case .pending:
            return viewModel.requests.filter { $0.status == .pending }
        case .accepted:
            return viewModel.requests.filter { $0.status == .accepted }
        case .all:
            return viewModel.requests
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))

            VStack(spacing: Theme.Spacing.s) {
                Text(emptyStateTitle)
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)

                Text(emptyStateMessage)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var emptyStateTitle: String {
        switch selectedTab {
        case .pending:
            return "No pending requests"
        case .accepted:
            return "No accepted requests"
        case .all:
            return "No talent requests yet"
        }
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .pending:
            return "Talent requests you send will appear here while waiting for responses."
        case .accepted:
            return "Accepted talent requests will appear here once talent confirms."
        case .all:
            return "Start by requesting talent for your events from the event creation flow."
        }
    }

    private func startConversation(with talentId: String, talentName: String) {
        selectedTalentIdForComposer = talentId
        selectedTalentNameForComposer = talentName
        showCreateConversation = true
    }
    
    private var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeBlack,
                    Color.sioreeBlack.opacity(0.98),
                    Color.sioreeCharcoal.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -120, y: -320)
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: 160, y: 220)
        }
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: Theme.Spacing.xs) {
            segmentButton(title: "Pending", isSelected: selectedTab == .pending) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .pending
                }
            }
            
            segmentButton(title: "Accepted", isSelected: selectedTab == .accepted) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .accepted
                }
            }
            
            segmentButton(title: "All", isSelected: selectedTab == .all) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .all
                }
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sioreeBody)
                .fontWeight(.semibold)
                .foregroundColor(.sioreeWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Group {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.sioreeIcyBlue.opacity(0.35), radius: 12, x: 0, y: 6)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

struct TalentRequestListItem: View {
    let request: TalentRequest
    let onMessage: () -> Void
    @State private var navigateToProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // Header with talent info and status
            HStack(spacing: Theme.Spacing.m) {
                // Talent Avatar - Clickable to navigate to profile
                Button(action: {
                    navigateToProfile = true
                }) {
                    ZStack {
                        if let avatar = request.talentAvatar,
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
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(request.talentName ?? "Unknown Talent")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)

                        if let category = request.talentCategory {
                            Text(category.rawValue)
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeIcyBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.sioreeIcyBlue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    if let eventTitle = request.eventTitle {
                        Text("For: \(eventTitle)")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }

                    Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey.opacity(0.7))
                }

                Spacer()

                // Status Badge
                VStack(alignment: .trailing, spacing: 4) {
                    statusBadge

                    // Message Button
                    Button(action: onMessage) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.sioreeIcyBlue)
                            .padding(8)
                            .background(Color.sioreeIcyBlue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }

            // Request Message
            if !request.message.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Your message:")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey.opacity(0.7))

                    Text(request.message)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(Theme.Spacing.m)
                .background(Color.sioreeCharcoal.opacity(0.3))
                .cornerRadius(Theme.CornerRadius.medium)
            }

            // Proposed Rate
            if let rate = request.proposedRate {
                HStack {
                    Text("Proposed rate:")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey.opacity(0.7))

                    Text("$\(Int(rate))/hour")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.2))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(statusBorderColor, lineWidth: 1)
        )
        .background(
            NavigationLink(destination: UserProfileView(userId: request.talentId), isActive: $navigateToProfile) {
                EmptyView()
            }
            .opacity(0)
        )
    }

    private var statusBadge: some View {
        Text(request.status.rawValue.capitalized)
            .font(.sioreeCaption)
            .foregroundColor(statusTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusBackgroundColor)
            .cornerRadius(12)
    }

    private var statusTextColor: Color {
        switch request.status {
        case .pending:
            return .sioreeWhite
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .withdrawn:
            return .sioreeLightGrey
        }
    }

    private var statusBackgroundColor: Color {
        switch request.status {
        case .pending:
            return .sioreeIcyBlue.opacity(0.8)
        case .accepted:
            return .green.opacity(0.2)
        case .rejected:
            return .red.opacity(0.2)
        case .withdrawn:
            return Color.sioreeLightGrey.opacity(0.2)
        }
    }

    private var statusBorderColor: Color {
        switch request.status {
        case .pending:
            return .sioreeIcyBlue.opacity(0.5)
        case .accepted:
            return .green.opacity(0.5)
        case .rejected:
            return .red.opacity(0.3)
        case .withdrawn:
            return Color.sioreeLightGrey.opacity(0.3)
        }
    }
}

class TalentRequestsViewModel: ObservableObject {
    @Published var requests: [TalentRequest] = []
    @Published var isLoading = false
    private let networkService = NetworkService()
    var cancellables = Set<AnyCancellable>()

    func loadTalentRequests() {
        isLoading = true

        // For now, we'll use sample data since we don't have the backend endpoint
        // In a real implementation, this would call the API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Sample data - replace with actual API call when backend is ready
            self.requests = self.createSampleRequests()
            self.isLoading = false
        }

        // Uncomment when backend is ready:
        // networkService.fetchTalentRequests(for: "currentHostId") // Need to get from auth
        //     .receive(on: DispatchQueue.main)
        //     .sink(
        //         receiveCompletion: { completion in
        //             self.isLoading = false
        //             if case .failure(let error) = completion {
        //                 print("Failed to load talent requests: \(error)")
        //             }
        //         },
        //         receiveValue: { requests in
        //             self.requests = requests
        //         }
        //     )
        //     .store(in: &cancellables)
    }

    private func createSampleRequests() -> [TalentRequest] {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        // Create requests with talent information populated
        var requests = [
            TalentRequest(
                id: "req1",
                hostId: "currentUserId",
                talentId: "talent1",
                eventId: "event1",
                eventTitle: "Summer Music Festival",
                message: "Hi! I'm looking for a DJ for my upcoming summer festival. Your profile caught my eye and I think you'd be perfect for the vibe we're going for.",
                proposedRate: 250.0,
                status: .pending,
                createdAt: now,
                updatedAt: now
            ),
            TalentRequest(
                id: "req2",
                hostId: "currentUserId",
                talentId: "talent2",
                eventId: "event2",
                eventTitle: "Corporate Networking Event",
                message: "Hello! We need experienced bartenders for our corporate event. Looking for someone professional and reliable.",
                proposedRate: 180.0,
                status: .accepted,
                createdAt: yesterday,
                updatedAt: now
            ),
            TalentRequest(
                id: "req3",
                hostId: "currentUserId",
                talentId: "talent3",
                eventId: nil,
                eventTitle: nil,
                message: "Hi there! I saw your portfolio and would love to discuss potential collaboration opportunities.",
                proposedRate: nil,
                status: .pending,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
                updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: now)!
            )
        ]

        // Set the optional talent properties (normally this would come from backend joins)
        requests[0].talentName = "DJ Alex Rivera"
        requests[0].talentAvatar = "https://example.com/avatar1.jpg"
        requests[0].talentCategory = .dj

        requests[1].talentName = "Sarah Martinez"
        requests[1].talentAvatar = "https://example.com/avatar2.jpg"
        requests[1].talentCategory = .bartender

        requests[2].talentName = "Mike Chen"
        requests[2].talentAvatar = "https://example.com/avatar3.jpg"
        requests[2].talentCategory = .photographer

        return requests
    }
}

#Preview {
    HostTalentRequestsView()
}
