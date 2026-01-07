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
    @State private var showCreateGroup = false
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
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(conversations) { conversation in
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
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showCreateGroup = true
                    }) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupChatView()
            }
            .onAppear {
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


