//
//  MessageView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct MessageView: View {
    let talent: TalentListing
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
                            if messages.isEmpty {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                    
                                    Text("Start a conversation")
                                        .font(.sioreeH3)
                                        .foregroundColor(Color.sioreeWhite)
                                    
                                    Text("Send a message to \(talent.name)")
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeLightGrey)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, Theme.Spacing.xl)
                            } else {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
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
                        .disabled(messageText.isEmpty)
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationTitle(talent.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
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
                text: "Thanks for reaching out! I'd love to discuss your event. When is it scheduled?",
                isFromCurrentUser: false,
                timestamp: Date()
            )
            messages.append(response)
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: Date
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                // Message text with long-press reactions
                MessageTextBubble(text: message.text, isFromCurrentUser: message.isFromCurrentUser)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isFromCurrentUser ? .trailing : .leading)
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
}

private struct MessageTextBubble: View {
    let text: String
    let isFromCurrentUser: Bool
    var body: some View {
        Text(text)
            .font(.sioreeBody)
            .foregroundColor(.sioreeWhite)
            .padding(Theme.Spacing.m)
            .background(isFromCurrentUser ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.2))
            .cornerRadius(Theme.CornerRadius.medium)
    }
}

#Preview {
    MessageView(talent: MockData.sampleTalent[0])
}



