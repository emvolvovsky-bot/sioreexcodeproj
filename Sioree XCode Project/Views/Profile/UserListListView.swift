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
    @State private var users: [User] = []
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
        // TODO: Implement API endpoint to fetch followers/following list
        // For now, use placeholder data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            users = []
            isLoading = false
        }
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
                        Text(userType == .partier ? "No events attended yet" : "No events hosted yet")
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
                            Text("\(events.count) \(userType == .partier ? "Events Attended" : "Events Hosted")")
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(userType == .partier ? "Events Attended" : "Events Hosted")
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
        networkService.fetchUserEvents(userId: userId)
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

