//
//  NetworkService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import Combine
import UIKit

struct FeedResponse: Codable {
    let events: [Event]
    let posts: [Post]
}

struct SearchResponse: Codable {
    let events: [Event]
    let hosts: [Host]
    let talent: [Talent]
    let posts: [Post]
}

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

class NetworkService {
    private let baseURL = Constants.API.baseURL
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = StorageService.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Sending auth token: \(token.prefix(20))...")
        } else {
            print("⚠️ No auth token found - request will be unauthenticated")
        }
        
        // Log request details for debugging
        print("📤 \(method) \(endpoint)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Request body: \(bodyString.prefix(200))...")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let decoder = JSONDecoder()
        // Use custom date decoding strategy that handles various ISO8601 formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601DateFormatter first (most common)
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601DateFormatter with fractional seconds
            let iso8601FormatterWithFractional = ISO8601DateFormatter()
            iso8601FormatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601FormatterWithFractional.date(from: dateString) {
                return date
            }
            
            // Try DateFormatter with various formats
            let dateFormatters: [DateFormatter] = [
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }()
            ]
            
            for formatter in dateFormatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // If all formatters fail, throw a descriptive error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted, but got: \(dateString)"
            )
        }
        
        return session.dataTaskPublisher(for: request)
            .timeout(.seconds(Int(Constants.API.timeout)), scheduler: DispatchQueue.global(), customError: {
                URLError(.timedOut)
            })
            .tryMap { data, response -> Data in
                // Log response for debugging
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Response: \(httpResponse.statusCode) for \(request.url?.absoluteString ?? "")")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📦 Full response body: \(jsonString)")
                    }
                    
                    // Check for error status codes
                    if httpResponse.statusCode >= 400 {
                        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorMessage = errorJson["error"] as? String {
                            print("❌ Server error: \(errorMessage)")
                            throw NetworkError.serverError(errorMessage)
                        }
                        print("❌ HTTP error: \(httpResponse.statusCode)")
                        throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
                    }
                }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> Error in
                // Handle timeout and network errors
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        print("❌ Request timed out after \(Constants.API.timeout) seconds")
                        return NetworkError.serverError("Connection terminated due to connection timeout. Please check your internet connection and ensure the backend server is running.")
                    case .notConnectedToInternet:
                        return NetworkError.serverError("No internet connection. Please check your network settings.")
                    case .cannotConnectToHost:
                        return NetworkError.serverError("Cannot connect to server. Please ensure the backend is running at \(self.baseURL).")
                    default:
                        return NetworkError.serverError("Network error: \(urlError.localizedDescription)")
                    }
                }
                // Better error logging for decoding errors
                if let decodingError = error as? DecodingError {
                    print("❌ JSON Decoding Error: \(decodingError)")
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: expected \(type), path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type), path: \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("   Key not found: \(key.stringValue), path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                    return NetworkError.decodingError
                }
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Feed
    func fetchFeed(filter: FeedFilter, page: Int) -> AnyPublisher<FeedResponse, Error> {
        return request("/api/feed?filter=\(filter.rawValue)&page=\(page)")
    }
    
    // MARK: - Events
    func fetchFeaturedEvents() -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]
        }
        return request("/api/events/featured")
            .map { (response: Response) in response.events }
            .eraseToAnyPublisher()
    }
    
    func fetchNearbyEvents(latitude: Double? = nil, longitude: Double? = nil, radiusMiles: Int = 30) -> AnyPublisher<[Event], Error> {
        struct NearbyEventsResponse: Codable {
            let events: [Event]
        }
        var endpoint = "/api/events/nearby"
        var params: [String] = []
        if let latitude {
            params.append("lat=\(latitude)")
        }
        if let longitude {
            params.append("lng=\(longitude)")
        }
        params.append("radius=\(radiusMiles)")
        if !params.isEmpty {
            endpoint += "?" + params.joined(separator: "&")
        }
        
        return request(endpoint)
            .map { (response: NearbyEventsResponse) in
                response.events
            }
            .eraseToAnyPublisher()
    }
    
    func fetchEvent(eventId: String) -> AnyPublisher<Event, Error> {
        return request("/api/events/\(eventId)")
    }

    func fetchEventBookings(eventId: String) -> AnyPublisher<[Booking], Error> {
        struct Response: Codable {
            let bookings: [Booking]
        }
        return request("/api/bookings/event/\(eventId)")
            .map { (response: Response) in response.bookings }
            .eraseToAnyPublisher()
    }
    
    func fetchEventsLookingForTalent(talentType: String) -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]
        }
        let trimmed = talentType.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedType = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let endpoint: String
        if encodedType.isEmpty {
            endpoint = "/api/events/looking-for"
        } else {
            endpoint = "/api/events/looking-for?roles=\(encodedType)"
        }
        return request(endpoint)
            .map { (response: Response) in response.events }
            .eraseToAnyPublisher()
    }
    
    func fetchTalentUpcomingEvents() -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]
        }
        return request("/api/events/talent/upcoming")
            .map { (response: Response) in response.events }
            .eraseToAnyPublisher()
    }
    
    func fetchRecentEventSignups() -> AnyPublisher<[EventSignup], Error> {
        return request("/api/events/host/recent-signups")
            .map { (response: EventSignupsResponse) in response.signups }
            .eraseToAnyPublisher()
    }
    
    func createEvent(title: String,
                     description: String,
                     date: Date,
                     time: Date,
                     location: String,
                     images: [String],
                     ticketPrice: Double?,
                     capacity: Int? = nil,
                     talentIds: [String] = [],
                     lookingForRoles: [String] = [],
                     lookingForNotes: String? = nil,
                     lookingForTalentType: String? = nil) -> AnyPublisher<Event, Error> {
        // Combine date and time for event_date
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        let combinedDate = calendar.date(from: combinedComponents) ?? date
        
        let isoDate = ISO8601DateFormatter().string(from: combinedDate)
        
        // Send both camelCase and snake_case keys for maximum backend compatibility
        var body: [String: Any] = [
            "title": title,
            "description": description,
            "event_date": isoDate,
            "eventDate": isoDate,
            "date": isoDate,
            "location": location,
            "images": images
        ]
        
        // Handle ticket_price - always send as a number (Double)
        // For free events, send 0.0 as a Double
        // For paid events, send the price as a Double
        // JSONSerialization will handle Double correctly as a number
        if let price = ticketPrice, price > 0 {
            body["ticket_price"] = Double(price)  // Explicitly cast to Double to ensure number type
            body["ticketPrice"] = Double(price)
        } else {
            body["ticket_price"] = Double(0.0)  // Free event - send as Double 0.0
            body["ticketPrice"] = Double(0.0)
        }
        
        // Add capacity if provided
        if let capacity = capacity {
            body["capacity"] = capacity
        }
        
        // Add talent IDs if provided
        body["talentIds"] = talentIds
        body["talent_ids"] = talentIds
        
        // Add structured looking-for roles and notes
        if !lookingForRoles.isEmpty {
            body["lookingForRoles"] = lookingForRoles
            body["looking_for_roles"] = lookingForRoles
        }
        if let notes = lookingForNotes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            body["lookingForNotes"] = notes
            body["looking_for_notes"] = notes
            body["lookingForTalentNotes"] = notes
        }
        
        let trimmedRolesSummary = lookingForRoles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        var lookingForSummaryParts: [String] = []
        if !trimmedRolesSummary.isEmpty { lookingForSummaryParts.append(trimmedRolesSummary) }
        if let notes = lookingForNotes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            lookingForSummaryParts.append(notes)
        }
        let fallbackLookingFor = lookingForSummaryParts.joined(separator: " — ")
        
        // Add looking for talent type if provided
        let talentType = (lookingForTalentType?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? (fallbackLookingFor.isEmpty ? nil : fallbackLookingFor)
            ?? "General talent"
        
        // Always include keys so backend validators see the field defined, and ensure it's non-empty
        body["lookingForTalentType"] = talentType
        body["looking_for_talent_type"] = talentType
        body["talentNeeded"] = talentType
        
        print("📤 Creating event with body: \(body)")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/events", method: "POST", body: jsonData)
    }
    
    func toggleEventLike(eventId: String) -> AnyPublisher<Bool, Error> {
        return request("/api/events/\(eventId)/like", method: "POST")
    }
    
    func toggleEventSave(eventId: String) -> AnyPublisher<Bool, Error> {
        return request("/api/events/\(eventId)/save", method: "POST")
    }
    
    func rsvpToEvent(eventId: String) -> AnyPublisher<RSVPResponse, Error> {
        struct Response: Codable {
            let success: Bool
            let qrCode: String?
        }
        return request("/api/events/\(eventId)/rsvp", method: "POST")
            .map { (response: Response) in
                RSVPResponse(success: response.success, qrCode: response.qrCode)
            }
            .eraseToAnyPublisher()
    }
    
    struct RSVPResponse {
        let success: Bool
        let qrCode: String?
    }
    
    func cancelRSVP(eventId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/events/\(eventId)/rsvp", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    func fetchEventAttendees(eventId: String) -> AnyPublisher<[Attendee], Error> {
        struct Response: Codable {
            let attendees: [Attendee]
        }
        return request("/api/events/\(eventId)/attendees")
            .map { (response: Response) in response.attendees }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Users
    func fetchUserProfile(userId: String) -> AnyPublisher<User, Error> {
        return request("/api/users/\(userId)")
    }
    
    func fetchTalentCompletedEvents(talentUserId: String) -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]?
        }
        return request("/api/talent/\(talentUserId)/completed-events")
            .map { (response: Response) in response.events ?? [] }
            .eraseToAnyPublisher()
    }
    
    func fetchUserEvents(userId: String) -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]
        }
        return request("/api/users/\(userId)/events")
            .map { (response: Response) in response.events }
            .eraseToAnyPublisher()
    }
    
    func fetchAttendedEvents(userId: String) -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]
        }
        return request("/api/users/\(userId)/attended")
            .map { (response: Response) in response.events }
            .eraseToAnyPublisher()
    }
    
    func fetchUpcomingAttendingEvents() -> AnyPublisher<[Event], Error> {
        struct Response: Codable {
            let events: [Event]
        }
        return request("/api/events/attending/upcoming")
            .map { (response: Response) in response.events }
            .eraseToAnyPublisher()
    }
    
    func deleteEvent(eventId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/events/\(eventId)", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    func fetchUserPosts(userId: String) -> AnyPublisher<[Post], Error> {
        struct PostsResponse: Codable {
            let posts: [Post]
        }
        return request("/api/users/\(userId)/posts")
            .map { (response: PostsResponse) in response.posts }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Group Chats
    func createGroupChat(title: String, memberIds: [String]) -> AnyPublisher<GroupChat, Error> {
        let body: [String: Any] = [
            "title": title,
            "memberIds": memberIds
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let id: String
            let title: String
            let isGroup: Bool
            let members: [GroupMember]
            let createdAt: String
        }

        let endpoints = [
            "/api/messages/groups",
            "/api/messages/group-chats",      // fallback alias
            "/api/messages/groupchat"         // fallback alias
        ]

        func attempt(_ index: Int) -> AnyPublisher<GroupChat, Error> {
            guard index < endpoints.count else {
                return Fail(error: NetworkError.serverError("Group chat endpoint unavailable")).eraseToAnyPublisher()
            }

            return request(endpoints[index], method: "POST", body: jsonData)
                .map { (response: Response) in
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let date = formatter.date(from: response.createdAt) ?? Date()
                    
                    return GroupChat(
                        id: response.id,
                        title: response.title,
                        members: response.members,
                        createdAt: date
                    )
                }
                .catch { error -> AnyPublisher<GroupChat, Error> in
                    if case let NetworkError.serverError(message) = error,
                       message.contains("404") {
                        // Retry next alias on 404
                        return attempt(index + 1)
                    }
                    return Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        return attempt(0)
    }
    
    func getGroupMembers(conversationId: String) -> AnyPublisher<[GroupMember], Error> {
        struct Response: Codable {
            let members: [GroupMember]
        }
        return request("/api/messages/groups/\(conversationId)/members")
            .map { (response: Response) in response.members }
            .eraseToAnyPublisher()
    }
    
    func addGroupMembers(conversationId: String, memberIds: [String]) -> AnyPublisher<Bool, Error> {
        let body: [String: Any] = [
            "memberIds": memberIds
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/messages/groups/\(conversationId)/members", method: "POST", body: jsonData)
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    func removeGroupMember(conversationId: String, memberId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/messages/groups/\(conversationId)/members/\(memberId)", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    func updateProfile(name: String?, username: String?, bio: String?, location: String?) -> AnyPublisher<User, Error> {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let username = username { body["username"] = username }
        if let bio = bio { body["bio"] = bio }
        if let location = location { body["location"] = location }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/users/profile", method: "PATCH", body: jsonData)
    }
    
    func uploadProfilePicture(image: UIImage) -> AnyPublisher<String, Error> {
        // Resize and compress image before upload to avoid HTTP 413 errors
        let resizedImage = image.resized(to: CGSize(width: 800, height: 800))
        
        // Try different compression qualities to keep file size under 1MB
        var compressionQuality: CGFloat = 0.7
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        let maxSize = 1 * 1024 * 1024 // 1MB
        
        // Reduce quality if image is still too large
        while let data = imageData, data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalImageData = imageData else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        let base64String = finalImageData.base64EncodedString()
        let body: [String: Any] = [
            "avatar": "data:image/jpeg;base64,\(base64String)"
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        struct Response: Codable {
            let avatar: String
        }
        
        return request("/api/users/profile/avatar", method: "POST", body: jsonData)
            .map { (response: Response) in response.avatar }
            .eraseToAnyPublisher()
    }

    func uploadTalentClips(eventId: String, images: [UIImage]) -> AnyPublisher<[String], Error> {
        // Process images - resize and compress
        let processedImages = images.map { image -> Data in
            let resizedImage = image.resized(to: CGSize(width: 800, height: 800))

            var compressionQuality: CGFloat = 0.7
            var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            let maxSize = 1 * 1024 * 1024 // 1MB

            while let data = imageData, data.count > maxSize && compressionQuality > 0.1 {
                compressionQuality -= 0.1
                imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            }

            return imageData ?? Data()
        }

        let base64Strings = processedImages.map { "data:image/jpeg;base64,\($0.base64EncodedString())" }

        let body: [String: Any] = [
            "eventId": eventId,
            "clips": base64Strings
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        struct Response: Codable {
            let clips: [String]
        }

        return request("/api/talent/clips", method: "POST", body: jsonData)
            .map { (response: Response) in response.clips }
            .eraseToAnyPublisher()
    }

    func fetchTalentMediaForHost(hostId: String) -> AnyPublisher<[TalentMediaItem], Error> {
        return request("/api/hosts/\(hostId)/talent-media")
    }

    struct FollowUpdateResponse: Codable {
        let following: Bool
        let followerCount: Int?
        let followingCount: Int?
        let targetFollowerCount: Int?
        let targetFollowingCount: Int?
        let wasInserted: Bool?

        enum CodingKeys: String, CodingKey {
            case following
            case followerCount
            case followingCount
            case targetFollowerCount = "targetFollowerCount"
            case targetFollowingCount = "targetFollowingCount"
            case wasInserted
        }

        init(following: Bool, followerCount: Int? = nil, followingCount: Int? = nil, targetFollowerCount: Int? = nil, targetFollowingCount: Int? = nil, wasInserted: Bool? = nil) {
            self.following = following
            self.followerCount = followerCount
            self.followingCount = followingCount
            self.targetFollowerCount = targetFollowerCount
            self.targetFollowingCount = targetFollowingCount
            self.wasInserted = wasInserted
        }
    }
    
    private func performFollowRequest(userId: String, method: String) -> AnyPublisher<FollowUpdateResponse, Error> {
        struct LegacyToggleResponse: Codable { let following: Bool }
        
        let primary: AnyPublisher<FollowUpdateResponse, Error> = request("/api/follow/\(userId)", method: method)
        
        return primary
            .catch { error -> AnyPublisher<FollowUpdateResponse, Error> in
                if case NetworkError.serverError(let message) = error, message.contains("HTTP 404") {
                    // Fallback to legacy toggle endpoint
                    return self.request("/api/users/\(userId)/follow", method: "POST")
                        .flatMap { (legacy: LegacyToggleResponse) -> AnyPublisher<FollowUpdateResponse, Error> in
                            // Fetch updated counts so UI can refresh
                            return self.fetchUserProfile(userId: userId)
                                .map { profile in
                                    FollowUpdateResponse(
                                        following: legacy.following,
                                        followerCount: profile.followerCount,
                                        followingCount: nil
                                    )
                                }
                                .eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func follow(userId: String) -> AnyPublisher<FollowUpdateResponse, Error> {
        return performFollowRequest(userId: userId, method: "POST")
    }
    
    func unfollow(userId: String) -> AnyPublisher<FollowUpdateResponse, Error> {
        return performFollowRequest(userId: userId, method: "DELETE")
    }
    
    func fetchMyFollowing() -> AnyPublisher<[User], Error> {
        struct Response: Codable {
            let users: [User]
        }
        return request("/api/following")
            .map { (response: Response) in response.users }
            .catch { error -> AnyPublisher<[User], Error> in
                if case NetworkError.serverError(let message) = error, message.contains("HTTP 404") {
                    // Legacy fallback to following-list
                    guard let currentUserId = StorageService.shared.getUserId() else {
                        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    struct LegacyResponse: Codable { let users: [User] }
                    return self.request("/api/users/\(currentUserId)/following-list")
                        .map { (response: LegacyResponse) in response.users }
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func fetchMyFollowingIds() -> AnyPublisher<[String], Error> {
        struct Response: Codable {
            let followingIds: [String]?
        }
        return request("/api/following")
            .map { (response: Response) in response.followingIds ?? [] }
            .catch { error -> AnyPublisher<[String], Error> in
                if case NetworkError.serverError(let message) = error, message.contains("HTTP 404") {
                    // Legacy fallback to following-list
                    guard let currentUserId = StorageService.shared.getUserId() else {
                        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    struct LegacyResponse: Codable { let users: [User] }
                    return self.request("/api/users/\(currentUserId)/following-list")
                        .map { (response: LegacyResponse) in response.users.map { $0.id } }
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func fetchFollowers(userId: String, userType: UserType? = nil) -> AnyPublisher<[User], Error> {
        struct Response: Codable {
            let users: [User]
        }
        var endpoint = "/api/users/\(userId)/followers"
        if let userType = userType {
            endpoint += "?userType=\(userType.rawValue)"
        }
        return request(endpoint)
            .map { (response: Response) in response.users }
            .eraseToAnyPublisher()
    }
    
    func fetchFollowing(userId: String, userType: UserType? = nil) -> AnyPublisher<[User], Error> {
        struct Response: Codable {
            let users: [User]
        }
        var endpoint = "/api/users/\(userId)/following-list"
        if let userType = userType {
            endpoint += "?userType=\(userType.rawValue)"
        }
        return request(endpoint)
            .map { (response: Response) in response.users }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Talent
    func fetchTalent(category: TalentCategory?, searchQuery: String?) -> AnyPublisher<[Talent], Error> {
        var endpoint = "/api/talent"
        var queryParams: [String] = []
        
        if let category = category {
            queryParams.append("category=\(category.rawValue)")
        }
        if let query = searchQuery {
            queryParams.append("search=\(query)")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return request(endpoint)
    }
    
    func fetchTalentProfile(talentId: String) -> AnyPublisher<Talent, Error> {
        return request("/api/talent/\(talentId)")
    }
    
    func registerTalent(category: TalentCategory, bio: String?, priceMin: Double?, priceMax: Double?) -> AnyPublisher<Talent, Error> {
        struct Response: Codable {
            let talent: Talent
        }
        var body: [String: Any] = [
            "category": category.rawValue
        ]
        if let bio = bio { body["bio"] = bio }
        if let priceMin = priceMin { body["priceMin"] = priceMin }
        if let priceMax = priceMax { body["priceMax"] = priceMax }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        return request("/api/talent", method: "POST", body: jsonData)
            .map { (response: Response) in response.talent }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Bookings
    func fetchBookings() -> AnyPublisher<[Booking], Error> {
        return request("/api/bookings")
    }
    
    func createBooking(talentId: String, eventId: String?, date: Date, time: Date, duration: Int, price: Double, notes: String?) -> AnyPublisher<Booking, Error> {
        var body: [String: Any] = [
            "talentId": talentId,
            "date": ISO8601DateFormatter().string(from: date),
            "time": ISO8601DateFormatter().string(from: time),
            "duration": duration,
            "price": price
        ]
        
        if let eventId = eventId { body["eventId"] = eventId }
        if let notes = notes { body["notes"] = notes }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/bookings", method: "POST", body: jsonData)
    }
    
    func updateBookingStatus(bookingId: String, status: BookingStatus) -> AnyPublisher<Bool, Error> {
        let body: [String: Any] = ["status": status.rawValue]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/bookings/\(bookingId)/status", method: "PATCH", body: jsonData)
    }
    
    // MARK: - Search
    func search(query: String, category: SearchCategory) -> AnyPublisher<SearchResponse, Error> {
        let endpoint = "/api/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&category=\(category.rawValue)"
        return request(endpoint)
    }
    
    func fetchTrendingSearches() -> AnyPublisher<[String], Error> {
        return request("/api/search/trending")
    }
    
    func searchUsers(query: String) -> AnyPublisher<[User], Error> {
        struct Response: Codable {
            let users: [User]?
        }
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return request("/api/users/search?q=\(encodedQuery)")
            .map { (response: Response) in response.users ?? [] }
            .eraseToAnyPublisher()
    }
    
    func fetchAllUsers() -> AnyPublisher<[User], Error> {
        struct Response: Codable {
            let users: [User]?
        }
        // Use wildcard query to get all users
        return request("/api/users/search?q=*")
            .map { (response: Response) in response.users ?? [] }
            .eraseToAnyPublisher()
    }
    
    func checkFollowing(userId: String) -> AnyPublisher<[String: Bool], Error> {
        return fetchMyFollowingIds()
            .map { ids in ["following": ids.contains(userId)] }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Event Promotion (for brands)
    func promoteEvent(eventId: String, expiresAt: Date? = nil, promotionBudget: Double = 0) -> AnyPublisher<Bool, Error> {
        // Brand promotions have been removed
        return Fail(error: NetworkError.serverError("Brand promotions are disabled")).eraseToAnyPublisher()
    }
    
    func unpromoteEvent(eventId: String) -> AnyPublisher<Bool, Error> {
        // Brand promotions have been removed
        return Fail(error: NetworkError.serverError("Brand promotions are disabled")).eraseToAnyPublisher()
    }
    
    // MARK: - Reviews
    func createReview(reviewedUserId: String, rating: Int, comment: String?) -> AnyPublisher<Review, Error> {
        let body: [String: Any] = [
            "reviewedUserId": reviewedUserId,
            "rating": rating,
            "comment": comment ?? ""
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/reviews", method: "POST", body: jsonData)
    }
    
    func fetchReviews(userId: String) -> AnyPublisher<[Review], Error> {
        struct Response: Codable {
            let reviews: [Review]
        }
        return request("/api/reviews/\(userId)")
            .map { (response: Response) in response.reviews }
            .eraseToAnyPublisher()
    }
    
    func deleteReview(reviewId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/reviews/\(reviewId)", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Brand Insights
    func fetchBrandInsights() -> AnyPublisher<BrandInsights, Error> {
        return request("/api/brands/insights")
    }
    
    func trackEventImpression(eventId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        let body: [String: Any] = ["eventId": eventId]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        return request("/api/brands/track-impression", method: "POST", body: jsonData)
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    func fetchBrandPromotedEvents() -> AnyPublisher<[PromotedEvent], Error> {
        struct PromotedEventsResponse: Codable {
            let events: [PromotedEvent]
        }
        return request("/api/brands/promoted-events")
            .map { (response: PromotedEventsResponse) in response.events }
            .eraseToAnyPublisher()
    }

    // MARK: - Posts

    func createPost(caption: String?, mediaUrls: [String] = [], location: String? = nil, eventId: String? = nil) -> AnyPublisher<Post, Error> {
        var body: [String: Any] = [
            "mediaUrls": mediaUrls
        ]

        if let caption = caption {
            body["caption"] = caption
        }
        if let location = location {
            body["location"] = location
        }
        if let eventId = eventId {
            body["eventId"] = eventId
        }

        print("📡 NetworkService.createPost sending body: \(body)")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        return request("/api/posts", method: "POST", body: jsonData)
    }

    func fetchPostsForEvent(eventId: String) -> AnyPublisher<[Post], Error> {
        struct Response: Codable {
            let posts: [Post]
        }
        return request("/api/posts/event/\(eventId)")
            .map { (response: Response) in response.posts }
            .eraseToAnyPublisher()
    }

    func fetchFeedPosts(page: Int = 1) -> AnyPublisher<[Post], Error> {
        struct Response: Codable {
            let posts: [Post]
        }
        return request("/api/posts?page=\(page)")
            .map { (response: Response) in response.posts }
            .eraseToAnyPublisher()
    }

    func deletePost(postId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/posts/\(postId)", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }

    func togglePostLike(postId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let liked: Bool
        }
        return request("/api/posts/\(postId)/like", method: "POST")
            .map { (response: Response) in response.liked }
            .eraseToAnyPublisher()
    }

    // MARK: - Earnings
    func fetchEarnings() -> AnyPublisher<EarningsResponse, Error> {
        return request("/api/earnings")
    }
    
    func withdrawEarnings(amount: Double, bankAccountId: String) -> AnyPublisher<Bool, Error> {
        struct WithdrawResponse: Codable {
            let success: Bool
        }
        let body: [String: Any] = [
            "amount": amount,
            "bankAccountId": bankAccountId
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        return request("/api/earnings/withdraw", method: "POST", body: jsonData)
            .map { (response: WithdrawResponse) in response.success }
            .eraseToAnyPublisher()
    }
}

// MARK: - Earnings Models
struct Earning: Identifiable, Codable {
    let id: String
    let amount: Double
    let source: String
    let date: Date
    let eventId: String?
}

struct Withdrawal: Identifiable, Codable {
    let id: String
    let amount: Double
    let bankAccountName: String
    let date: Date
    let status: WithdrawalStatus
}

enum WithdrawalStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

struct EarningsResponse: Codable {
    let totalEarnings: Double
    let earnings: [Earning]
    let withdrawals: [Withdrawal]
}

// MARK: - Brand Models
struct PromotedEvent: Identifiable, Codable {
    let id: String
    let title: String
    let location: String
    let date: Date?
    let promotedAt: Date?
    let expiresAt: Date?
    let budget: Double
    
    enum CodingKeys: String, CodingKey {
        case id, title, location, date, budget
        case promotedAt = "promotedAt"
        case expiresAt = "expiresAt"
    }
}

