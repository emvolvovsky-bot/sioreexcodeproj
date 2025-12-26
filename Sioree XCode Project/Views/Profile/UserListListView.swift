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
    @Environment(\.dismiss) var dismiss
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
    init(userId: String, listType: UserListType, userType: UserType? = nil) {
        self.userId = userId
        self.listType = listType
        self.userType = userType
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
                
                if isLoading {
                    LoadingView()
                } else if users.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: listType == .followers ? "person.2.slash" : "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                        Text(listType == .followers ? "No followers yet" : "Not following anyone")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(users) { user in
                                NavigationLink(destination: UserProfileView(userId: user.id)) {
                                    UserListRow(user: user)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            Text("\(users.count) \(listType == .followers ? "Followers" : "Following")")
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .id(UUID()) // Force refresh when users change
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(listType == .followers ? "Followers" : "Following")
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
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        isLoading = true
        
        // Always fetch full lists so counts match the displayed totals
        let publisher: AnyPublisher<[User], Error> = listType == .followers
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
                    users = Array(uniqueUsers.values)
                    isLoading = false
                }
            )
            .store(in: &cancellables)
    }
}

struct UserListRow: View {
    let user: User
    
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
        }
        .padding(.vertical, Theme.Spacing.xs)
        .listRowBackground(Color.sioreeLightGrey.opacity(0.1))
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

#Preview {
    UserListListView(userId: "1", listType: .followers)
}

