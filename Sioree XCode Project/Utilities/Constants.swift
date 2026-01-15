//
//  Constants.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation

struct Constants {
    // MARK: - Environment Configuration
    // Set to .production when deploying to App Store
    enum Environment {
        case development
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                // Use environment variable or fallback to localhost
                // Never hardcode IP addresses in production code
                if let devURL = ProcessInfo.processInfo.environment["DEV_API_URL"] {
                    return devURL
                }
                // Default to Render API so simulators/dev builds point at hosted backend
                return "https://sioree-api.onrender.com"
            case .production:
                return "https://sioree-api.onrender.com"  // Render deployment
            }
        }
    }
    
    // MARK: - API
    struct API {
        // Change this to .production when ready for App Store
        static let environment: Environment = .production
        
        static var baseURL: String {
            environment.baseURL
        }
        static let timeout: TimeInterval = 30 // 30 seconds timeout (increased for slower connections)
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let isOnboarded = "isOnboarded"
        static let authToken = "authToken"
        static let userId = "userId"
        static let userType = "userType"
        static let followingIdsCache = "followingIdsCache"
    }
    
    // MARK: - App Info
    struct App {
        static let name = "Sioree"
        static let version = "1.0.0"
    }
    
    // MARK: - Stripe
    struct Stripe {
        // Update these values with your Stripe Buy Button settings.
        static let publishableKey = "pk_test_51SbF9IEZUZFsipCPLKDUFgbVQpowjxWafVJjHZBR9TihnyFHSsZ5yA93lrz4krTsQNNttqwBIrDW0MLKcYDMiD6q00Db2qsWKJ"
        static let buyButtonId = "{{BUY_BUTTON_ID}}"
    }

    // MARK: - Limits
    struct Limits {
        static let maxEventImages = 10
        static let maxPostImages = 5
        static let maxBioLength = 200
        static let maxCaptionLength = 500
    }
}

