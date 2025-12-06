//
//  UserSearchView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct UserSearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    
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
                    // Search Bar (optional - can filter)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        
                        TextField("Search users...", text: $searchText)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { oldValue, newValue in
                                if newValue.count >= 2 {
                                    searchUsers(query: newValue)
                                } else if newValue.isEmpty {
                                    loadAllUsers()
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                loadAllUsers()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.sioreeLightGrey)
                            }
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(Theme.Spacing.m)
                    
                    // Results - Show all users by default
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if users.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.sioreeLightGrey.opacity(0.5))
                            Text("No users found")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.s) {
                                ForEach(users) { user in
                                    UserSearchRow(user: user)
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("All Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onAppear {
                loadAllUsers()
            }
        }
    }
    
    private func loadAllUsers() {
        isLoading = true
        
        networkService.fetchAllUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Load all users error: \(error)")
                        users = []
                    }
                },
                receiveValue: { fetchedUsers in
                    isLoading = false
                    users = fetchedUsers
                    print("✅ Loaded \(users.count) users")
                }
            )
            .store(in: &cancellables)
    }
    
    private func searchUsers(query: String) {
        guard query.count >= 2 else {
            users = []
            return
        }
        
        isLoading = true
        
        struct SearchResponse: Codable {
            let users: [User]
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        networkService.request("/api/users/search?q=\(encodedQuery)")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Search error: \(error)")
                        users = []
                    }
                },
                receiveValue: { (response: SearchResponse) in
                    isLoading = false
                    users = response.users
                    print("✅ Found \(users.count) users for query: \(query)")
                }
            )
            .store(in: &cancellables)
    }
}

struct UserSearchRow: View {
    let user: User
    @State private var isFollowing = false
    @State private var showMessageView = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.sioreeLightGrey.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                if let avatar = user.avatar, !avatar.isEmpty {
                    AsyncImage(url: URL(string: avatar)) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(user.name ?? user.username)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                    
                    if user.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
                
                Text("@\(user.username)")
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.s) {
                // Message Button
                Button(action: {
                    showMessageView = true
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.sioreeIcyBlue)
                        .frame(width: 36, height: 36)
                        .background(Color.sioreeIcyBlue.opacity(0.1))
                        .cornerRadius(18)
                }
                
                // Follow/Unfollow Button
                Button(action: {
                    toggleFollow()
                }) {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.sioreeBodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(isFollowing ? .sioreeWhite : .sioreeIcyBlue)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(isFollowing ? Color.sioreeIcyBlue : Color.sioreeIcyBlue.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.small)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 2)
        )
        .sheet(isPresented: $showMessageView) {
            // Navigate to message view with this user
            // This will be handled by creating a conversation
            Text("Message view for \(user.name ?? user.username)")
        }
    }
    
    private func toggleFollow() {
        // TODO: Implement follow/unfollow API call
        isFollowing.toggle()
    }
}

#Preview {
    UserSearchView()
}

