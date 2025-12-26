//
//  EventAttendeesView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct Attendee: Identifiable, Codable {
    let id: String
    let name: String
    let username: String
    let avatar: String?
    let isVerified: Bool
    var isFollowing: Bool? // nil = not checked, true = following, false = not following
    var isFollowedBy: Bool? // nil = not checked, true = they follow you, false = they don't follow you
}

struct EventAttendeesView: View {
    let eventId: String
    let eventName: String
    @State private var selectedAttendee: Attendee?
    @State private var attendees: [Attendee] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
    init(eventId: String, eventName: String) {
        self.eventId = eventId
        self.eventName = eventName
    }
    
    var body: some View {
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
            } else if attendees.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    Text("No attendees yet")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(attendees) { attendee in
                            NavigationLink(destination: UserProfileView(userId: attendee.id)) {
                                AttendeeRow(attendee: attendee) {
                                    selectedAttendee = attendee
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text("\(attendees.count) People Going")
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Attendees")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadAttendees()
        }
        .sheet(item: $selectedAttendee) { attendee in
            AttendeeMessageView(attendee: attendee)
        }
        .environmentObject(authViewModel)
    }
    
    private func loadAttendees() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchEventAttendees(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        print("❌ Failed to load attendees: \(error)")
                    }
                },
                receiveValue: { fetchedAttendees in
                    attendees = fetchedAttendees
                    // Check follow status for each attendee
                    checkFollowStatuses()
                    isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    private func checkFollowStatuses() {
        guard authViewModel.currentUser?.id != nil else { return }
        
        networkService.fetchMyFollowingIds()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { followingIds in
                    for index in attendees.indices {
                        attendees[index].isFollowing = followingIds.contains(attendees[index].id)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

struct AttendeeRow: View {
    let attendee: Attendee
    let onMessageTap: () -> Void
    
    var followStatusText: String? {
        if let isFollowing = attendee.isFollowing {
            if isFollowing {
                return "Following"
            } else if let isFollowedBy = attendee.isFollowedBy, isFollowedBy {
                return "Follows you"
            } else {
                return "Follow"
            }
        }
        return nil
    }
    
    var followStatusColor: Color {
        if let isFollowing = attendee.isFollowing {
            if isFollowing {
                return .sioreeIcyBlue
            } else if let isFollowedBy = attendee.isFollowedBy, isFollowedBy {
                return .sioreeWarmGlow
            }
        }
        return .sioreeLightGrey
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Avatar
            AvatarView(
                imageURL: attendee.avatar,
                size: .medium,
                showBorder: attendee.isVerified
            )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(attendee.name)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                    
                    if attendee.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
                
                HStack(spacing: Theme.Spacing.xs) {
                    Text("@\(attendee.username)")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                    
                    if let statusText = followStatusText {
                        Text("• \(statusText)")
                            .font(.sioreeCaption)
                            .foregroundColor(followStatusColor)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onMessageTap) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.sioreeIcyBlue)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .listRowBackground(Color.sioreeLightGrey.opacity(0.1))
    }
}

#Preview {
    NavigationStack {
        EventAttendeesView(eventId: "e1", eventName: "Halloween Party")
    }
}

