//
//  TalentProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

class TalentProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var events: [Event] = []
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var followerCount: Int = 0
    @Published var followingCount: Int = 0

    private let networkService = NetworkService()
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    private weak var authViewModel: AuthViewModel?

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    func loadProfile() {
        isLoading = true
        errorMessage = nil

        let authService = AuthService()
        authService.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                    self?.followerCount = user.followerCount
                    self?.followingCount = user.followingCount
                    self?.loadUserContent()
                }
            )
            .store(in: &cancellables)
    }

    func loadUserContent() {
        guard let userId = StorageService.shared.getUserId() else { return }

        // Load talent's completed events (events they've worked at)
        networkService.fetchTalentCompletedEvents(talentUserId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] events in
                    self?.events = events
                }
            )
            .store(in: &cancellables)
    }
}

struct TalentProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TalentProfileViewModel()
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var selectedEventForPhotos: Event? = nil
    @State private var selectedEventForPost: Event?
    
    private var currentUser: User? {
        authViewModel.currentUser
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.sioreeBlack,
                Color.sioreeBlack.opacity(0.98),
                Color.sioreeCharcoal.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var mainContent: some View {
        Group {
            if currentUser == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let user = currentUser {
                userProfileContent(user: user)
            }
        }
    }

    private func userProfileContent(user: User) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader(user: user)
                eventsSection
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func profileHeader(user: User) -> some View {
        InstagramStyleProfileHeader(
            user: user,
            postsCount: viewModel.events.count,
            followerCount: viewModel.followerCount,
            followingCount: viewModel.followingCount,
            onEditProfile: {
                showEditProfile = true
            },
            onFollowersTap: {
                showFollowersList = true
            },
            onFollowingTap: {
                showFollowingList = true
            },
            showEventsStat: false,
            showEditButton: true
        )
        .padding(.top, 8)
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            eventsSectionHeader
            eventsContent
        }
    }

    private var eventsSectionHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Event History")
                    .font(.sioreeH2)
                    .foregroundColor(Color.sioreeWhite)
                Spacer()
                if viewModel.events.count > 6 {
                    NavigationLink(destination: TalentEventsWorkedView()) {
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

    private var eventsContent: some View {
        Group {
            if viewModel.events.isEmpty {
                emptyEventsView
            } else {
                eventsGridView
            }
        }
    }

    private var emptyEventsView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
            VStack(spacing: Theme.Spacing.s) {
                Text("No events worked at yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Your completed events and clips will appear here")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var eventsGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.m),
                GridItem(.flexible(), spacing: Theme.Spacing.m)
            ],
            spacing: Theme.Spacing.m
        ) {
            ForEach(Array(viewModel.events.prefix(6)), id: \.id) { event in
                EventCardGridItem(event: event)
                    .onTapGesture {
                        selectedEventForPhotos = event
                    }
                    .contextMenu {
                        Button(action: {
                            selectedEventForPost = event
                        }) {
                            Label("Add Photos", systemImage: "photo.fill")
                        }
                    }
            }
        }
        .padding(.all, Theme.Spacing.m)
    }


    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                mainContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let user = currentUser {
                        Text(user.username)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.sioreeWhite)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditView(user: currentUser)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showFollowersList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .followers, userType: .partier)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .following, userType: .partier)
                }
            }
            .sheet(item: $selectedEventForPhotos) { event in
                EventPhotosViewer(event: event)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedEventForPost) { event in
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadProfile()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadProfile()
            }
        }
    }

}

#Preview {
    TalentProfileView()
        .environmentObject(AuthViewModel())
}


