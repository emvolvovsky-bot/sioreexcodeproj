//
//  CreateConversationView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct CreateConversationView: View {
    let userId: String
    let userName: String
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversation: Conversation?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var messageText: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.dismiss) var dismiss
    @State private var showCheck = false
    @State private var checkScale: CGFloat = 0.6
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let conversation = conversation {
                    RealMessageView(conversation: conversation)
                } else {
                    VStack(spacing: Theme.Spacing.m) {
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        }
                        Spacer()
                        TextField("Type a message to \(userName)...", text: $messageText, axis: .vertical)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeLightGrey.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                            )
                            .padding(.horizontal, Theme.Spacing.l)

                        Button(action: sendFirstMessage) {
                            Text("Send")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.sioreeIcyBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        .padding(.horizontal, Theme.Spacing.l)
                        Spacer()
                    }
                }
                
                // Checkmark overlay after successful send
                if showCheck {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 88))
                            .foregroundColor(.green)
                            .scaleEffect(checkScale)
                            .opacity(showCheck ? 1 : 0)
                            .onAppear {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                    checkScale = 1.05
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        checkScale = 1.0
                                    }
                                }
                            }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle(userName)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Do not auto-create conversations on appear.
            }
        }
    }
    
    private func sendFirstMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isLoading = true
        messagingService.sendMessage(conversationId: nil, receiverId: userId, text: text)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { message in
                    // Show checkmark then dismiss composer. Backend will have created the conversation.
                    withAnimation {
                        showCheck = true
                    }
                    // Notify inbox immediately
                    NotificationCenter.default.post(name: .refreshInbox, object: nil)
                    // Dismiss after brief animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        dismiss()
                    }
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    CreateConversationView(userId: "test-id", userName: "Test User")
}

