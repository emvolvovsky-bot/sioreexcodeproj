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
    @State private var followingIds: Set<String> = []
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
                                    NavigationLink(destination: UserProfileView(userId: user.id)) {
                                        UserSearchRow(
                                            user: user,
                                            isInitiallyFollowing: followingIds.contains(user.id)
                                        ) { isNowFollowing in
                                            if isNowFollowing {
                                                followingIds.insert(user.id)
                                            } else {
                                                followingIds.remove(user.id)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
                loadFollowingIds()
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
    
    private func loadFollowingIds() {
        // Apply cached follow state immediately so the UI reflects prior actions
        followingIds = Set(StorageService.shared.getFollowingIds())
        
        networkService.fetchMyFollowingIds()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { ids in
                    followingIds = Set(ids)
                    StorageService.shared.saveFollowingIds(ids)
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
    let isInitiallyFollowing: Bool
    let onFollowChange: (Bool) -> Void
    
    @State private var isFollowing: Bool
    @State private var isRequesting = false
    @State private var showMessageView = false
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    private let storageService = StorageService.shared
    
    private var nameParts: [String] {
        user.name.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }
    
    private var firstName: String {
        nameParts.first ?? user.name
    }
    
    private var lastName: String {
        let tail = nameParts.dropFirst()
        return tail.isEmpty ? "" : tail.joined(separator: " ")
    }
    
    init(user: User, isInitiallyFollowing: Bool, onFollowChange: @escaping (Bool) -> Void) {
        self.user = user
        self.isInitiallyFollowing = isInitiallyFollowing
        self.onFollowChange = onFollowChange
        _isFollowing = State(initialValue: isInitiallyFollowing)
    }
    
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
                HStack(spacing: Theme.Spacing.xs) {
                    Text(firstName)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if user.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
                
                if !lastName.isEmpty {
                    Text(lastName)
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Text("@\(user.username)")
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
                    .lineLimit(1)
                
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
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(isFollowing ? .sioreeWhite : .sioreeIcyBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(minWidth: 108, minHeight: 38)
                        .padding(.horizontal, Theme.Spacing.s)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(isFollowing ? Color.sioreeIcyBlue : Color.sioreeIcyBlue.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                }
                .disabled(isRequesting)
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
            CreateConversationView(userId: user.id, userName: user.name ?? user.username)
        }
        .onAppear {
            isFollowing = isInitiallyFollowing
        }
        .onChange(of: isInitiallyFollowing) { _, newValue in
            isFollowing = newValue
        }
    }
    
    private func toggleFollow() {
        guard !isRequesting else { return }
        isRequesting = true
        
        let action = isFollowing ? networkService.unfollow(userId: user.id) : networkService.follow(userId: user.id)
        
        action
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isRequesting = false
                    if case .failure(let error) = completion {
                        print("❌ Follow toggle failed: \(error)")
                    }
                },
                receiveValue: { response in
                    isFollowing = response.following
                    
                    // Persist locally until the user explicitly unfollows
                    if response.following {
                        storageService.addFollowingId(user.id)
                    } else {
                        storageService.removeFollowingId(user.id)
                    }
                    
                    onFollowChange(response.following)
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    UserSearchView()
}

