//
//  AttendeeMessageView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct AttendeeMessageView: View {
    let attendee: Attendee
    @Environment(\.dismiss) var dismiss
    @StateObject private var messagingService = MessagingService.shared
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var conversation: Conversation?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCheck = false
    @State private var checkScale: CGFloat = 0.6
    
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
                                    
                                    Text("Send a message to \(attendee.name)")
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeLightGrey)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, Theme.Spacing.xl)
                            } else {
                                ForEach(messages) { message in
                                    RealMessageBubble(message: message)
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
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
            .navigationTitle(attendee.name)
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
                // Do NOT create a conversation when opening this view.
                // Leave `conversation` nil until a message is actually sent.
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
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        // Get or create conversation first
        if let conversation = conversation {
            sendMessageToConversation(conversation, text: text)
        } else {
            createConversationAndSend(text: text)
        }
    }
    
    private func createConversationAndSend(text: String) {
        isLoading = true
        // Send message without pre-creating a conversation. Backend will create it if needed.
        messagingService.sendMessage(conversationId: nil, receiverId: attendee.id, text: text)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        messageText = text
                    }
                },
                receiveValue: { message in
                    // Show checkmark animation and dismiss the message composer.
                    withAnimation {
                        showCheck = true
                    }
                    NotificationCenter.default.post(name: .refreshInbox, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        dismiss()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func sendMessageToConversation(_ conversation: Conversation, text: String) {
        messagingService.sendMessage(
            conversationId: conversation.id,
            receiverId: attendee.id,
            text: text
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    messageText = text
                }
            },
            receiveValue: { message in
                messages.append(message)
            }
        )
        .store(in: &cancellables)
    }
    
    private func loadMessages() {
        guard let conversation = conversation else { return }
        isLoading = true
        messagingService.getMessages(conversationId: conversation.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { response in
                    self.messages = response.messages.reversed()
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    AttendeeMessageView(attendee: Attendee(
        id: "1",
        name: "Alex Johnson",
        username: "@alexj",
        avatar: nil,
        isVerified: false
    ))
}

