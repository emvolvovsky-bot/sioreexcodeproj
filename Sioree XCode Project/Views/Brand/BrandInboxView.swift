//
//  BrandInboxView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct BrandInboxView: View {
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSearch = false
    @State private var chatSearchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
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

                            Text(conversations.isEmpty ? "Connect with talent and hosts" : "Try a different search")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.xl)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(filteredConversations) { conversation in
                                    NavigationLink(destination: RealMessageView(conversation: conversation)) {
                                        BrandConversationRow(conversation: conversation)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.m)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView()
            }
            .onAppear {
                loadConversations()
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshInbox)) { _ in
                loadConversations()
            }
            .onReceive(NotificationCenter.default.publisher(for: .messageUpserted)) { _ in
                loadConversations()
            }
            .onReceive(NotificationCenter.default.publisher(for: .messageSavedLocally)) { _ in
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
        }
    }
    
    private var inboxSearchHeader: some View {
        HStack(spacing: Theme.Spacing.s) {
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
                showSearch = true
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

struct BrandConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.sioreeLightGrey.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.fill")
                    .foregroundColor(Color.sioreeIcyBlue)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(conversation.participantName)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeWhite)
                    
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(Color.sioreeIcyBlue)
                            .frame(width: 8, height: 8)
                    }
                }
                
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                Text(conversation.lastMessageTime.formatted(date: .omitted, time: .shortened))
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.sioreeCaption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.sioreeWhite)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.sioreeIcyBlue)
                        .cornerRadius(10)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(conversation.unreadCount > 0 ? Color.sioreeIcyBlue.opacity(0.1) : Color.sioreeLightGrey.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(conversation.unreadCount > 0 ? Color.sioreeIcyBlue.opacity(0.5) : Color.sioreeIcyBlue.opacity(0.2), lineWidth: 2)
        )
    }
}

#Preview {
    BrandInboxView()
}


