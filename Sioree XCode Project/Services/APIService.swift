//
//  APIService.swift
//  Sioree XCode Project
//
//  Created by Emil Volvovsky on 12/5/25.
//

import Foundation

class APIService {

    static let shared = APIService()

    // Use centralized base URL from Constants
    private let baseURL = Constants.API.baseURL

    // MARK: - Generic Request Function

    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {

        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.API.timeout

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(http.statusCode) else {
                print("❌ HTTP Error: \(http.statusCode) for \(url.absoluteString)")
                throw URLError(.badServerResponse)
            }

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as URLError {
            print("❌ Network Error: \(error.localizedDescription) for \(url.absoluteString)")
            throw error
        } catch {
            print("❌ Decode Error: \(error.localizedDescription)")
            throw error
        }
    }
}
