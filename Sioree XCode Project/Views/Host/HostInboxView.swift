//
//  HostInboxView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct HostConversation: Identifiable {
    let id: String
    let talentName: String
    let talentRole: String
    let lastMessage: String
    let timestamp: Date
    let isUnread: Bool
    
    init(id: String = UUID().uuidString,
         talentName: String,
         talentRole: String,
         lastMessage: String,
         timestamp: Date,
         isUnread: Bool = false) {
        self.id = id
        self.talentName = talentName
        self.talentRole = talentRole
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.isUnread = isUnread
    }
}

struct HostInboxView: View {
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var selectedConversation: Conversation?
    @State private var errorMessage: String?
    @State private var showSearch = false
    
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
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                } else if conversations.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                        
                        Text("No messages yet")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)
                        
                        Text("Answer any questions from partiers")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                        
                        Text("Reach out to talent")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(conversations) { conversation in
                                RealConversationRow(conversation: conversation) {
                                    selectedConversation = conversation
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView()
            }
            .onAppear {
                loadConversations()
            }
            .refreshable {
                loadConversations()
            }
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func loadConversations() {
        isLoading = true
        messagingService.getConversations()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { conversations in
                    self.conversations = conversations
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct RealConversationRow: View {
    let conversation: Conversation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.m) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.sioreeLightGrey.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    if let avatar = conversation.participantAvatar, !avatar.isEmpty {
                        AsyncImage(url: URL(string: avatar)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.sioreeIcyBlue)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
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
                    
                    Text(conversation.lastMessage)
                        .font(.sioreeBodySmall)
                        .foregroundColor(conversation.unreadCount > 0 ? Color.sioreeWhite : Color.sioreeLightGrey)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text(conversation.lastMessageTime.formatted(date: .omitted, time: .shortened))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.sioreeCaption)
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
}

struct HostConversationRow: View {
    let conversation: HostConversation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                        Text(conversation.talentName)
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeWhite)
                        
                        if conversation.isUnread {
                            Circle()
                                .fill(Color.sioreeIcyBlue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(conversation.talentRole)
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeLightGrey)
                    
                    Text(conversation.lastMessage)
                        .font(.sioreeBodySmall)
                        .foregroundColor(conversation.isUnread ? Color.sioreeWhite : Color.sioreeLightGrey)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text(conversation.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                }
            }
            .padding(Theme.Spacing.m)
            .background(conversation.isUnread ? Color.sioreeIcyBlue.opacity(0.1) : Color.sioreeLightGrey.opacity(0.05))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(conversation.isUnread ? Color.sioreeIcyBlue.opacity(0.5) : Color.sioreeIcyBlue.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

struct HostMessageView: View {
    let conversation: HostConversation
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    
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
                    // Messages
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(messages.isEmpty ? [ChatMessage(text: conversation.lastMessage, isFromCurrentUser: false, timestamp: conversation.timestamp)] : messages) { message in
                                MessageBubble(message: message)
                                    .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                    
                    // Input
                    HStack(spacing: Theme.Spacing.s) {
                        TextField("Type a message...", text: $messageText, axis: .vertical)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeLightGrey.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                            )
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(messageText.isEmpty ? Color.sioreeLightGrey.opacity(0.3) : Color.sioreeIcyBlue)
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationTitle(conversation.talentName)
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
                // Load existing messages
                if messages.isEmpty {
                    messages.append(ChatMessage(text: conversation.lastMessage, isFromCurrentUser: false, timestamp: conversation.timestamp))
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newMessage = ChatMessage(
            text: messageText,
            isFromCurrentUser: true,
            timestamp: Date()
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // Simulate response after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let response = ChatMessage(
                text: "Got it! I'll get back to you soon.",
                isFromCurrentUser: false,
                timestamp: Date()
            )
            messages.append(response)
        }
    }
}

#Preview {
    HostInboxView()
}

