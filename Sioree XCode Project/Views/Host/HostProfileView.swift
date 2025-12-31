//
//  HostProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct HostProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showRoleSelection = false
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var selectedEventForPost: Event?
    @State private var selectedEventForPhotos: Event? = nil
    @State private var selectedEventForDetail: Event? = nil
    
    private var currentUser: User? {
        authViewModel.currentUser
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
                
                Group {
                    if currentUser == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let user = currentUser {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Instagram-style profile header
                                InstagramStyleProfileHeader(
                                    user: user,
                                    postsCount: viewModel.posts.count,
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
                                             "No past events yet. Host your first event!" :
                                             "No upcoming events. Create your next event!")
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
                                
                                // Earnings (only for hosts)
                                if user.userType == .host {
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
                                    
                                    // Host History (only for hosts)
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

                                    // Talent Media (only for hosts)
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
                            .padding(.bottom, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let user = currentUser {
                        Button(action: { showRoleSelection = true }) {
                            HStack(spacing: 6) {
                                Text(user.username)
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.sioreeWhite)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.sioreeWhite)
                            .font(.system(size: 20, weight: .medium))
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
            .sheet(isPresented: $showRoleSelection) {
                RoleSelectionView(selectedRole: Binding(
                    get: { UserRole(rawValue: selectedRoleRaw) },
                    set: { newValue in
                        if let role = newValue {
                            selectedRoleRaw = role.rawValue
                        }
                    }
                ), isChangingRole: true)
            }
            .sheet(isPresented: $showFollowersList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .followers, userType: .host)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .following, userType: .host)
                }
            }
            .sheet(item: $selectedEventForPost) { event in
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedEventForPhotos) { event in
                EventPhotosViewer(event: event)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedEventForDetail) { event in
                EventDetailPlaceholderView(event: event)
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { notification in
                // Refresh posts when a new post is created
                viewModel.loadUserContent()
            }
        }
    }
}

#Preview {
    HostProfileView()
        .environmentObject(AuthViewModel())
}
