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
                return "http://192.168.1.200:4000"  // Local development
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
    }
    
    // MARK: - App Info
    struct App {
        static let name = "Sioree"
        static let version = "1.0.0"
    }
    
    // MARK: - Limits
    struct Limits {
        static let maxEventImages = 10
        static let maxPostImages = 5
        static let maxBioLength = 200
        static let maxCaptionLength = 500
    }
}

