//
//  InboxProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct InboxProfileView: View {
    let userId: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedConversation: Conversation?
    @State private var selectedEventForPhotos: Event?
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    private var isCurrentUser: Bool {
        authViewModel.currentUser?.id == userId
    }
    
    private var pastEvents: [Event] {
        viewModel.events.filter { event in
            event.date < Date() || event.status == .completed
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                            InstagramStyleProfileHeader(
                                user: user,
                                postsCount: pastEvents.count,
                                followerCount: viewModel.followerCount,
                                followingCount: viewModel.followingCount,
                                onEditProfile: {},
                                onFollowersTap: {},
                                onFollowingTap: {},
                                showEventsStat: false,
                                showEditButton: false
                            )
                            .padding(.top, 8)
                            
                            if !isCurrentUser {
                                HStack(spacing: Theme.Spacing.m) {
                                    Button(action: {
                                        viewModel.toggleFollow()
                                    }) {
                                        Text(viewModel.isFollowing ? "Following" : "Follow")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.sioreeWhite)
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
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.top, 12)
                            }
                            
                            pastEventsSection
                        }
                        .padding(.bottom, Theme.Spacing.l)
                    }
                }
            }
            .navigationTitle(viewModel.user?.name ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
            .fullScreenCover(item: $selectedEventForPhotos) { event in
                if isCurrentUser || (viewModel.user?.userType == .partier) {
                    EventStoryViewer(event: event, viewUserId: isCurrentUser ? nil : userId)
                        .environmentObject(authViewModel)
                } else {
                    EventPhotosViewer(event: event, viewUserId: userId)
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
            }
            .onChange(of: viewModel.user?.id) { _ in
                if let user = viewModel.user, user.userType == .partier {
                    loadAttendedEvents()
                }
            }
        }
    }
    
    private var pastEventsSection: some View {
        Group {
            if pastEvents.isEmpty {
                VStack(spacing: Theme.Spacing.l) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
                    VStack(spacing: Theme.Spacing.s) {
                        Text("No past events yet")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)
                        Text("Past events will appear here")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 240)
                .padding(.vertical, Theme.Spacing.xl)
                .padding(.horizontal, Theme.Spacing.l)
            } else {
                let columns = Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.m), count: 3)
                
                LazyVGrid(columns: columns, spacing: Theme.Spacing.l) {
                    ForEach(Array(pastEvents.prefix(9)), id: \.id) { event in
                        VStack(spacing: Theme.Spacing.xs) {
                            EventHighlightCircle(event: event)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        selectedEventForPhotos = event
                                    }
                                }
                            
                            Text(event.title)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.sioreeWhite)
                                .lineLimit(1)
                                .frame(maxWidth: 100)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.m)
            }
        }
    }
    
    private func startConversation() {
        MessagingService.shared.getOrCreateConversation(with: userId)
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
    
    private func loadAttendedEvents() {
        networkService.fetchAttendedEvents(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { events in
                    viewModel.events = events
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    InboxProfileView(userId: "1")
        .environmentObject(AuthViewModel())
}
