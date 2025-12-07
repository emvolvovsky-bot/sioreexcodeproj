//
//  MessagingService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import Combine

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
    let isRead: Bool
    let messageType: String // "text", "image", "event_invite"
}

struct Conversation: Identifiable, Codable {
    let id: String
    let participantId: String
    let participantName: String
    let participantAvatar: String?
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    let isActive: Bool
}

struct ConversationResponse: Codable {
    let conversations: [Conversation]
    let total: Int
}

struct MessagesResponse: Codable {
    let messages: [Message]
    let hasMore: Bool
}

class MessagingService: ObservableObject {
    static let shared = MessagingService()
    private let networkService = NetworkService()
    
    // MARK: - Get Conversations
    func getConversations(role: String? = nil) -> AnyPublisher<[Conversation], Error> {
        // ✅ Using real backend API
        let useMockMessaging = false
        
        if useMockMessaging {
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.success([]))
                }
            }
            .eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let conversations: [Conversation]
        }
        
        var endpoint = "/api/messages/conversations"
        if let role = role {
            endpoint += "?role=\(role)"
        }
        
        return networkService.request(endpoint)
            .map { (response: Response) in response.conversations }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Messages for Conversation
    func getMessages(conversationId: String, page: Int = 1, role: String? = nil) -> AnyPublisher<MessagesResponse, Error> {
        let useMockMessaging = false  // ✅ Using real backend
        
        if useMockMessaging {
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let response = MessagesResponse(
                        messages: [],
                        hasMore: false
                    )
                    promise(.success(response))
                }
            }
            .eraseToAnyPublisher()
        }
        
        var endpoint = "/api/messages/\(conversationId)?page=\(page)"
        if let role = role {
            endpoint += "&role=\(role)"
        }
        
        return networkService.request(endpoint)
    }
    
    // MARK: - Send Message
    func sendMessage(conversationId: String?, receiverId: String, text: String, senderRole: String? = nil) -> AnyPublisher<Message, Error> {
        let useMockMessaging = false  // ✅ Using real backend
        
        var body: [String: Any] = [
            "receiverId": receiverId,
            "text": text,
            "messageType": "text"
        ]
        
        if let conversationId = conversationId {
            body["conversationId"] = conversationId
        }
        
        if let senderRole = senderRole {
            body["senderRole"] = senderRole
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        if useMockMessaging {
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let message = Message(
                        id: UUID().uuidString,
                        conversationId: conversationId ?? UUID().uuidString,
                        senderId: StorageService.shared.getUserId() ?? "current_user",
                        receiverId: receiverId,
                        text: text,
                        timestamp: Date(),
                        isRead: false,
                        messageType: "text"
                    )
                    promise(.success(message))
                }
            }
            .eraseToAnyPublisher()
        }
        
        return networkService.request("/api/messages", method: "POST", body: jsonData)
    }
    
    // MARK: - Mark as Read
    func markAsRead(conversationId: String) -> AnyPublisher<Bool, Error> {
        let useMockMessaging = false  // ✅ Using real backend
        
        if useMockMessaging {
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    promise(.success(true))
                }
            }
            .eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let success: Bool
        }
        return networkService.request("/api/messages/\(conversationId)/read", method: "POST")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Create or Get Conversation
    func getOrCreateConversation(with userId: String) -> AnyPublisher<Conversation, Error> {
        let useMockMessaging = false  // ✅ Using real backend
        
        let body: [String: Any] = ["userId": userId]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        if useMockMessaging {
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let conversation = Conversation(
                        id: UUID().uuidString,
                        participantId: userId,
                        participantName: "User",
                        participantAvatar: nil,
                        lastMessage: "",
                        lastMessageTime: Date(),
                        unreadCount: 0,
                        isActive: true
                    )
                    promise(.success(conversation))
                }
            }
            .eraseToAnyPublisher()
        }
        
        return networkService.request("/api/messages/conversation", method: "POST", body: jsonData)
    }
    
    // MARK: - Delete Message
    func deleteMessage(messageId: String) -> AnyPublisher<Bool, Error> {
        let useMockMessaging = false  // ✅ Using real backend
        
        if useMockMessaging {
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    promise(.success(true))
                }
            }
            .eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let success: Bool
        }
        return networkService.request("/api/messages/\(messageId)", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
}

