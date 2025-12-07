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
                    Text(message.text)
                        .font(.sioreeBody)
                        .foregroundColor(isFromCurrentUser ? Color.sioreeWhite : Color.sioreeWhite)
                        .padding(Theme.Spacing.m)
                        .background(isFromCurrentUser ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.medium)
                }
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

// Swipeable message bubble with delete functionality
struct SwipeableMessageBubble: View {
    let message: Message
    let onDelete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDeleting = false
    private let currentUserId = StorageService.shared.getUserId() ?? ""
    
    private var isFromCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    // Only allow deletion of own messages
    private var canDelete: Bool {
        isFromCurrentUser && message.messageType != "deleted" && message.text != "[Message deleted]"
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background (only visible when swiped)
            if canDelete && dragOffset < -50 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isDeleting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .cornerRadius(Theme.CornerRadius.medium)
                    }
                    .padding(.trailing, Theme.Spacing.m)
                }
            }
            
            // Message bubble
            RealMessageBubble(message: message)
                .offset(x: canDelete ? dragOffset : 0)
                .opacity(isDeleting ? 0 : 1)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if canDelete {
                                // Only allow swiping left (negative offset)
                                if value.translation.width < 0 {
                                    dragOffset = value.translation.width
                                }
                            }
                        }
                        .onEnded { value in
                            if canDelete {
                                if value.translation.width < -100 {
                                    // Swiped far enough, trigger delete
                                    withAnimation {
                                        dragOffset = -200
                                        isDeleting = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onDelete()
                                    }
                                } else {
                                    // Spring back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
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
        ))
    }
    .padding()
    .background(Color.sioreeBlack)
}



