//
//  AuthViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        if let token = StorageService.shared.getAuthToken(), !token.isEmpty {
            // Validate token and fetch user
            fetchCurrentUser()
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Login failed: \(error)")
                        print("❌ Error type: \(type(of: error))")
                        
                        // Better error messages
                        if let urlError = error as? URLError {
                            switch urlError.code {
                            case .notConnectedToInternet:
                                self?.errorMessage = "No internet connection. Please check your network."
                            case .cannotConnectToHost:
                                self?.errorMessage = "Cannot connect to server. Make sure backend is running at \(Constants.API.baseURL)"
                            case .timedOut:
                                self?.errorMessage = "Connection timeout. Backend server is not responding."
                            default:
                                self?.errorMessage = "Login failed: \(error.localizedDescription)"
                            }
                        } else if let networkError = error as? NetworkError {
                            self?.errorMessage = networkError.errorDescription ?? "Login failed"
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ Login successful - saving token and user data")
                    StorageService.shared.saveAuthToken(response.token)
                    StorageService.shared.saveUserId(response.user.id)
                    StorageService.shared.saveUserType(response.user.userType)
                    self?.currentUser = response.user
                    self?.isAuthenticated = true
                    print("✅ isAuthenticated set to: \(self?.isAuthenticated ?? false)")
                    print("✅ Current user: \(response.user.email ?? "unknown")")
                    // Send push notification for login
                    NotificationService.shared.notifyLogin(userName: response.user.name)
                    // Don't call fetchCurrentUser immediately - use the user data from login response
                    // fetchCurrentUser can be called later if needed, but won't block login
                }
            )
            .store(in: &cancellables)
    }
    
    func signUp(email: String, password: String, username: String, name: String, userType: UserType, location: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        authService.signUp(email: email, password: password, username: username, name: name, userType: userType, location: location)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Sign up failed: \(error)")
                        print("❌ Error type: \(type(of: error))")
                        
                        // Better error messages
                        if let urlError = error as? URLError {
                            switch urlError.code {
                            case .notConnectedToInternet:
                                self?.errorMessage = "No internet connection. Please check your network."
                            case .cannotConnectToHost:
                                self?.errorMessage = "Cannot connect to server. Make sure backend is running at \(Constants.API.baseURL)"
                            case .timedOut:
                                self?.errorMessage = "Connection timeout. Backend server is not responding."
                            default:
                                self?.errorMessage = "Sign up failed: \(error.localizedDescription)"
                            }
                        } else if let networkError = error as? NetworkError {
                            self?.errorMessage = networkError.errorDescription ?? "Sign up failed"
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ Sign up successful - saving token and user data")
                    StorageService.shared.saveAuthToken(response.token)
                    StorageService.shared.saveUserId(response.user.id)
                    StorageService.shared.saveUserType(response.user.userType)
                    if response.user.userType == .host || response.user.userType == .talent {
                        StorageService.shared.setNeedsBankConnect(true)
                    }
                    self?.currentUser = response.user
                    self?.isAuthenticated = true
                    print("✅ isAuthenticated set to: \(self?.isAuthenticated ?? false)")
                    print("✅ Current user: \(response.user.email ?? "unknown")")
                    // Send push notification for signup
                    NotificationService.shared.notifySignup(userName: response.user.name)
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        StorageService.shared.clearAuthToken()
        StorageService.shared.clearUserId()
        StorageService.shared.clearUserType()
        currentUser = nil
        isAuthenticated = false
    }
    
    func fetchCurrentUser() {
        authService.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    // If fetch fails, don't reset authentication - user might still be logged in
                    if case .failure(let error) = completion {
                        print("⚠️ Failed to fetch current user: \(error.localizedDescription)")
                        print("⚠️ But keeping user authenticated with existing data")
                        // Don't reset isAuthenticated - keep user logged in with existing data
                        // The login response already provided user data
                    }
                },
                receiveValue: { [weak self] user in
                    print("✅ Fetched current user: \(user.email ?? "unknown")")
                    self?.currentUser = user
                    StorageService.shared.saveUserType(user.userType)
                    self?.isAuthenticated = true
                    print("✅ isAuthenticated after fetch: \(self?.isAuthenticated ?? false)")
                }
            )
            .store(in: &cancellables)
    }
}

