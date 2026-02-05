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
                
                // Validate conversation data
                if conversation.participantId.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Invalid Conversation")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)
                        
                        Text("Unable to load conversation. Please try again.")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .padding(.top, Theme.Spacing.m)
                        .foregroundColor(.sioreeIcyBlue)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Custom header (back button left, centered name)
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18))
                                    .foregroundColor(.sioreeIcyBlue)
                                    .padding(8) // tappable area without visible background
                            }
                            .contentShape(Rectangle())

                            Spacer()

                            Text(conversation.participantName.isEmpty ? "Message" : conversation.participantName)
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity)

                            Spacer()

                            // Keep a same-size placeholder to balance layout (matches back button size)
                            Image(systemName: "chevron.left")
                                .opacity(0)
                                .padding(8)
                                .frame(width: 44, alignment: .trailing)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.s)

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
                                            .padding(.horizontal, Theme.Spacing.l)
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
                            TextField("Message...", text: $messageText, axis: .vertical)
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
                            .disabled(messageText.isEmpty || isLoading || conversation.participantId.isEmpty)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Render from local cache first, but always refresh from network so messages appear immediately.
                if !conversation.participantId.isEmpty && !conversation.id.isEmpty {
                    let local = MessageRepository.shared.fetchMessagesLocally(conversationId: conversation.id)
                    if !local.isEmpty {
                        self.messages = local
                    } else {
                        // If no local messages, show loading while fetching
                        self.isLoading = true
                    }
                    // Always attempt to refresh from network to ensure latest messages are present
                    loadMessagesFromNetwork()
                    // Do not trigger background sync here — sync is performed only after login
                    markAsRead()
                } else {
                    errorMessage = "Invalid conversation data"
                }
            }
            // Listen for local message saves (pending) and server upserts and refresh messages only for this conversation
            .onReceive(NotificationCenter.default.publisher(for: .messageSavedLocally)) { note in
                guard let convId = note.userInfo?["conversationId"] as? String, convId == conversation.id else { return }
                let local = MessageRepository.shared.fetchMessagesLocally(conversationId: conversation.id)
                if !local.isEmpty {
                    self.messages = local
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .messageUpserted)) { note in
                guard let convId = note.userInfo?["conversationId"] as? String, convId == conversation.id else { return }
                let local = MessageRepository.shared.fetchMessagesLocally(conversationId: conversation.id)
                if !local.isEmpty {
                    self.messages = local
                }
            }
            .onDisappear {
                // Refresh inbox when leaving message view
                NotificationCenter.default.post(name: .refreshInbox, object: nil)
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
        // Fetch without role filter to avoid backend filtering issues
        messagingService.getMessages(conversationId: conversation.id, role: nil)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { response in
                    // Always order chronologically so the newest renders at the bottom
                    self.messages = response.messages.sorted { $0.timestamp < $1.timestamp }
                }
            )
            .store(in: &cancellables)
    }

    private func loadMessagesFromNetwork() {
        isLoading = true
        messagingService.getMessages(conversationId: conversation.id, role: nil)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            }, receiveValue: { response in
                self.messages = response.messages.sorted { $0.timestamp < $1.timestamp }
                // Persist into local DB
                for msg in response.messages {
                    let dict: [String: Any] = [
                        "id": msg.id,
                        "conversationId": msg.conversationId,
                        "senderId": msg.senderId,
                        "receiverId": msg.receiverId,
                        "text": msg.text,
                        "timestamp": msg.timestamp.iso8601String()
                    ]
                    MessageRepository.shared.upsertMessageFromServer(messageDict: dict)
                }
            })
            .store(in: &cancellables)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        messagingService.sendMessage(
            conversationId: conversation.id,
            receiverId: conversation.participantId,
            text: text,
            senderRole: nil
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
                    messages.sort { $0.timestamp < $1.timestamp }
                    // Notify inbox views to refresh
                    NotificationCenter.default.post(name: .refreshInbox, object: nil)
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

