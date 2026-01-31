import Foundation
import CoreData
import Combine

final class MessageRepository {
    static let shared = MessageRepository()
    private let core = CoreDataStack.shared

    private init() {}

    // Save a pending message locally (optimistic send)
    func savePendingMessage(conversationId: String, text: String, senderId: String, receiverId: String, clientTempId: String) {
        let ctx = core.newBackgroundContext()
        ctx.perform {
            guard let entity = NSEntityDescription.entity(forEntityName: "MessageEntity", in: ctx) else {
                print("MessageEntity not found in model")
                return
            }
            let msg = NSManagedObject(entity: entity, insertInto: ctx)
            msg.setValue(UUID().uuidString, forKey: "id")
            msg.setValue(clientTempId, forKey: "clientTempId")
            msg.setValue(conversationId, forKey: "conversationId")
            msg.setValue(text, forKey: "text")
            msg.setValue(senderId, forKey: "senderId")
            msg.setValue(receiverId, forKey: "receiverId")
            msg.setValue(Date(), forKey: "createdAt")
            msg.setValue("pending", forKey: "status")
            do {
                try ctx.save()
                // Notify UI that a pending message was saved locally
                NotificationCenter.default.post(name: .messageSavedLocally, object: nil, userInfo: ["conversationId": conversationId])
            } catch {
                print("Failed to save pending message: \(error)")
            }
        }
    }

    // Update or insert message from server
    func upsertMessageFromServer(messageDict: [String: Any]) {
        let ctx = core.newBackgroundContext()
        ctx.perform {
            guard let entity = NSEntityDescription.entity(forEntityName: "MessageEntity", in: ctx) else {
                print("MessageEntity not found in model")
                return
            }

            // Try to match by server id or clientTempId
            let serverId = (messageDict["id"] as? String) ?? "\(messageDict["id"] ?? "")"
            let clientTempId = messageDict["clientTempId"] as? String

            let fetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MessageEntity")
            fetch.predicate = NSPredicate(format: "serverId == %@ OR clientTempId == %@", serverId, clientTempId ?? "")
            fetch.fetchLimit = 1

            do {
                let results = try ctx.fetch(fetch)
                let msg: NSManagedObject
                if let existing = results.first {
                    msg = existing
                } else {
                    msg = NSManagedObject(entity: entity, insertInto: ctx)
                }

                msg.setValue(serverId, forKey: "serverId")
                if let conversationId = messageDict["conversationId"] as? String {
                    msg.setValue(conversationId, forKey: "conversationId")
                }
                if let text = messageDict["text"] as? String {
                    msg.setValue(text, forKey: "text")
                }
                if let senderId = messageDict["senderId"] as? String {
                    msg.setValue(senderId, forKey: "senderId")
                }
                if let createdAtStr = messageDict["timestamp"] as? String {
                    let formatter = ISO8601DateFormatter()
                    if let d = formatter.date(from: createdAtStr) {
                        msg.setValue(d, forKey: "createdAt")
                    }
                }
                msg.setValue("sent", forKey: "status")

                try ctx.save()
                // Notify UI that a server message was upserted/updated locally
                if let convId = msg.value(forKey: "conversationId") as? String {
                    NotificationCenter.default.post(name: .messageUpserted, object: nil, userInfo: ["conversationId": convId])
                }
            } catch {
                print("Failed to upsert server message: \(error)")
            }
        }
    }

    // Fetch messages for a conversation from local Core Data (synchronous convenience)
    func fetchMessagesLocally(conversationId: String) -> [Message] {
        let ctx = core.viewContext
        let fetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MessageEntity")
        fetch.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        fetch.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let results = try ctx.fetch(fetch)
            var out: [Message] = []
            for obj in results {
                let id = (obj.value(forKey: "serverId") as? String) ?? (obj.value(forKey: "id") as? String) ?? UUID().uuidString
                let conversationId = obj.value(forKey: "conversationId") as? String ?? ""
                let senderId = obj.value(forKey: "senderId") as? String ?? ""
                let receiverId = obj.value(forKey: "receiverId") as? String ?? ""
                let text = obj.value(forKey: "text") as? String ?? ""
                let ts = obj.value(forKey: "createdAt") as? Date ?? Date()
                let isRead = obj.value(forKey: "isRead") as? Bool ?? false
                let messageType = obj.value(forKey: "messageType") as? String ?? "text"
                let message = Message(id: id, conversationId: conversationId, senderId: senderId, receiverId: receiverId, text: text, timestamp: ts, isRead: isRead, messageType: messageType)
                out.append(message)
            }
            return out
        } catch {
            print("Failed to fetch local messages: \(error)")
            return []
        }
    }
}

