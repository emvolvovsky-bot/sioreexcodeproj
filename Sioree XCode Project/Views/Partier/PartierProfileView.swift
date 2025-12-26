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
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @StateObject private var viewModel = ProfileViewModel(useAttendedEvents: true)
    @State private var showRoleSelection = false
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var selectedEventForPost: Event?
    
    private var currentUser: User? {
        authViewModel.currentUser
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
                                
                                // Events attended list with add-photos
                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                    Text("Events Attended")
                                        .font(.sioreeH3)
                                        .foregroundColor(.sioreeWhite)
                                        .padding(.horizontal, Theme.Spacing.m)
                                    
                                    if viewModel.events.isEmpty {
                                        Text("RSVP or attend events to share photos.")
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeLightGrey)
                                            .padding(.horizontal, Theme.Spacing.m)
                                            .padding(.bottom, Theme.Spacing.m)
                                    } else {
                                        VStack(spacing: Theme.Spacing.m) {
                                            ForEach(viewModel.events) { event in
                                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(event.title)
                                                                .font(.sioreeH4)
                                                                .foregroundColor(.sioreeWhite)
                                                                .lineLimit(2)
                                                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                                                .font(.sioreeBodySmall)
                                                                .foregroundColor(.sioreeLightGrey)
                                                        }
                                                        Spacer()
                                                    }
                                                    
                                                    HStack(spacing: Theme.Spacing.s) {
                                                        Button(action: {
                                                            selectedEventForPost = event
                                                        }) {
                                                            Label("Add photos", systemImage: "camera.fill")
                                                                .font(.sioreeBodySmall)
                                                                .foregroundColor(.sioreeWhite)
                                                                .padding(.horizontal, Theme.Spacing.m)
                                                                .padding(.vertical, Theme.Spacing.s)
                                                                .background(Color.sioreeIcyBlue)
                                                                .cornerRadius(Theme.CornerRadius.medium)
                                                        }
                                                        
                                                        Spacer()
                                                    }
                                                }
                                                .padding(Theme.Spacing.m)
                                                .background(Color.sioreeLightGrey.opacity(0.08))
                                                .cornerRadius(Theme.CornerRadius.medium)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                        .stroke(Color.sioreeIcyBlue.opacity(0.25), lineWidth: 1)
                                                )
                                            }
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .padding(.bottom, Theme.Spacing.m)
                                    }
                                }
                                .padding(.top, Theme.Spacing.m)
                                
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
                    UserListListView(userId: userId, listType: .followers, userType: .partier)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .following, userType: .partier)
                }
            }
            .sheet(item: $selectedEventForPost) { event in
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.loadUserContent()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.loadUserContent()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { notification in
                // Refresh posts when a new post is created
                viewModel.loadUserContent()
            }
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

