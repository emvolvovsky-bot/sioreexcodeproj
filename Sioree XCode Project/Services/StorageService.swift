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
    
    func clearUserType() {
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.userType)
    }

    // MARK: - Bank Connect Prompt
    func setNeedsBankConnect(_ needsConnect: Bool) {
        userDefaults.set(needsConnect, forKey: Constants.UserDefaultsKeys.needsBankConnect)
    }

    func needsBankConnect() -> Bool {
        return userDefaults.bool(forKey: Constants.UserDefaultsKeys.needsBankConnect)
    }

    func clearNeedsBankConnect() {
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.needsBankConnect)
    }

    // MARK: - Following Cache
    func saveFollowingIds(_ ids: [String]) {
        userDefaults.set(ids, forKey: Constants.UserDefaultsKeys.followingIdsCache)
    }
    
    func getFollowingIds() -> [String] {
        return userDefaults.stringArray(forKey: Constants.UserDefaultsKeys.followingIdsCache) ?? []
    }
    
    func addFollowingId(_ id: String) {
        var ids = Set(getFollowingIds())
        ids.insert(id)
        saveFollowingIds(Array(ids))
    }
    
    func removeFollowingId(_ id: String) {
        var ids = Set(getFollowingIds())
        ids.remove(id)
        saveFollowingIds(Array(ids))
    }
    
    // MARK: - Generic Data Storage
    func saveData(_ data: Data, forKey key: String) {
        userDefaults.set(data, forKey: key)
    }
    
    func getData(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }

    // MARK: - Local Followers/Following Cache Keys
    private func localFollowersKey(forUserId userId: String) -> String {
        return "localFollowers:\(userId)"
    }

    private func localFollowingKey(forUserId userId: String) -> String {
        return "localFollowing:\(userId)"
    }

    // MARK: - Local Followers/Following Counts
    private func localFollowerCountKey(forUserId userId: String) -> String {
        return "localFollowerCount:\(userId)"
    }

    private func localFollowingCountKey(forUserId userId: String) -> String {
        return "localFollowingCount:\(userId)"
    }

    func saveFollowerCount(_ count: Int, forUserId userId: String) {
        userDefaults.set(count, forKey: localFollowerCountKey(forUserId: userId))
    }

    func getFollowerCount(forUserId userId: String) -> Int? {
        let key = localFollowerCountKey(forUserId: userId)
        guard userDefaults.object(forKey: key) != nil else { return nil }
        return userDefaults.integer(forKey: key)
    }

    func saveFollowingCount(_ count: Int, forUserId userId: String) {
        userDefaults.set(count, forKey: localFollowingCountKey(forUserId: userId))
    }

    func getFollowingCount(forUserId userId: String) -> Int? {
        let key = localFollowingCountKey(forUserId: userId)
        guard userDefaults.object(forKey: key) != nil else { return nil }
        return userDefaults.integer(forKey: key)
    }

    // MARK: - Save / Retrieve User Lists
    func saveUserList(_ users: [User], forUserId userId: String, listType: UserListType) {
        do {
            let data = try JSONEncoder().encode(users)
            let key = listType == .followers ? localFollowersKey(forUserId: userId) : localFollowingKey(forUserId: userId)
            saveData(data, forKey: key)
        } catch {
            print("❌ StorageService.saveUserList encode error: \(error)")
        }
    }

    func getUserList(forUserId userId: String, listType: UserListType) -> [User] {
        let key = listType == .followers ? localFollowersKey(forUserId: userId) : localFollowingKey(forUserId: userId)
        guard let data = getData(forKey: key) else { return [] }
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            return users
        } catch {
            print("❌ StorageService.getUserList decode error: \(error)")
            return []
        }
    }

    // MARK: - Local Events Cache
    private func localEventsKey(forUserId userId: String) -> String {
        return "localEvents:\(userId)"
    }

    private func localEventKey(forEventId eventId: String) -> String {
        return "localEvent:\(eventId)"
    }

    /// Save an array of events that belong to a given user (host).
    func saveLocalEvents(_ events: [Event], forUserId userId: String) {
        do {
            let data = try JSONEncoder().encode(events)
            saveData(data, forKey: localEventsKey(forUserId: userId))
            // Also update individual event entries for quick lookup
            for event in events {
                let ed = try JSONEncoder().encode(event)
                saveData(ed, forKey: localEventKey(forEventId: event.id))
            }
        } catch {
            print("❌ StorageService.saveLocalEvents encode error: \(error)")
        }
    }

    /// Retrieve locally cached events for a given user (host).
    func getLocalEvents(forUserId userId: String) -> [Event] {
        guard let data = getData(forKey: localEventsKey(forUserId: userId)) else { return [] }
        do {
            let events = try JSONDecoder().decode([Event].self, from: data)
            return events
        } catch {
            print("❌ StorageService.getLocalEvents decode error: \(error)")
            return []
        }
    }

    /// Save or update a single event in the local cache (adds to host's list and individual key).
    func saveLocalEvent(_ event: Event) {
        let owner = event.hostId
        var existing = getLocalEvents(forUserId: owner)
        if let idx = existing.firstIndex(where: { $0.id == event.id }) {
            existing[idx] = event
        } else {
            existing.insert(event, at: 0)
        }
        saveLocalEvents(existing, forUserId: owner)
        // Also store by id for quick lookup
        do {
            let ed = try JSONEncoder().encode(event)
            saveData(ed, forKey: localEventKey(forEventId: event.id))
        } catch {
            print("❌ StorageService.saveLocalEvent encode error: \(error)")
        }
    }

    /// Retrieve a single cached event by id.
    func getLocalEvent(eventId: String) -> Event? {
        guard let data = getData(forKey: localEventKey(forEventId: eventId)) else { return nil }
        do {
            let event = try JSONDecoder().decode(Event.self, from: data)
            return event
        } catch {
            print("❌ StorageService.getLocalEvent decode error: \(error)")
            return nil
        }
    }

    // MARK: - Saved / Favorite Events Cache
    private func savedEventsKey(forUserId userId: String) -> String {
        return "savedEvents:\(userId)"
    }

    /// Permanently cache saved events for the given user.
    func saveSavedEvents(_ events: [Event], forUserId userId: String) {
        do {
            let data = try JSONEncoder().encode(events)
            saveData(data, forKey: savedEventsKey(forUserId: userId))
        } catch {
            print("❌ StorageService.saveSavedEvents encode error: \(error)")
        }
    }

    /// Retrieve cached saved events for the given user.
    func getSavedEvents(forUserId userId: String) -> [Event] {
        guard let data = getData(forKey: savedEventsKey(forUserId: userId)) else { return [] }
        do {
            let events = try JSONDecoder().decode([Event].self, from: data)
            return events
        } catch {
            print("❌ StorageService.getSavedEvents decode error: \(error)")
            return []
        }
    }
}

