//
//  PartierInboxView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct PartierInboxView: View {
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateGroup = false
    @State private var showUserSearch = false
    @State private var chatSearchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                VStack(spacing: Theme.Spacing.m) {
                    inboxSearchHeader

                    if isLoading {
                        Spacer()
                        LoadingView()
                        Spacer()
                    } else if filteredConversations.isEmpty {
                        Spacer()
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))

                            Text(conversations.isEmpty ? "No messages yet" : "No chats found")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)

                            Text(conversations.isEmpty ? "Thank a host or ask a question" : "Try a different search")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.xl)

                            if conversations.isEmpty {
                                Text("Ask talent a question")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Theme.Spacing.xl)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(filteredConversations) { conversation in
                                    NavigationLink(
                                        destination:
                                            RealMessageView(conversation: conversation)
                                                .onAppear { NotificationCenter.default.post(name: .hideTabBar, object: nil) }
                                                .onDisappear { NotificationCenter.default.post(name: .showTabBar, object: nil) }
                                    ) {
                                        PartierConversationRow(conversation: conversation)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteConversation(conversation)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.l)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.m)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupChatView()
            }
            .sheet(isPresented: $showUserSearch) {
                UserSearchView()
            }
            .onAppear {
                let local = ConversationRepository.shared.fetchConversationsLocally()
                if !local.isEmpty {
                    self.conversations = local
                    self.isLoading = false
                } else {
                    loadConversations()
                }
                SyncManager.shared.syncConversationsDelta()
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshInbox)) { _ in
                loadConversations()
            }
        }
    }
    
    private func loadConversations() {
        isLoading = true
        // Fetch shared inbox across all roles
        messagingService.getConversations()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        print("❌ Failed to load conversations: \(error)")
                    }
                },
                receiveValue: { fetchedConversations in
                    conversations = fetchedConversations.sorted { $0.lastMessageTime > $1.lastMessageTime }
                    isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeBlack,
                    Color.sioreeBlack.opacity(0.98),
                    Color.sioreeCharcoal.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -120, y: -320)
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: 160, y: 220)
        }
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        messagingService.deleteConversation(conversationId: conversation.id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to delete conversation: \(error)")
                }
            } receiveValue: { success in
                if success {
                    withAnimation {
                        conversations.removeAll { $0.id == conversation.id }
                    }
                } else {
                    print("⚠️ Delete conversation returned false for id: \(conversation.id)")
                }
            }
            .store(in: &cancellables)
    }

    private var filteredConversations: [Conversation] {
        let trimmedQuery = chatSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return conversations }
        let query = trimmedQuery.lowercased()
        return conversations.filter { conversation in
            conversation.participantName.lowercased().contains(query)
                || conversation.lastMessage.lowercased().contains(query)
        }
    }

    private var inboxSearchHeader: some View {
        HStack(spacing: Theme.Spacing.s) {
            Button(action: {
                showCreateGroup = true
            }) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.sioreeIcyBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.sioreeIcyBlue.opacity(0.15))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Create group chat")
            
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.8))
                
                TextField("Search chats", text: $chatSearchText)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                if !chatSearchText.isEmpty {
                    Button(action: { chatSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.8))
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(Color.sioreeLightGrey.opacity(0.12))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
            )
            
            Button(action: {
                showUserSearch = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sioreeWhite)
                    .frame(width: 34, height: 34)
                    .background(
                        LinearGradient(
                            colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("New chat")
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}

struct PartierConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Avatar - Tappable to navigate to profile
            NavigationLink(destination: UserProfileView(userId: conversation.participantId)) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.sioreeIcyBlue.opacity(0.3),
                                    Color.sioreeIcyBlue.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.sioreeIcyBlue.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: Color.sioreeIcyBlue.opacity(0.25), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(Color.sioreeIcyBlue)
                        .font(.system(size: 20, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(conversation.participantName)
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.sioreeWhite)
                    
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(Color.sioreeIcyBlue)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.sioreeIcyBlue.opacity(0.6), radius: 4)
                    }
                }
                
                Text(conversation.lastMessage)
                    .font(.sioreeBodySmall)
                    .foregroundColor(conversation.unreadCount > 0 ? Color.sioreeWhite.opacity(0.9) : Color.sioreeLightGrey.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(conversation.lastMessageTime.formatted(date: .omitted, time: .shortened))
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.8))
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.sioreeCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.sioreeWhite)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.sioreeIcyBlue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(conversation.unreadCount > 0 ? 0.1 : 0.06))
                .background(
                    .ultraThinMaterial.opacity(0.7),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            conversation.unreadCount > 0 ? Color.sioreeIcyBlue.opacity(0.5) : Color.white.opacity(0.15),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(
            color: conversation.unreadCount > 0 ? Color.sioreeIcyBlue.opacity(0.3) : Color.black.opacity(0.3),
            radius: conversation.unreadCount > 0 ? 20 : 12,
            x: 0,
            y: conversation.unreadCount > 0 ? 10 : 6
        )
    }
}

#Preview {
    NavigationStack {
        PartierInboxView()
    }
}

