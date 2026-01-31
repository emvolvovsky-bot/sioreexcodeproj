import Foundation
import CoreData

final class ConversationRepository {
    static let shared = ConversationRepository()
    private let core = CoreDataStack.shared

    private init() {}

    func upsertConversation(convDict: [String: Any]) {
        let ctx = core.newBackgroundContext()
        ctx.perform {
            guard let entity = NSEntityDescription.entity(forEntityName: "ConversationEntity", in: ctx) else {
                print("ConversationEntity not found in model")
                return
            }

            let serverId = (convDict["id"] as? String) ?? "\(convDict["id"] ?? "")"

            let fetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ConversationEntity")
            fetch.predicate = NSPredicate(format: "serverId == %@", serverId)
            fetch.fetchLimit = 1

            do {
                let results = try ctx.fetch(fetch)
                let conv: NSManagedObject
                if let existing = results.first {
                    conv = existing
                } else {
                    conv = NSManagedObject(entity: entity, insertInto: ctx)
                }

                // Ensure a local UUID `id` exists (Core Data model may mark `id` as required)
                if conv.value(forKey: "id") == nil {
                    conv.setValue(UUID().uuidString, forKey: "id")
                }

                conv.setValue(serverId, forKey: "serverId")
                // Normalize participantId/name/avatar to strings to avoid Core Data type mismatches
                if let participantId = convDict["participantId"] {
                    conv.setValue("\(participantId)", forKey: "participantId")
                } else {
                    conv.setValue(nil, forKey: "participantId")
                }
                conv.setValue(convDict["participantName"] as? String, forKey: "participantName")
                conv.setValue(convDict["participantAvatar"] as? String, forKey: "participantAvatar")
                if let updatedAt = convDict["updatedAt"] as? String {
                    let formatter = ISO8601DateFormatter()
                    if let d = formatter.date(from: updatedAt) {
                        conv.setValue(d, forKey: "updatedAt")
                    }
                }

                try ctx.save()
            } catch {
                print("Failed to upsert conversation: \(error)")
            }
        }
    }

    // Fetch conversations locally (synchronous)
    func fetchConversationsLocally() -> [Conversation] {
        let ctx = core.viewContext
        let fetch: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ConversationEntity")
        fetch.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        do {
            let results = try ctx.fetch(fetch)
            var out: [Conversation] = []
            for obj in results {
                let id = (obj.value(forKey: "serverId") as? String) ?? UUID().uuidString
                let participantId = obj.value(forKey: "participantId") as? String ?? ""
                let participantName = obj.value(forKey: "participantName") as? String ?? "Unknown"
                let participantAvatar = obj.value(forKey: "participantAvatar") as? String
                let lastMessage = obj.value(forKey: "lastMessage") as? String ?? ""
                let lastMessageTime = obj.value(forKey: "updatedAt") as? Date ?? Date()
                let unreadCount = obj.value(forKey: "unreadCount") as? Int ?? 0
                let conv = Conversation(id: id, participantId: participantId, participantName: participantName, participantAvatar: participantAvatar, lastMessage: lastMessage, lastMessageTime: lastMessageTime, unreadCount: unreadCount, isActive: true)
                out.append(conv)
            }
            return out
        } catch {
            print("Failed to fetch local conversations: \(error)")
            return []
        }
    }
}

