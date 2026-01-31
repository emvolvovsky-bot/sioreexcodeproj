//
//  UserListListView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

enum UserListType {
    case followers
    case following
}

struct UserListListView: View {
    let userId: String
    let listType: UserListType
    let userType: UserType? // Current user's type to filter followers/following
    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var selectedTab: UserListType = .followers
    @State private var searchText: String = ""
    @State private var selectedConversation: Conversation? = nil
    @State private var isShowingConversation = false
    @StateObject private var messagingService = MessagingService.shared
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
    init(userId: String, listType: UserListType, userType: UserType? = nil) {
        self.userId = userId
        self.listType = listType
        self.userType = userType
        _selectedTab = State(initialValue: listType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tabs
                    HStack {
                        Button(action: { selectedTab = .followers }) {
                            VStack(spacing: 6) {
                                Text("Followers")
                                    .font(.sioreeH3)
                                    .foregroundColor(selectedTab == .followers ? .sioreeWhite : .sioreeLightGrey)
                                Rectangle()
                                    .fill(selectedTab == .followers ? Color.sioreeIcyBlue : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Button(action: { selectedTab = .following }) {
                            VStack(spacing: 6) {
                                Text("Following")
                                    .font(.sioreeH3)
                                    .foregroundColor(selectedTab == .following ? .sioreeWhite : .sioreeLightGrey)
                                Rectangle()
                                    .fill(selectedTab == .following ? Color.sioreeIcyBlue : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        TextField("Search", text: $searchText)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.none)
                    }
                    .padding(10)
                    .background(Color.sioreeLightGrey.opacity(0.06))
                    .cornerRadius(10)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.s)

                    // Content
                    if isLoading {
                        Spacer()
                        LoadingView()
                        Spacer()
                    } else {
                        List {
                        ForEach(filteredUsers(), id: \.id) { user in
                                HStack {
                                    NavigationLink(destination: InboxProfileView(userId: user.id)) {
                                        UserListLabel(user: user)
                                            .fixedSize()
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Spacer()

                                    Button(action: {
                                        // Open or create a conversation then navigate into it
                                        messagingService.getOrCreateConversation(with: user.id)
                                            .receive(on: DispatchQueue.main)
                                            .sink(receiveCompletion: { _ in }, receiveValue: { conv in
                                                selectedConversation = conv
                                                isShowingConversation = true
                                            })
                                            .store(in: &cancellables)
                                    }) {
                                        Text("Message")
                                            .font(.system(size: 14, weight: .semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.sioreeIcyBlue)
                                            .foregroundColor(.sioreeBlack)
                                            .cornerRadius(12)
                                    }
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(authViewModel.currentUser?.username ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.sioreeWhite)
                    }
                }
            }
            .onAppear {
                // Ensure selected tab matches initial prop
                selectedTab = listType
                loadUsers(forceFetch: false)
            }
            .onChange(of: selectedTab) { _ in
                loadUsers(forceFetch: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FollowStatusChanged"))) { _ in
                // When follow status changes elsewhere, refresh from server
                loadUsers(forceFetch: true)
            }
            // Navigate to conversation when created/fetched
            NavigationLink(
                destination:
                    selectedConversation.map { AnyView(RealMessageView(conversation: $0)) } ?? AnyView(EmptyView()),
                isActive: $isShowingConversation
            ) {
                EmptyView()
            }
        }
    }
    
    private func loadUsers(forceFetch: Bool = false) {
        isLoading = true

        // Try local cache first unless forced to fetch
        if !forceFetch {
            let cached = StorageService.shared.getUserList(forUserId: userId, listType: selectedTab)
            if !cached.isEmpty {
                users = cached
                isLoading = false
                return
            }
        }

        // Fetch from network
        let publisher: AnyPublisher<[User], Error> = selectedTab == .followers
            ? networkService.fetchFollowers(userId: userId, userType: nil)
            : networkService.fetchFollowing(userId: userId, userType: nil)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load \(listType == .followers ? "followers" : "following"): \(error)")
                    }
                },
                receiveValue: { [self] fetchedUsers in
                    // Remove duplicates based on user ID to prevent double counting
                    var uniqueUsers: [String: User] = [:]
                    for user in fetchedUsers {
                        uniqueUsers[user.id] = user
                    }
                    let list = Array(uniqueUsers.values)
                    users = list
                    isLoading = false
                    // Cache locally
                    StorageService.shared.saveUserList(list, forUserId: userId, listType: selectedTab)
                }
            )
            .store(in: &cancellables)
    }

    private func filteredUsers() -> [User] {
        let lower = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return users.sorted { $0.name < $1.name } }
        return users.filter { user in
            user.name.lowercased().contains(lower) || user.username.lowercased().contains(lower)
        }
        .sorted { $0.name < $1.name }
    }
}

struct UserListRow: View {
    let user: User
    var onMessage: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Avatar
            AvatarView(
                imageURL: user.avatar,
                size: .medium,
                showBorder: user.verified
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(user.name)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)

                    if user.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }

                Text("@\(user.username)")
                    .font(.sioreeCaption)
                    .foregroundColor(.sioreeLightGrey)
            }

            Spacer()

            // Message button
            Button(action: {
                onMessage?()
            }) {
                Text("Message")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.sioreeIcyBlue)
                    .foregroundColor(.sioreeBlack)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct UserEventsListView: View {
    let userId: String
    let userType: UserType?
    @State private var events: [Event] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
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
                
                if isLoading {
                    LoadingView()
                } else if events.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                        Text(emptyStateTitle)
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(events) { event in
                                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                    EventListRow(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            Text("\(events.count) \(eventsSectionTitle)")
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onAppear {
                loadEvents()
            }
        }
    }
    
    private func loadEvents() {
        isLoading = true
        
        // Partier: attended, Host: hosted, Talent: worked at (completed gigs), fallback: hosted
        let publisher: AnyPublisher<[Event], Error>
        if userType == .partier {
            publisher = networkService.fetchAttendedEvents(userId: userId)
        } else if userType == .host {
            publisher = networkService.fetchUserEvents(userId: userId)
        } else if userType == .talent {
            publisher = networkService.fetchTalentCompletedEvents(talentUserId: userId)
        } else {
            publisher = networkService.fetchUserEvents(userId: userId)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load events: \(error)")
                    }
                },
                receiveValue: { fetchedEvents in
                    events = fetchedEvents
                    isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    private var navigationTitle: String {
        if userType == .partier { return "Events Attended" }
        if userType == .host { return "Events Hosted" }
        if userType == .talent { return "Events Worked At" }
        return "Events Hosted"
    }
    
    private var eventsSectionTitle: String {
        if userType == .partier { return "Events Attended" }
        if userType == .host { return "Events Hosted" }
        if userType == .talent { return "Events Worked At" }
        return "Events Hosted"
    }
    
    private var emptyStateTitle: String {
        if userType == .partier { return "No events attended yet" }
        if userType == .host { return "No events hosted yet" }
        if userType == .talent { return "No events worked at yet" }
        return "No events hosted yet"
    }
}

struct EventListRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.title)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                    .lineLimit(2)
                
                Text(event.date.formattedEventDate())
                    .font(.sioreeCaption)
                    .foregroundColor(.sioreeLightGrey)
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .listRowBackground(Color.sioreeLightGrey.opacity(0.1))
    }
}

// Lightweight label used inside NavigationLink so the Message button is separately tappable
struct UserListLabel: View {
    let user: User

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            AvatarView(
                imageURL: user.avatar,
                size: .medium,
                showBorder: user.verified
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(user.name)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)

                    if user.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }

                Text("@\(user.username)")
                    .font(.sioreeCaption)
                    .foregroundColor(.sioreeLightGrey)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    UserListListView(userId: "1", listType: .followers)
}

