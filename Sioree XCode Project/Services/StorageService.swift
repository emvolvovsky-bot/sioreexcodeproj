//
//  StorageService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

class StorageService {
    static let shared = StorageService()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Auth Token
    func saveAuthToken(_ token: String) {
        userDefaults.set(token, forKey: Constants.UserDefaultsKeys.authToken)
    }
    
    func getAuthToken() -> String? {
        return userDefaults.string(forKey: Constants.UserDefaultsKeys.authToken)
    }
    
    func clearAuthToken() {
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.authToken)
    }
    
    // MARK: - User ID
    func saveUserId(_ userId: String) {
        userDefaults.set(userId, forKey: Constants.UserDefaultsKeys.userId)
    }
    
    func getUserId() -> String? {
        return userDefaults.string(forKey: Constants.UserDefaultsKeys.userId)
    }
    
    func clearUserId() {
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.userId)
    }
    
    // MARK: - Onboarding
    func setOnboarded(_ isOnboarded: Bool) {
        userDefaults.set(isOnboarded, forKey: Constants.UserDefaultsKeys.isOnboarded)
    }
    
    func isOnboarded() -> Bool {
        return userDefaults.bool(forKey: Constants.UserDefaultsKeys.isOnboarded)
    }
    
    // MARK: - Recent Searches
    func saveRecentSearches(_ searches: [String]) {
        userDefaults.set(searches, forKey: "recentSearches")
    }
    
    func getRecentSearches() -> [String] {
        return userDefaults.stringArray(forKey: "recentSearches") ?? []
    }
    
    // MARK: - User Type
    func saveUserType(_ userType: UserType) {
        userDefaults.set(userType.rawValue, forKey: Constants.UserDefaultsKeys.userType)
    }
    
    func getUserType() -> UserType? {
        guard let rawValue = userDefaults.string(forKey: Constants.UserDefaultsKeys.userType) else {
            return nil
        }
        return UserType(rawValue: rawValue)
    }
    
    // MARK: - Generic Data Storage
    func saveData(_ data: Data, forKey key: String) {
        userDefaults.set(data, forKey: key)
    }
    
    func getData(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }
}

