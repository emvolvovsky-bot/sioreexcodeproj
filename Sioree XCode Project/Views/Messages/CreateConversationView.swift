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
    @FocusState private var isTextEditorFocused: Bool
    @State private var showSentBanner = false
    @State private var editorHeight: CGFloat = 56
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let conversation = conversation {
                    RealMessageView(conversation: conversation)
                } else {
                    VStack(spacing: 3) {
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        }

                        // Compact growing editor: starts small and grows as user types
                        GrowingTextEditor(
                            text: $messageText,
                            calculatedHeight: $editorHeight,
                            minHeight: 52,
                            maxHeight: 180,
                            isFirstResponder: isTextEditorFocused,
                            font: UIFont.preferredFont(forTextStyle: .body)
                        )
                        .frame(height: max(editorHeight, 52))
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.sioreeLightGrey.opacity(0.02))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.sioreeIcyBlue.opacity(0.18), lineWidth: 1)
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isTextEditorFocused = true
                            }
                        }

                        HStack {
                            Spacer()
                            Button(action: sendFirstMessage) {
                                Text("Send")
                                    .font(.sioreeBodyBold)
                                    .frame(minWidth: 120, minHeight: 44)
                                    .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? Color.gray : Color.sioreeIcyBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                        .padding(.bottom, Theme.Spacing.m)
                    }
                    .padding(.top, 4)
                    .offset(y: -8)
                }
                
                // Sent animation/banner
                if showSentBanner {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Sent")
                                .foregroundColor(.white)
                                .font(.sioreeBodyBold)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.green)
                        .cornerRadius(30)
                        .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 6)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .ignoresSafeArea(edges: .bottom)
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
                    // Notify inbox immediately
                    NotificationCenter.default.post(name: .refreshInbox, object: nil)

                    // Clear text and show sent banner with animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSentBanner = true
                        messageText = ""
                    }

                    // Dismiss after short delay allowing the user to see the banner
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut) {
                            showSentBanner = false
                        }
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

