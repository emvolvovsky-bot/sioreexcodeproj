//
//  RealMessageBubble.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct RealMessageBubble: View {
    let message: Message
    private let currentUserId = StorageService.shared.getUserId() ?? ""
    
    private var isFromCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                // Show deleted message indicator if message was deleted
                if message.messageType == "deleted" || message.text == "[Message deleted]" {
                    Text("[Message deleted]")
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                        .italic()
                        .padding(Theme.Spacing.m)
                } else {
                    // Message text with long-press reactions support
                    MessageTextBubble(text: message.text, isFromCurrentUser: isFromCurrentUser)
                }
                // reactions intentionally removed (no UI)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

// Small reusable view for the message text that supports long-press reactions
private struct MessageTextBubble: View {
    let text: String
    let isFromCurrentUser: Bool

    var body: some View {
        let bgColor = isFromCurrentUser ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.15)
        let strokeColor = isFromCurrentUser ? Color.sioreeIcyBlue.opacity(0.4) : Color.white.opacity(0.1)
        let shadowColor = isFromCurrentUser ? Color.sioreeIcyBlue.opacity(0.3) : Color.black.opacity(0.2)

        Text(text)
            .font(.sioreeBody)
            .foregroundColor(Color.sioreeWhite)
            .padding(Theme.Spacing.m)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(bgColor))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(strokeColor, lineWidth: 1))
            .shadow(color: shadowColor, radius: isFromCurrentUser ? 12 : 8, x: 0, y: 4)
    }
}

// Swipeable message bubble with delete functionality
struct SwipeableMessageBubble: View {
    let message: Message
    let onDelete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showTimestamp: Bool = false
    @State private var isDeleting = false
    private let currentUserId = StorageService.shared.getUserId() ?? ""
    
    private var isFromCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    // Only allow deletion of own messages
    private var canDelete: Bool {
        isFromCurrentUser && message.messageType != "deleted" && message.text != "[Message deleted]"
    }
    
    // Feature flag: disable swipe-to-delete UI (keeps delete API intact)
    private let allowSwipeDelete = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background removed (swipe-to-delete disabled)
            
            // Timestamp badge shown when user swipes right
            if showTimestamp {
                HStack {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.sioreeCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding(.leading, Theme.Spacing.m)
                    Spacer()
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Message bubble
            RealMessageBubble(message: message)
                .offset(x: dragOffset)
                .opacity(isDeleting ? 0 : 1)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow right-swipe for timestamp preview. Left-swipe is ignored to prevent delete.
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            } else {
                                // ignore left drag
                                dragOffset = 0
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 60 {
                                // Swiped right enough: toggle timestamp display
                                withAnimation(.spring()) {
                                    showTimestamp.toggle()
                                }
                                // spring back visually
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            } else {
                                // Spring back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
        }
    }
}

#Preview {
    VStack {
        RealMessageBubble(message: Message(
            id: "m1",
            conversationId: "c1",
            senderId: "u1",
            receiverId: "u2",
            text: "Hello!",
            timestamp: Date(),
            isRead: false,
            messageType: "text"
            , reaction: nil
        ))
        
        RealMessageBubble(message: Message(
            id: "m2",
            conversationId: "c1",
            senderId: "u2",
            receiverId: "u1",
            text: "Hi there!",
            timestamp: Date(),
            isRead: false,
            messageType: "text"
            , reaction: nil
        ))
    }
    .padding()
    .background(Color.sioreeBlack)
}



