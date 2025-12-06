//
//  TalentProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct TalentProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @StateObject private var earningsViewModel = TalentEarningsViewModel.shared
    @State private var showRoleSelection = false
    @State private var showSettings = false
    
    private var currentUser: User? {
        authViewModel.currentUser
    }
    
    private var isTalentUser: Bool {
        currentUser?.userType == .talent
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
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.Spacing.xl) {
                                // Profile Card - Same as Host
                                if let user = currentUser {
                                    VStack(spacing: Theme.Spacing.m) {
                                        Text(user.name ?? user.username)
                                            .font(.sioreeH1)
                                            .foregroundColor(Color.sioreeWhite)
                                        
                                        if let bio = user.bio, !bio.isEmpty {
                                            Text(bio)
                                                .font(.sioreeBody)
                                                .foregroundColor(Color.sioreeLightGrey)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, Theme.Spacing.m)
                                        }
                                        
                                        HStack(spacing: Theme.Spacing.l) {
                                            VStack {
                                                Text("\(user.followerCount)")
                                                    .font(.sioreeH3)
                                                    .foregroundColor(Color.sioreeWhite)
                                                Text("Followers")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeLightGrey)
                                            }
                                            
                                            VStack {
                                                Text("\(user.eventCount)")
                                                    .font(.sioreeH3)
                                                    .foregroundColor(Color.sioreeWhite)
                                                Text("Gigs")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeLightGrey)
                                            }
                                            
                                            // Earnings This Month (Only visible to talent)
                                            if isTalentUser {
                                                VStack {
                                                    Text("$\(earningsViewModel.earningsThisMonth)")
                                                        .font(.sioreeH3)
                                                        .foregroundColor(Color.sioreeWarmGlow)
                                                    Text("Earnings")
                                                        .font(.sioreeCaption)
                                                        .foregroundColor(Color.sioreeLightGrey)
                                                }
                                            } else {
                                                VStack {
                                                    Text(user.email)
                                                        .font(.sioreeBodySmall)
                                                        .foregroundColor(Color.sioreeLightGrey)
                                                    Text("Email")
                                                        .font(.sioreeCaption)
                                                        .foregroundColor(Color.sioreeLightGrey)
                                                }
                                            }
                                        }
                                        
                                        // Earnings Breakdown (Only visible to talent)
                                        if isTalentUser {
                                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                                Text("Earnings Breakdown")
                                                    .font(.sioreeH4)
                                                    .foregroundColor(Color.sioreeWhite)
                                                    .padding(.top, Theme.Spacing.m)
                                                
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text("This Month")
                                                            .font(.sioreeBodySmall)
                                                            .foregroundColor(Color.sioreeLightGrey)
                                                        Text("$\(earningsViewModel.earningsThisMonth)")
                                                            .font(.sioreeH4)
                                                            .foregroundColor(Color.sioreeWarmGlow)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    VStack(alignment: .trailing) {
                                                        Text("Total")
                                                            .font(.sioreeBodySmall)
                                                            .foregroundColor(Color.sioreeLightGrey)
                                                        Text("$\(earningsViewModel.totalEarnings)")
                                                            .font(.sioreeH4)
                                                            .foregroundColor(Color.sioreeIcyBlue)
                                                    }
                                                }
                                            }
                                            .padding(Theme.Spacing.m)
                                            .background(Color.sioreeIcyBlue.opacity(0.1))
                                            .cornerRadius(Theme.CornerRadius.medium)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(Theme.Spacing.l)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                                    )
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                                
                                // Role Switch Button
                                Button(action: {
                                    showRoleSelection = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 16))
                                        Text("Feeling different?")
                                            .font(.sioreeBody)
                                    }
                                    .foregroundColor(Color.sioreeIcyBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
        }
    }
}

#Preview {
    TalentProfileView()
        .environmentObject(AuthViewModel())
}

