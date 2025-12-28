//
//  TalentProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showRoleSelection = false
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var showClips = false
    @State private var showPortfolio = false
    @State private var showMarketplaceRegistration = false
    @State private var clips: [TalentClip] = []
    @State private var portfolioItems: [PortfolioItem] = []
    private let networkService = NetworkService()
    
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
                                // Talent-specific profile header (no Posts, no Username in stats)
                                TalentProfileHeader(
                                    user: user,
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
                                    }
                                )
                                .padding(.top, 8)
                                
                                // Marketplace Registration Section
                                Button(action: {
                                    showMarketplaceRegistration = true
                                }) {
                                    HStack {
                                        Image(systemName: "storefront.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.sioreeIcyBlue)
                                        
                                        Text("Join Marketplace")
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
                                
                                // Talent-specific sections: Clips and Portfolio (instead of Posts)
                                // Clips Section
                                Button(action: {
                                    showClips = true
                                }) {
                                    HStack {
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.sioreeIcyBlue)
                                        
                                        Text("Clips")
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
                                
                                // Portfolio Section
                                Button(action: {
                                    showPortfolio = true
                                }) {
                                    HStack {
                                        Image(systemName: "briefcase.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.sioreeIcyBlue)
                                        
                                        Text("Portfolio")
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
                                
                                // Earnings (only for talent)
                                NavigationLink(destination: TalentEarningsView()) {
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
                    UserListListView(userId: userId, listType: .followers, userType: .talent)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .following, userType: .talent)
                }
            }
            .sheet(isPresented: $showClips) {
                ClipsView(clips: $clips)
            }
            .sheet(isPresented: $showPortfolio) {
                TalentPortfolioView(portfolioItems: $portfolioItems, userId: currentUser?.id ?? "")
            }
            .sheet(isPresented: $showMarketplaceRegistration) {
                TalentMarketplaceRegistrationView()
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
                loadClips()
                loadPortfolio()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
                loadClips()
                loadPortfolio()
            }
        }
    }
    
    private func loadClips() {
        // TODO: Load clips from backend
        // For now, clips array is empty
    }
    
    private func loadPortfolio() {
        // TODO: Load portfolio from backend
        // For now, portfolioItems array is empty
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    TalentProfileView()
        .environmentObject(AuthViewModel())
}

