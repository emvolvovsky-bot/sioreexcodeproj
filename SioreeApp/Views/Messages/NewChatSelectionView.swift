//
//  NewChatSelectionView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct NewChatSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let onSelectUser: (String, String) -> Void
    let onSelectGroupChat: () -> Void
    
    @State private var users: [User] = []
    @State private var searchQuery: String = ""
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    
    var filteredUsers: [User] {
        if searchQuery.isEmpty {
            return users.prefix(20).map { $0 } // Limit initial display
        }
        return users.filter { user in
            user.id != authViewModel.currentUser?.id &&
            (user.name.localizedCaseInsensitiveContains(searchQuery) ||
             user.username.localizedCaseInsensitiveContains(searchQuery))
        }
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
                
                VStack(spacing: 0) {
                    // Header buttons - Direct Message or Group Chat
                    HStack(spacing: Theme.Spacing.m) {
                        // Direct Message Button
                        Button(action: {
                            // Focus on user selection
                        }) {
                            HStack(spacing: Theme.Spacing.s) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Direct Message")
                                    .font(.sioreeBody)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.sioreeWhite)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .fill(Color.sioreeIcyBlue.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.5), lineWidth: 1.5)
                                    )
                            )
                        }
                        
                        // Group Chat Button
                        Button(action: {
                            onSelectGroupChat()
                        }) {
                            HStack(spacing: Theme.Spacing.s) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Group Chat")
                                    .font(.sioreeBody)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.sioreeIcyBlue)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .fill(Color.sioreeIcyBlue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.m)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        TextField("Search users...", text: $searchQuery)
                            .foregroundColor(.sioreeWhite)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(Theme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(Color.sioreeLightGrey.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.m)
                    
                    // Users List
                    if isLoading && users.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                        Spacer()
                    } else if filteredUsers.isEmpty {
                        Spacer()
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: searchQuery.isEmpty ? "person.3.fill" : "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                            
                            Text(searchQuery.isEmpty ? "No users found" : "No results")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            if !searchQuery.isEmpty {
                                Text("Try a different search term")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeLightGrey)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.s) {
                                ForEach(filteredUsers) { user in
                                    Button(action: {
                                        let userName = user.name
                                        onSelectUser(user.id, userName)
                                    }) {
                                        HStack(spacing: Theme.Spacing.m) {
                                            // Avatar
                                            AvatarView(imageURL: user.avatar, size: .medium)
                                            
                                            // User Info
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(user.name)
                                                    .font(.sioreeBody)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.sioreeWhite)
                                                
                                                Text("@\(user.username)")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                        }
                                        .padding(.horizontal, Theme.Spacing.l)
                                        .padding(.vertical, Theme.Spacing.m)
                                        .background(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                .fill(Color.sioreeLightGrey.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                        .stroke(Color.sioreeIcyBlue.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                        .padding(.horizontal, Theme.Spacing.l)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
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
        networkService.fetchAllUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load users: \(error)")
                    }
                },
                receiveValue: { [self] fetchedUsers in
                    // Filter out current user
                    users = fetchedUsers.filter { $0.id != authViewModel.currentUser?.id }
                    isLoading = false
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    NewChatSelectionView(
        onSelectUser: { userId, userName in
            print("Selected user: \(userName) (\(userId))")
        },
        onSelectGroupChat: {
            print("Create group chat")
        }
    )
    .environmentObject(AuthViewModel())
}

