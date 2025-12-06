//
//  SocialMediaService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import Combine
import AuthenticationServices
import UIKit

struct ConnectedSocialAccount: Identifiable, Codable {
    let id: String
    let platform: String
    let username: String
    let profileUrl: String?
    let isConnected: Bool
    let connectedAt: Date?
}

struct OAuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let userId: String
    let username: String
}

class SocialMediaService: ObservableObject {
    static let shared = SocialMediaService()
    private let networkService = NetworkService()
    
    // MARK: - Instagram OAuth
    func connectInstagram() -> AnyPublisher<ConnectedSocialAccount, Error> {
        return Future { promise in
            // Step 1: Get OAuth URL from backend
            // In production: networkService.request("/api/social/instagram/auth-url", method: "POST")
            
            // For demo, we'll simulate the OAuth flow
            // In production, you would:
            // 1. Get auth URL from your backend
            // 2. Use ASWebAuthenticationSession to open the URL
            // 3. User signs in on Instagram
            // 4. Instagram redirects back with code
            // 5. Exchange code for access token
            // 6. Save connection to backend
            
            let authURL = URL(string: "https://api.instagram.com/oauth/authorize?client_id=YOUR_CLIENT_ID&redirect_uri=YOUR_REDIRECT_URI&scope=user_profile,user_media&response_type=code")!
            
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "sioree"
            ) { callbackURL, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?
                        .first(where: { $0.name == "code" })?
                        .value else {
                    promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get authorization code"])))
                    return
                }
                
                // Exchange code for token (via backend)
                // In production: networkService.request("/api/social/instagram/exchange", method: "POST", body: code)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let account = ConnectedSocialAccount(
                        id: UUID().uuidString,
                        platform: "instagram",
                        username: "@user_instagram",
                        profileUrl: "https://instagram.com/user_instagram",
                        isConnected: true,
                        connectedAt: Date()
                    )
                    promise(.success(account))
                }
            }
            
            session.presentationContextProvider = OAuthWebAuthSession.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - TikTok OAuth
    func connectTikTok() -> AnyPublisher<ConnectedSocialAccount, Error> {
        return Future { promise in
            // Step 1: Get OAuth URL from backend
            // In production: networkService.request("/api/social/tiktok/auth-url", method: "GET")
            
            // For now, construct TikTok OAuth URL
            // In production, get this from your backend
            let clientKey = "YOUR_TIKTOK_CLIENT_KEY"
            let redirectURI = "sioree://tiktok-callback"
            let state = UUID().uuidString
            let scope = "user.info.basic"
            
            let authURLString = "https://www.tiktok.com/v2/auth/authorize/?client_key=\(clientKey)&scope=\(scope)&response_type=code&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&state=\(state)"
            
            guard let authURL = URL(string: authURLString) else {
                promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid TikTok OAuth URL"])))
                return
            }
            
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "sioree"
            ) { callbackURL, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?
                        .first(where: { $0.name == "code" })?
                        .value else {
                    promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get authorization code"])))
                    return
                }
                
                // Exchange code for token (via backend)
                // In production: networkService.request("/api/social/tiktok/exchange", method: "POST", body: ["code": code])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let account = ConnectedSocialAccount(
                        id: UUID().uuidString,
                        platform: "tiktok",
                        username: "@user_tiktok",
                        profileUrl: "https://tiktok.com/@user_tiktok",
                        isConnected: true,
                        connectedAt: Date()
                    )
                    promise(.success(account))
                }
            }
            
            session.presentationContextProvider = OAuthWebAuthSession.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - YouTube OAuth
    func connectYouTube() -> AnyPublisher<ConnectedSocialAccount, Error> {
        return Future { promise in
            // Step 1: Get OAuth URL from backend
            // In production: networkService.request("/api/social/youtube/auth-url", method: "GET")
            
            // For now, construct Google/YouTube OAuth URL
            // In production, get this from your backend
            let clientID = "YOUR_GOOGLE_CLIENT_ID"
            let redirectURI = "sioree://youtube-callback"
            let scope = "https://www.googleapis.com/auth/youtube.readonly"
            let state = UUID().uuidString
            
            let authURLString = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientID)&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&response_type=code&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&state=\(state)"
            
            guard let authURL = URL(string: authURLString) else {
                promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid YouTube OAuth URL"])))
                return
            }
            
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "sioree"
            ) { callbackURL, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?
                        .first(where: { $0.name == "code" })?
                        .value else {
                    promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get authorization code"])))
                    return
                }
                
                // Exchange code for token (via backend)
                // In production: networkService.request("/api/social/youtube/exchange", method: "POST", body: ["code": code])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let account = ConnectedSocialAccount(
                        id: UUID().uuidString,
                        platform: "youtube",
                        username: "User Channel",
                        profileUrl: "https://youtube.com/@user",
                        isConnected: true,
                        connectedAt: Date()
                    )
                    promise(.success(account))
                }
            }
            
            session.presentationContextProvider = OAuthWebAuthSession.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Spotify OAuth
    func connectSpotify() -> AnyPublisher<ConnectedSocialAccount, Error> {
        return Future { promise in
            // Step 1: Get OAuth URL from backend
            // In production: networkService.request("/api/social/spotify/auth-url", method: "GET")
            
            // For now, construct Spotify OAuth URL
            // In production, get this from your backend
            let clientID = "YOUR_SPOTIFY_CLIENT_ID"
            let redirectURI = "sioree://spotify-callback"
            let scope = "user-read-private user-read-email"
            let state = UUID().uuidString
            
            let authURLString = "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&state=\(state)"
            
            guard let authURL = URL(string: authURLString) else {
                promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Spotify OAuth URL"])))
                return
            }
            
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "sioree"
            ) { callbackURL, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?
                        .first(where: { $0.name == "code" })?
                        .value else {
                    promise(.failure(NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get authorization code"])))
                    return
                }
                
                // Exchange code for token (via backend)
                // In production: networkService.request("/api/social/spotify/exchange", method: "POST", body: ["code": code])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let account = ConnectedSocialAccount(
                        id: UUID().uuidString,
                        platform: "spotify",
                        username: "User Artist",
                        profileUrl: "https://open.spotify.com/artist/user",
                        isConnected: true,
                        connectedAt: Date()
                    )
                    promise(.success(account))
                }
            }
            
            session.presentationContextProvider = OAuthWebAuthSession.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Get Connected Accounts
    func getConnectedAccounts() -> AnyPublisher<[ConnectedSocialAccount], Error> {
        // In production: networkService.request("/api/social/accounts")
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success([]))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Disconnect Account
    func disconnectAccount(_ accountId: String) -> AnyPublisher<Bool, Error> {
        // In production: networkService.request("/api/social/accounts/\(accountId)", method: "DELETE")
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - OAuth Web Authentication
class OAuthWebAuthSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthWebAuthSession()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

