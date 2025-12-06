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
                // Better error logging
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
    
    func fetchNearbyEvents() -> AnyPublisher<[Event], Error> {
        struct NearbyEventsResponse: Codable {
            let events: [Event]
        }
        return request("/api/events/nearby")
            .map { (response: NearbyEventsResponse) in
                response.events
            }
            .eraseToAnyPublisher()
    }
    
    func fetchEvent(eventId: String) -> AnyPublisher<Event, Error> {
        return request("/api/events/\(eventId)")
    }
    
    func createEvent(title: String, description: String, date: Date, time: Date, location: String, images: [String], ticketPrice: Double?, capacity: Int? = nil) -> AnyPublisher<Event, Error> {
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
        
        var body: [String: Any] = [
            "title": title,
            "description": description,
            "event_date": ISO8601DateFormatter().string(from: combinedDate),
            "location": location,
            "images": images
        ]
        
        // Handle ticket_price - always send as a number (Double)
        // For free events, send 0.0 as a Double
        // For paid events, send the price as a Double
        // JSONSerialization will handle Double correctly as a number
        if let price = ticketPrice, price > 0 {
            body["ticket_price"] = Double(price)  // Explicitly cast to Double to ensure number type
        } else {
            body["ticket_price"] = Double(0.0)  // Free event - send as Double 0.0
        }
        
        // Add capacity if provided
        if let capacity = capacity {
            body["capacity"] = capacity
        }
        
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
    
    func rsvpToEvent(eventId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/events/\(eventId)/rsvp", method: "POST")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
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
    
    func fetchUserPosts(userId: String) -> AnyPublisher<[Post], Error> {
        return request("/api/users/\(userId)/posts")
    }
    
    func updateProfile(name: String?, bio: String?, location: String?) -> AnyPublisher<User, Error> {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let bio = bio { body["bio"] = bio }
        if let location = location { body["location"] = location }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/users/profile", method: "PATCH", body: jsonData)
    }
    
    func uploadProfilePicture(image: UIImage) -> AnyPublisher<String, Error> {
        // Convert image to base64 or upload to server
        // For now, we'll use a simple approach: convert to base64 and send
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        let base64String = imageData.base64EncodedString()
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
    
    func toggleFollow(userId: String) -> AnyPublisher<Bool, Error> {
        return request("/api/users/\(userId)/follow", method: "POST")
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
        struct Response: Codable {
            let following: Bool
        }
        return request("/api/users/\(userId)/following")
            .map { (response: Response) in ["following": response.following] }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Event Promotion (for brands)
    func promoteEvent(eventId: String, expiresAt: Date? = nil, promotionBudget: Double = 0) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        
        var body: [String: Any] = [
            "promotionBudget": promotionBudget
        ]
        
        if let expiresAt = expiresAt {
            body["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt)
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return request("/api/events/\(eventId)/promote", method: "POST", body: jsonData)
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
    }
    
    func unpromoteEvent(eventId: String) -> AnyPublisher<Bool, Error> {
        struct Response: Codable {
            let success: Bool
        }
        return request("/api/events/\(eventId)/promote", method: "DELETE")
            .map { (response: Response) in response.success }
            .eraseToAnyPublisher()
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
}

