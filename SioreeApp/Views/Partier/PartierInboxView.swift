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
    @State private var showSearch = false
    @State private var showCreateGroup = false
    @State private var showNewChatModal = false
    @State private var selectedUserId: String?
    @State private var selectedUserName: String?
    @State private var showConversation = false
    @State private var cancellables = Set<AnyCancellable>()
    
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
                        
                        Text("Thank a host or ask a question")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                        
                        Text("Ask talent a question")
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
                                    PartierConversationRow(conversation: conversation)
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
                    showNewChatModal = true
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
            .sheet(isPresented: $showNewChatModal) {
                NewChatSelectionView(
                    onSelectUser: { userId, userName in
                        showNewChatModal = false
                        selectedUserId = userId
                        selectedUserName = userName
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showConversation = true
                        }
                    },
                    onSelectGroupChat: {
                        showNewChatModal = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showCreateGroup = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showConversation) {
                if let userId = selectedUserId, let userName = selectedUserName {
                    CreateConversationView(userId: userId, userName: userName)
                }
            }
            .onAppear {
                loadConversations()
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

