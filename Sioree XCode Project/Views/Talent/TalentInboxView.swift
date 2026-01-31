//
//  TalentInboxView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentInboxView: View {
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var selectedConversation: Conversation?
    @State private var errorMessage: String?
    @State private var showSearch = false
    @State private var chatSearchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                VStack(spacing: Theme.Spacing.m) {
                    inboxSearchHeader

                    if filteredConversations.isEmpty {
                        Spacer()
                        VStack(spacing: Theme.Spacing.s) {
                            Text(conversations.isEmpty ? "No messages yet" : "No chats found")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)

                            if conversations.isEmpty {
                                Text("Communicate with other talent, partiers, and hosts")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("Try a different search")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey)
                                    .multilineTextAlignment(.center)
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
                                        TalentConversationRow(conversation: conversation)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
            .sheet(isPresented: $showSearch) {
                UserSearchView()
            }
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
                    .onAppear { NotificationCenter.default.post(name: .hideTabBar, object: nil) }
                    .onDisappear { NotificationCenter.default.post(name: .showTabBar, object: nil) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { note in
                guard let dict = note.userInfo?["conversation"] as? [String: Any] else { return }
                let id = dict["id"] as? String ?? UUID().uuidString
                let participantId = dict["participantId"] as? String ?? ""
                let participantName = dict["participantName"] as? String ?? "Unknown"
                let participantAvatar = dict["participantAvatar"] as? String
                let lastMessage = dict["lastMessage"] as? String ?? ""
                var lastMessageTime = Date()
                if let timeStr = dict["lastMessageTime"] as? String {
                    let fmt = ISO8601DateFormatter()
                    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    lastMessageTime = fmt.date(from: timeStr) ?? Date()
                }
                let unreadCount = dict["unreadCount"] as? Int ?? 0
                let conv = Conversation(id: id, participantId: participantId, participantName: participantName, participantAvatar: participantAvatar, lastMessage: lastMessage, lastMessageTime: lastMessageTime, unreadCount: unreadCount, isActive: true)
                selectedConversation = conv
            }
            .onAppear {
                let local = ConversationRepository.shared.fetchConversationsLocally()
                // Ensure local conversations are ordered newest-first
                self.conversations = local.sorted { $0.lastMessageTime > $1.lastMessageTime }
                // Do not trigger network fetch here — sync is performed only after login
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshInbox)) { _ in
                loadConversations(showLoading: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .messageUpserted)) { _ in
                loadConversations(showLoading: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .messageSavedLocally)) { _ in
                loadConversations(showLoading: false)
            }
        }
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
    
    private func loadConversations(showLoading: Bool = false) {
        if showLoading { isLoading = true }
        // Fetch shared inbox across all roles
        messagingService.getConversations()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if showLoading { isLoading = false }
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { conversations in
                    self.conversations = conversations.sorted { $0.lastMessageTime > $1.lastMessageTime }
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
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct TalentConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Avatar - Tappable to navigate to profile (use InboxProfileView to match UserSearch flow)
            NavigationLink(destination: InboxProfileView(userId: conversation.participantId)) {
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
                    
                    AvatarView(imageURL: conversation.participantAvatar, userId: conversation.participantId, size: .medium)
                        .frame(width: 56, height: 56)
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
    TalentInboxView()
}

