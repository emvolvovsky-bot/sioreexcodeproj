//
//  AuthService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import Combine

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct EmailCheckResponse: Codable {
    let exists: Bool
}

class AuthService {
    private let networkService = NetworkService()
    private let useMockAuth = false // ✅ Now using real backend authentication
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        if useMockAuth {
            return mockLogin(email: email, password: password)
        }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request("/api/auth/login", method: "POST", body: jsonData)
    }
    
    func signUp(email: String, password: String, username: String, name: String, userType: UserType, location: String? = nil) -> AnyPublisher<AuthResponse, Error> {
        if useMockAuth {
            return mockSignUp(email: email, password: password, username: username, name: name, userType: userType)
        }
        
        var body: [String: Any] = [
            "email": email,
            "password": password,
            "username": username,
            "name": name,
            "userType": userType.rawValue
        ]
        
        // Add location if provided (especially for talent)
        if let location = location, !location.isEmpty {
            body["location"] = location
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request("/api/auth/signup", method: "POST", body: jsonData)
    }
    
    func checkEmailExists(email: String) -> AnyPublisher<Bool, Error> {
        if useMockAuth {
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        let endpoint = "/api/auth/check-email?email=\(encodedEmail)"
        return networkService.request(endpoint)
            .map { (response: EmailCheckResponse) in response.exists }
            .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<User, Error> {
        if useMockAuth {
            return mockGetCurrentUser()
        }
        return networkService.request("/api/auth/me")
    }
    
    func logout() {
        StorageService.shared.clearAuthToken()
        StorageService.shared.clearUserId()
    }
    
    func forgotPassword(email: String) -> AnyPublisher<Bool, Error> {
        if useMockAuth {
            return mockForgotPassword(email: email)
        }
        
        let body: [String: Any] = [
            "email": email
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request("/api/auth/forgot-password", method: "POST", body: jsonData)
            .map { (_: [String: String]) in true }
            .eraseToAnyPublisher()
    }
    
    private func mockForgotPassword(email: String) -> AnyPublisher<Bool, Error> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard !email.isEmpty else {
                    promise(.failure(NetworkError.unknown))
                    return
                }
                // Mock success - in real app, this would send an email
                print("📧 Mock: Password reset email sent to \(email)")
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<Bool, Error> {
        struct DeleteResponse: Codable {
            let message: String
        }
        return networkService.request("/api/auth/delete-account", method: "DELETE")
            .map { (_: DeleteResponse) in true }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Mock Authentication (for development)
    private func mockLogin(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Validate basic requirements
                guard !email.isEmpty, !password.isEmpty else {
                    promise(.failure(NetworkError.unknown))
                    return
                }
                
                // Check if user exists in storage (for demo persistence)
                if let userId = StorageService.shared.getUserId(),
                   let userData = StorageService.shared.getData(forKey: "user_\(userId)"),
                   let user = try? JSONDecoder().decode(User.self, from: userData),
                   user.email == email {
                    print("✅ Mock login: Found existing user \(user.email)")
                    let token = UUID().uuidString
                    let response = AuthResponse(token: token, user: user)
                    promise(.success(response))
                } else {
                    // Create new user for demo (first time login)
                    print("✅ Mock login: Creating new user for \(email)")
                    let username = email.components(separatedBy: "@").first ?? "user"
                    let user = User(
                        email: email,
                        username: username,
                        name: username.capitalized,
                        userType: .partier
                    )
                    // Save user ID and user data
                    StorageService.shared.saveUserId(user.id)
                    if let userData = try? JSONEncoder().encode(user) {
                        StorageService.shared.saveData(userData, forKey: "user_\(user.id)")
                    }
                    let token = UUID().uuidString
                    let response = AuthResponse(token: token, user: user)
                    promise(.success(response))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func mockSignUp(email: String, password: String, username: String, name: String, userType: UserType) -> AnyPublisher<AuthResponse, Error> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Validate basic requirements
                guard !email.isEmpty, !password.isEmpty, !username.isEmpty, !name.isEmpty else {
                    promise(.failure(NetworkError.unknown))
                    return
                }
                
                // Create new user
                let user = User(
                    email: email,
                    username: username,
                    name: name,
                    userType: userType
                )
                
                // Save user ID and user data to storage for demo persistence
                StorageService.shared.saveUserId(user.id)
                if let userData = try? JSONEncoder().encode(user) {
                    StorageService.shared.saveData(userData, forKey: "user_\(user.id)")
                    print("✅ Mock signup: Saved user \(user.email) with ID \(user.id)")
                }
                
                let token = UUID().uuidString
                let response = AuthResponse(token: token, user: user)
                promise(.success(response))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func mockGetCurrentUser() -> AnyPublisher<User, Error> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let userId = StorageService.shared.getUserId(),
                   let userData = StorageService.shared.getData(forKey: "user_\(userId)"),
                   let user = try? JSONDecoder().decode(User.self, from: userData) {
                    promise(.success(user))
                } else {
                    promise(.failure(NetworkError.unauthorized))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}


