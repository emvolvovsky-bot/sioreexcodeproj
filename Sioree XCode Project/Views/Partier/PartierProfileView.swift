//
//  PartierProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct PartierProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(useAttendedEvents: true)
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
                    NavigationLink(destination: EventsAttendedView()) {
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
                Text("No events attended yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Your attended events and photos will appear here")
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
            .toolbarBackground(Color.sioreeBlack.opacity(0.8), for: .navigationBar)
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
            .fullScreenCover(item: $selectedEventForPhotos) { event in
                EventStoryViewer(event: event)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedEventForPost) { event in
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
            }
        }
    }
}

struct EventCardGridItem: View {
    let event: Event
    
    private var coverImageUrl: String? {
        // Check for stored cover image first (from first photo upload)
        let coverKey = "event_cover_\(event.id)"
        if let storedCover = UserDefaults.standard.string(forKey: coverKey), !storedCover.isEmpty {
            return storedCover
        }
        // Fallback to event's first image
        return event.images.first
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Event image/thumbnail
            ZStack {
                if let imageUrl = coverImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.sioreeCharcoal)
                                .overlay(
                                    Image(systemName: "party.popper.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(Color.sioreeCharcoal)
                                .overlay(
                                    Image(systemName: "party.popper.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.sioreeLightGrey)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.sioreeCharcoal)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.sioreeCharcoal)
                        .overlay(
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                        )
                }
            }
            .frame(height: 180)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Event info overlay
            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                Text(event.title)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeWhite)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.8), radius: 2)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                }
                .shadow(color: Color.black.opacity(0.8), radius: 2)
            }
            .padding(Theme.Spacing.s)
        }
    }
}

struct BadgeRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            Text(text)
                .font(.sioreeBody)
                .foregroundColor(Color.sioreeWhite)
            
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    PartierProfileView()
        .environmentObject(AuthViewModel())
}

