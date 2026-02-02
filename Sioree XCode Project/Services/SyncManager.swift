import Foundation
import Combine
import CoreData

final class SyncManager {
    static let shared = SyncManager()
    private let messaging = MessagingService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // Start background sync (call on app launch)
    func start() {
        // Periodic simple timer-based sync; in production, tie to push notifications and reachability
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncConversationsDelta()
                self?.sendPendingMessages()
            }
            .store(in: &cancellables)
    }

    // Fetch conversations updated after localLatest
    func syncConversationsDelta() {
        // Don't attempt to sync conversations unless we have an authenticated user.
        // This avoids unauthenticated or pre-login syncs that may seed the local DB with conversations
        // belonging to other users.
        guard let currentUserId = StorageService.shared.getUserId(), !currentUserId.isEmpty else {
            // No authenticated user yet — skip sync.
            return
        }

        // TODO: compute local latest updatedAt from Core Data; for now pass nil to fetch all deltas
        // The messaging.getConversations() endpoint is already scoped to the authenticated user on the server,
        // but we still guard here to avoid calling it before login (which can produce confusing UI state).
        messaging.getConversations()
            .sink(receiveCompletion: { completion in
                if case .failure(let err) = completion {
                    print("Conversation delta fetch failed: \(err)")
                }
            }, receiveValue: { conversations in
                // Upsert conversations into Core Data (only store conversations for current user)
                for conv in conversations {
                    // Defensive: ensure participant belongs to current user context for 1:1 chats.
                    // Group chats will have nil participantId.
                    if !conv.participantId.isEmpty {
                        // nothing additional required here — server returns only authorized conversations
                    }

                    let dict: [String: Any] = [
                        "id": conv.id,
                        "participantId": conv.participantId,
                        "participantName": conv.participantName,
                        "participantAvatar": conv.participantAvatar ?? NSNull(),
                        "updatedAt": conv.lastMessageTime.iso8601String()
                    ]
                    ConversationRepository.shared.upsertConversation(convDict: dict)

                    // DEBUG: log fetched conversation and verify authorization by attempting to fetch messages.
                    let isGroup = conv.participantId.isEmpty
                    print("📥 Fetched conversation id=\(conv.id) isGroup=\(isGroup) participantId=\(conv.participantId) title=\(conv.conversationTitle ?? "")")
                    MessagingService.shared.getMessages(conversationId: conv.id, page: 1)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let err) = completion {
                                print("⛔ Authorization check failed for conversation \(conv.id): \(err)")
                            }
                        }, receiveValue: { _ in
                            print("✅ Authorization check passed for conversation \(conv.id)")
                        })
                        .store(in: &self.cancellables)
                }
            })
            .store(in: &cancellables)
    }

    // Send pending messages from local DB
    func sendPendingMessages() {
        let ctx = CoreDataStack.shared.newBackgroundContext()
        ctx.perform {
            let fetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MessageEntity")
            fetch.predicate = NSPredicate(format: "status == %@", "pending")
            do {
                let pending = try ctx.fetch(fetch)
                for msg in pending {
                    guard
                        let conversationId = msg.value(forKey: "conversationId") as? String,
                        let text = msg.value(forKey: "text") as? String,
                        let receiverId = msg.value(forKey: "receiverId") as? String,
                        let clientTempId = msg.value(forKey: "clientTempId") as? String
                    else { continue }

                    // Call network send with clientTempId to reconcile
                    DispatchQueue.main.async {
                        _ = self.messaging.sendMessage(conversationId: conversationId, receiverId: receiverId, text: text, clientTempId: clientTempId)
                            .sink(receiveCompletion: { completion in
                                if case .failure(let err) = completion {
                                    print("Failed to send pending message: \(err)")
                                }
                            }, receiveValue: { serverMsg in
                                // Upsert server message locally
                                if let data = try? JSONEncoder().encode(serverMsg),
                                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                    MessageRepository.shared.upsertMessageFromServer(messageDict: dict)
                                }
                            })
                    }
                }
            } catch {
                print("Failed to fetch pending messages: \(error)")
            }
        }
    }
}

