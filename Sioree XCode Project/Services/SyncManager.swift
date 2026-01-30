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
        // TODO: compute local latest updatedAt from Core Data; for now pass nil to fetch all
        let updatedAfter: String? = nil
        var endpoint = "/api/messages/conversations"
        if let updatedAfter = updatedAfter {
            endpoint += "?updated_after=\(updatedAfter)"
        }

        messaging.getConversations()
            .sink(receiveCompletion: { completion in
                if case .failure(let err) = completion {
                    print("Conversation delta fetch failed: \(err)")
                }
            }, receiveValue: { conversations in
                // Upsert conversations into Core Data
                for conv in conversations {
                    let dict: [String: Any] = [
                        "id": conv.id,
                        "participantId": conv.participantId,
                        "participantName": conv.participantName,
                        "participantAvatar": conv.participantAvatar ?? NSNull(),
                        "updatedAt": conv.lastMessageTime.iso8601String()
                    ]
                    ConversationRepository.shared.upsertConversation(convDict: dict)
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

