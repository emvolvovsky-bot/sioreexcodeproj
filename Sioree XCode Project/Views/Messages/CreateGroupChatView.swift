//
//  CreateGroupChatView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct CreateGroupChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var groupTitle: String = ""
    @State private var selectedMembers: Set<String> = []
    @State private var allUsers: [User] = []
    @State private var searchQuery: String = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    
    var filteredUsers: [User] {
        if searchQuery.isEmpty {
            return allUsers
        }
        return allUsers.filter { user in
            user.name.localizedCaseInsensitiveContains(searchQuery) ||
            user.username.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Group Title Input
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Group Name")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.top, Theme.Spacing.m)
                        
                        TextField("Enter group name", text: $groupTitle)
                            .padding(Theme.Spacing.m)
                            .foregroundColor(.sioreeWhite)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, Theme.Spacing.m)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        TextField("Search users...", text: $searchQuery)
                            .foregroundColor(.sioreeWhite)
                    }
                    .padding(Theme.Spacing.m)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    
                    // Selected Members Count
                    if !selectedMembers.isEmpty {
                        HStack {
                            Text("\(selectedMembers.count) selected")
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeIcyBlue)
                            Spacer()
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.s)
                    }
                    
                    // Users List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredUsers) { user in
                                if user.id != authViewModel.currentUser?.id {
                                    Button(action: {
                                        if selectedMembers.contains(user.id) {
                                            selectedMembers.remove(user.id)
                                        } else {
                                            selectedMembers.insert(user.id)
                                        }
                                    }) {
                                        HStack(spacing: Theme.Spacing.m) {
                                            AvatarView(imageURL: user.avatar, size: .medium)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(user.name)
                                                    .font(.sioreeBody)
                                                    .foregroundColor(.sioreeWhite)
                                                Text("@\(user.username)")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedMembers.contains(user.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.sioreeIcyBlue)
                                            } else {
                                                Image(systemName: "circle")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                            }
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .padding(.vertical, Theme.Spacing.m)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if user.id != filteredUsers.last?.id {
                                        Divider()
                                            .background(Color.sioreeLightGrey.opacity(0.2))
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Group Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroupChat()
                    }
                    .fontWeight(.semibold)
                    .disabled(isCreating || groupTitle.isEmpty || selectedMembers.isEmpty)
                }
            }
            .overlay {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        networkService.fetchAllUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [self] users in
                    allUsers = users
                }
            )
            .store(in: &cancellables)
    }
    
    private func createGroupChat() {
        guard !groupTitle.isEmpty, !selectedMembers.isEmpty else { return }
        
        isCreating = true
        errorMessage = ""
        
        networkService.createGroupChat(
            title: groupTitle,
            memberIds: Array(selectedMembers)
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [self] completion in
                isCreating = false
                if case .failure(let error) = completion {
                    // Show more specific server message if available
                    if case let NetworkError.serverError(message) = error {
                        errorMessage = "Failed to create group chat: \(message)"
                    } else {
                        errorMessage = "Failed to create group chat: \(error.localizedDescription)"
                    }
                    showError = true
                }
            },
            receiveValue: { [self] _ in
                // Success - dismiss
                dismiss()
            }
        )
        .store(in: &cancellables)
    }
}

#Preview {
    CreateGroupChatView()
        .environmentObject(AuthViewModel())
}

