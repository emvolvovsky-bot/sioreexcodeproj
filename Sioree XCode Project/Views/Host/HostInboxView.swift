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
    @State private var showCreateGroup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                if isLoading {
                    LoadingView()
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
                                NavigationLink(
                                    destination:
                                        RealMessageView(conversation: conversation)
                                            .onAppear { NotificationCenter.default.post(name: .hideTabBar, object: nil) }
                                            .onDisappear { NotificationCenter.default.post(name: .showTabBar, object: nil) }
                                ) {
                                    HostConversationRow(conversation: conversation)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: Theme.Spacing.m) {
                        Button(action: {
                            showCreateGroup = true
                        }) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.sioreeIcyBlue)
                                .frame(width: 36, height: 36)
                                .background(Color.sioreeIcyBlue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            showSearch = true
                        }) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.sioreeIcyBlue)
                                .frame(width: 36, height: 36)
                                .background(Color.sioreeIcyBlue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Text a person")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.sioreeIcyBlue)
                            .frame(width: 36, height: 36)
                            .background(Color.sioreeIcyBlue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Search users")
                }
            }
            .overlay(alignment: .topTrailing) {
                // Floating Action Button
                Button(action: {
                    showSearch = true
                }) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.sioreeIcyBlue.opacity(0.4),
                                        Color.sioreeIcyBlue.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                            .blur(radius: 8)
                        
                        // Button circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.sioreeIcyBlue.opacity(0.9),
                                        Color.sioreeIcyBlue
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.sioreeIcyBlue.opacity(0.5), radius: 16, x: 0, y: 8)
                        
                        // Plus icon
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                }
                .padding(.trailing, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView()
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupChatView()
            }
            .onAppear {
                loadConversations()
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshInbox)) { _ in
                loadConversations()
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
                    }
                },
                receiveValue: { conversations in
                    self.conversations = conversations.sorted { $0.lastMessageTime > $1.lastMessageTime }
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct HostConversationRow: View {
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
                    
                    if let avatar = conversation.participantAvatar, !avatar.isEmpty, let url = URL(string: avatar) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color.sioreeIcyBlue)
                                    .font(.system(size: 20, weight: .semibold))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color.sioreeIcyBlue)
                                    .font(.system(size: 20, weight: .semibold))
                            @unknown default:
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color.sioreeIcyBlue)
                                    .font(.system(size: 20, weight: .semibold))
                            }
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color.sioreeIcyBlue)
                            .font(.system(size: 20, weight: .semibold))
                    }
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

