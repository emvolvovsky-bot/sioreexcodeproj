//
//  UserProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showMessageView = false
    @State private var selectedConversation: Conversation?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var selectedEventForPhotos: Event? = nil
    @State private var selectedEventForDetail: Event? = nil
    @State private var talentEvents: [Event] = []
    private let networkService = NetworkService()
    
    init(userId: String) {
        self.userId = userId
        // Initialize with default settings, will be updated when user data loads
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    var isCurrentUser: Bool {
        authViewModel.currentUser?.id == userId
    }

    var viewedUserRole: UserRole? {
        if let user = viewModel.user {
            switch user.userType {
            case .partier: return .partier
            case .host: return .host
            case .talent: return .talent
            }
        }
        return nil
    }

    private func isEventPast(_ event: Event) -> Bool {
        return event.date < Date() || event.status == .completed
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
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let user = viewModel.user {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Instagram-style profile header
                            InstagramStyleProfileHeader(
                                user: user,
                                postsCount: viewModel.posts.count,
                                followerCount: viewModel.followerCount,
                                followingCount: viewModel.followingCount,
                                onEditProfile: {},
                                onFollowersTap: {
                                    showFollowersList = true
                                },
                                onFollowingTap: {
                                    showFollowingList = true
                                },
                                showEventsStat: false,
                                showEditButton: isCurrentUser
                            )
                            .padding(.top, 8)
                            
                            // Action Buttons (if not current user)
                            if !isCurrentUser {
                                HStack(spacing: Theme.Spacing.m) {
                                    // Follow/Unfollow Button
                                    Button(action: {
                                        viewModel.toggleFollow()
                                    }) {
                                        Text(viewModel.isFollowing ? "Following" : "Follow")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(viewModel.isFollowing ? .sioreeWhite : .sioreeWhite)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background {
                                                if viewModel.isFollowing {
                                                    Color.sioreeLightGrey.opacity(0.2)
                                                } else {
                                                    LinearGradient(
                                                        colors: [Color.sioreeIcyBlue.opacity(0.8), Color.sioreeIcyBlue],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                }
                                            }
                                            .cornerRadius(18)
                                    }
                                    
                                    // Message Button
                                    Button(action: {
                                        startConversation()
                                    }) {
                                        Text("Message")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.sioreeWhite)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(Color.sioreeLightGrey.opacity(0.2))
                                            .cornerRadius(18)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }
                            
                            // Role-specific content
                            if let role = viewedUserRole {
                                switch role {
                                case .partier:
                                    partierContent(user: user)
                                case .host:
                                    hostContent(user: user)
                                    // Posts for hosts
                                    postsSection
                                case .talent:
                                    talentContent(user: user)
                                    // Posts for talents
                                    postsSection
                                }
                            }
                        }
                        .padding(.bottom, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle(viewModel.user?.name ?? "Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
            .onAppear {
            }
            .onChange(of: viewModel.user?.id) { _ in
                // When user data loads, check if we need to reload with correct event type
                if let user = viewModel.user, user.userType == .partier {
                    // For partiers, we want attended events, so reload with useAttendedEvents: true
                    // This is a bit of a hack, but ProfileViewModel doesn't support changing this parameter
                    // We'll need to reload the events manually
                    loadAttendedEvents()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { notification in
                // Refresh posts when a new post is created
                if let postUserId = notification.userInfo?["userId"] as? String,
                   postUserId == userId {
                    viewModel.loadUserContent()
                }
            }
            .sheet(isPresented: $showFollowersList) {
                UserListListView(userId: userId, listType: .followers, userType: getUserTypeFromRole())
            }
            .sheet(isPresented: $showFollowingList) {
                UserListListView(userId: userId, listType: .following, userType: getUserTypeFromRole())
            }
            .sheet(item: $selectedEventForPhotos) { event in
                EventPhotosViewer(event: event, viewUserId: userId)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedEventForDetail) { event in
                EventDetailPlaceholderView(event: event)
            }
        }
    }
    
    private func getUserTypeFromRole() -> UserType? {
        return viewModel.user?.userType ?? authViewModel.currentUser?.userType
    }

    private func partierContent(user: User) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            eventsSectionHeader(title: "Event History", eventCount: viewModel.events.count, seeAllDestination: EventsAttendedView())
            eventsContent(events: viewModel.events, user: user, showPhotos: true)
        }
    }

    private func hostContent(user: User) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tab Picker for Events
            Picker("Event Type", selection: $viewModel.selectedHostTab) {
                ForEach(ProfileViewModel.HostProfileTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.top, Theme.Spacing.m)

            // Events Section
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(viewModel.selectedHostTab.rawValue)
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)
                    .padding(.horizontal, Theme.Spacing.m)

                if viewModel.filteredEvents.isEmpty {
                    Text(viewModel.selectedHostTab == .hosted ?
                         "No past events yet." :
                         "No upcoming events.")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.m)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Theme.Spacing.m),
                            GridItem(.flexible(), spacing: Theme.Spacing.m)
                        ],
                        spacing: Theme.Spacing.m
                    ) {
                        ForEach(viewModel.filteredEvents) { event in
                            HostEventCardGrid(event: event) {
                                if isEventPast(event) {
                                    // Past event - show photo collage
                                    selectedEventForPhotos = event
                                } else {
                                    // Upcoming event - show event detail
                                    selectedEventForDetail = event
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.m)
                }
            }
            .padding(.top, Theme.Spacing.m)

            // Host-specific sections (only show if viewing as host)
            if user.userType == .host {
                // Earnings - only show for current user
                if isCurrentUser {
                    NavigationLink(destination: EarningsView()) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.sioreeIcyBlue)

                            Text("Earnings")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeWhite)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(Color.sioreeLightGrey)
                        }
                        .padding(Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                }

                // Host History - show for all hosts
                NavigationLink(destination: HostHistoryView(hostId: user.id, hostName: user.name ?? user.username)) {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.sioreeIcyBlue)

                        Text("View Video Compilation")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeWhite)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                    .padding(Theme.Spacing.m)
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                    )
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.m)

                // Talent Media - show for all hosts
                NavigationLink(destination: TalentMediaView(hostId: user.id)) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.sioreeIcyBlue)

                        Text("Talent Media")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeWhite)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                    .padding(Theme.Spacing.m)
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.m)
            }
        }
    }

    private func talentContent(user: User) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            eventsSectionHeader(title: "Event History", eventCount: talentEvents.count, seeAllDestination: TalentEventsWorkedView())
            talentEventsContent(user: user)
        }
        .onAppear {
            loadTalentEvents()
        }
    }

    private func eventsSectionHeader(title: String, eventCount: Int, seeAllDestination: some View) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.sioreeH2)
                    .foregroundColor(Color.sioreeWhite)
                Spacer()
                // Only show "See All" link when viewing your own profile
                if isCurrentUser && eventCount > 6 {
                    NavigationLink(destination: seeAllDestination) {
                        Text("See All")
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.m)

            // Subtle divider
            Rectangle()
                .fill(Color.sioreeLightGrey.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, Theme.Spacing.m)
        }
    }

    private func eventsContent(events: [Event], user: User, showPhotos: Bool = false) -> some View {
        Group {
            if events.isEmpty {
                emptyEventsView
            } else {
                eventsGridView(events: events, showPhotos: showPhotos)
            }
        }
    }

    private func talentEventsContent(user: User) -> some View {
        Group {
            if talentEvents.isEmpty {
                emptyTalentEventsView
            } else {
                eventsGridView(events: talentEvents, showPhotos: true)
            }
        }
    }

    private func eventsGridView(events: [Event], showPhotos: Bool) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.m),
                GridItem(.flexible(), spacing: Theme.Spacing.m)
            ],
            spacing: Theme.Spacing.m
        ) {
            ForEach(Array(events.prefix(6)), id: \.id) { event in
                EventCardGridItem(event: event)
                    .onTapGesture {
                        if showPhotos {
                            selectedEventForPhotos = event
                        }
                    }
            }
        }
        .padding(.all, Theme.Spacing.m)
    }

    private var emptyEventsView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
            VStack(spacing: Theme.Spacing.s) {
                Text("No events attended yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Events will appear here")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var emptyTalentEventsView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
            VStack(spacing: Theme.Spacing.s) {
                Text("No events worked at yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Completed events will appear here")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var postsSection: some View {
        Group {
            if viewModel.posts.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    Text("No posts yet")
                        .font(.sioreeH3)
                        .foregroundColor(.sioreeWhite)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxl)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Posts")
                        .font(.sioreeH3)
                        .foregroundColor(.sioreeWhite)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.m)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostGridItem(post: post)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                }
                .padding(.top, Theme.Spacing.m)
            }
        }
    }

    private func loadTalentEvents() {
        networkService.fetchTalentCompletedEvents(talentUserId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { events in
                    self.talentEvents = events
                }
            )
            .store(in: &cancellables)
    }

    private func loadAttendedEvents() {
        networkService.fetchAttendedEvents(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { events in
                    self.viewModel.events = events
                }
            )
            .store(in: &cancellables)
    }
    
    private func startConversation() {
        MessagingService.shared.getOrCreateConversation(with: self.userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to create conversation: \(error)")
                    }
                },
                receiveValue: { conversation in
                    selectedConversation = conversation
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    UserProfileView(userId: "1")
        .environmentObject(AuthViewModel())
}

