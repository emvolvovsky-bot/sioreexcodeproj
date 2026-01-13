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
    let eventId: String?
    let bookingId: String?
    let conversationTitle: String?
    let eventTitle: String?
    let eventDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, participantId, participantName, participantAvatar, lastMessage, lastMessageTime, unreadCount, isActive
        case eventId, bookingId, conversationTitle, eventTitle, eventDate
    }

    init(id: String,
         participantId: String,
         participantName: String,
         participantAvatar: String? = nil,
         lastMessage: String,
         lastMessageTime: Date,
         unreadCount: Int,
         isActive: Bool,
         eventId: String? = nil,
         bookingId: String? = nil,
         conversationTitle: String? = nil,
         eventTitle: String? = nil,
         eventDate: Date? = nil) {
        self.id = id
        self.participantId = participantId
        self.participantName = participantName
        self.participantAvatar = participantAvatar
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
        self.isActive = isActive
        self.eventId = eventId
        self.bookingId = bookingId
        self.conversationTitle = conversationTitle
        self.eventTitle = eventTitle
        self.eventDate = eventDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode id as String
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Cannot decode id")
        }
        
        // Handle participantId - can be null for group chats, but we need a value
        if let participantIdString = try container.decodeIfPresent(String.self, forKey: .participantId),
           !participantIdString.isEmpty {
            participantId = participantIdString
        } else {
            // For group chats or missing participantId, use empty string as fallback
            // This should not happen for 1-on-1 conversations
            participantId = ""
        }
        
        // Decode participantName with fallback
        participantName = try container.decodeIfPresent(String.self, forKey: .participantName) ?? "Unknown"
        participantAvatar = try container.decodeIfPresent(String.self, forKey: .participantAvatar)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage) ?? ""
        
        // Handle date decoding
        if let dateString = try? container.decode(String.self, forKey: .lastMessageTime) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastMessageTime = formatter.date(from: dateString) ?? Date()
        } else {
            lastMessageTime = Date()
        }
        
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        
        // Optional fields
        if let eventIdString = try container.decodeIfPresent(String.self, forKey: .eventId),
           !eventIdString.isEmpty {
            eventId = eventIdString
        } else {
            eventId = nil
        }
        
        if let bookingIdString = try container.decodeIfPresent(String.self, forKey: .bookingId),
           !bookingIdString.isEmpty {
            bookingId = bookingIdString
        } else {
            bookingId = nil
        }
        
        conversationTitle = try container.decodeIfPresent(String.self, forKey: .conversationTitle)
        eventTitle = try container.decodeIfPresent(String.self, forKey: .eventTitle)
        
        // Handle eventDate
        if let dateString = try container.decodeIfPresent(String.self, forKey: .eventDate),
           !dateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            eventDate = formatter.date(from: dateString)
        } else {
            eventDate = nil
        }
    }
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
    func getConversations() -> AnyPublisher<[Conversation], Error> {
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
        
        return networkService.request("/api/messages/conversations")
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
    func getOrCreateConversation(with userId: String, eventId: String? = nil, bookingId: String? = nil) -> AnyPublisher<Conversation, Error> {
        let useMockMessaging = false  // ✅ Using real backend

        var body: [String: Any] = ["userId": userId]
        if let eventId = eventId { body["eventId"] = eventId }
        if let bookingId = bookingId { body["bookingId"] = bookingId }

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

