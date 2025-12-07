//
//  RealMessageView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct RealMessageView: View {
    let conversation: Conversation
    @Environment(\.dismiss) var dismiss
    @StateObject private var messagingService = MessagingService.shared
    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    
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
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                if isLoading && messages.isEmpty {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                                        .padding(.top, Theme.Spacing.xl)
                                } else if messages.isEmpty {
                                    VStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                        
                                        Text("Start a conversation")
                                            .font(.sioreeH3)
                                            .foregroundColor(Color.sioreeWhite)
                                        
                                        Text("Send a message to \(conversation.participantName)")
                                            .font(.sioreeBody)
                                            .foregroundColor(Color.sioreeLightGrey)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, Theme.Spacing.xl)
                                } else {
                                    ForEach(messages) { message in
                                        SwipeableMessageBubble(
                                            message: message,
                                            onDelete: {
                                                deleteMessage(message)
                                            }
                                        )
                                        .id(message.id)
                                        .padding(.horizontal, Theme.Spacing.m)
                                    }
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
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
                        .disabled(messageText.isEmpty || isLoading)
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationTitle(conversation.participantName)
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
                loadMessages()
                markAsRead()
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
    
    private func loadMessages() {
        isLoading = true
        // Pass the current role to filter messages by role
        let currentRole = selectedRoleRaw.isEmpty ? nil : selectedRoleRaw
        messagingService.getMessages(conversationId: conversation.id, role: currentRole)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { response in
                    self.messages = response.messages.reversed() // Most recent at bottom
                }
            )
            .store(in: &cancellables)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        // Pass the current role when sending message
        let currentRole = selectedRoleRaw.isEmpty ? nil : selectedRoleRaw
        messagingService.sendMessage(
            conversationId: conversation.id,
            receiverId: conversation.participantId,
            text: text,
            senderRole: currentRole
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    messageText = text // Restore text on error
                }
            },
            receiveValue: { message in
                messages.append(message)
            }
        )
        .store(in: &cancellables)
    }
    
    private func markAsRead() {
        messagingService.markAsRead(conversationId: conversation.id)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    private func deleteMessage(_ message: Message) {
        messagingService.deleteMessage(messageId: message.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { success in
                    if success {
                        // Remove message from local array
                        messages.removeAll { $0.id == message.id }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    RealMessageView(conversation: Conversation(
        id: "c1",
        participantId: "u1",
        participantName: "DJ Midnight",
        participantAvatar: nil,
        lastMessage: "Hey!",
        lastMessageTime: Date(),
        unreadCount: 2,
        isActive: true
    ))
}

