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
                Text(message.text)
                    .font(.sioreeBody)
                    .foregroundColor(isFromCurrentUser ? Color.sioreeWhite : Color.sioreeWhite)
                    .padding(Theme.Spacing.m)
                    .background(isFromCurrentUser ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.2))
                    .cornerRadius(Theme.CornerRadius.medium)
                
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



