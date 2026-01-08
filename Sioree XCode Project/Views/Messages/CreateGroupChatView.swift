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
    @State private var initialMessage: String = ""
    @State private var selectedMembers: Set<String> = []
    @State private var allUsers: [User] = []
    @State private var searchQuery: String = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    @StateObject private var messagingService = MessagingService.shared
    
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
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .fill(Color.sioreeLightGrey.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1.5)
                            )
                            .padding(.horizontal, Theme.Spacing.m)
                    }
                    
                    // Initial Message Input
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Initial Message")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.top, Theme.Spacing.m)
                        
                        TextField("Say something to start the conversation...", text: $initialMessage, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(Theme.Spacing.m)
                            .foregroundColor(.sioreeWhite)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .fill(Color.sioreeLightGrey.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1.5)
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
                    .foregroundColor(.sioreeIcyBlue)
                    .disabled(isCreating || groupTitle.isEmpty || selectedMembers.isEmpty || initialMessage.trimmingCharacters(in: .whitespaces).isEmpty)
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
        guard !groupTitle.isEmpty, !selectedMembers.isEmpty, !initialMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
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
            receiveValue: { [self] groupChat in
                // After successfully creating the group chat, try to send the initial message
                let trimmedMessage = initialMessage.trimmingCharacters(in: .whitespaces)
                sendInitialMessage(to: groupChat.id, text: trimmedMessage)
            }
        )
        .store(in: &cancellables)
    }
    
    private func sendInitialMessage(to conversationId: String, text: String) {
        // For group chats, we use the conversationId and pass sender as receiverId
        // The backend will handle group chats correctly when conversationId is provided
        let currentUserId = authViewModel.currentUser?.id ?? ""
        
        messagingService.sendMessage(
            conversationId: conversationId,
            receiverId: currentUserId, // For group chats, backend will handle this
            text: text
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [self] completion in
                // Don't show error for message sending failure - group chat was created successfully
                if case .failure(let error) = completion {
                    print("⚠️ Note: Group chat created but initial message couldn't be sent: \(error.localizedDescription)")
                    print("⚠️ User can send their first message manually when they open the chat")
                }
                // Always dismiss since group chat creation succeeded
                dismiss()
            },
            receiveValue: { [self] _ in
                // Success - message sent
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

