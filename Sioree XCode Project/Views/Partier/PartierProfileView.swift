//
//  PartierProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PartierProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @State private var showRoleSelection = false
    @State private var showSettings = false
    
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
                                                Text("\(user.followingCount)")
                                                    .font(.sioreeH3)
                                                    .foregroundColor(Color.sioreeWhite)
                                                Text("Following")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeLightGrey)
                                            }
                                            
                                            VStack {
                                                Text("\(user.eventCount)")
                                                    .font(.sioreeH3)
                                                    .foregroundColor(Color.sioreeWhite)
                                                Text("Events Attended")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeLightGrey)
                                            }
                                            
                                            VStack {
                                                Text("@\(user.username)")
                                                    .font(.sioreeBodySmall)
                                                    .foregroundColor(Color.sioreeLightGrey)
                                                Text("Username")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeLightGrey)
                                            }
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

