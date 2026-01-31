//
//  ImageService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class ImageService {
    static let shared = ImageService()
    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
        self.session = URLSession(configuration: config)
    }
    
    func loadImage(from urlString: String) -> AnyPublisher<UIImage?, Never> {
        guard let url = URL(string: urlString) else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        // Check persistent disk cache first (ImageCache)
        if let persistent = ImageCache.shared.getImage(for: url) {
            return Just(persistent).eraseToAnyPublisher()
        }

        // Check in-memory NSCache
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map { data, _ in UIImage(data: data) }
            .handleEvents(receiveOutput: { [weak self] image in
                if let image = image {
                    self?.cache.setObject(image, forKey: urlString as NSString)
                    // Persist to disk cache for future launches
                    ImageCache.shared.storeImage(image, for: url)
                }
            })
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func uploadImage(_ image: UIImage) -> AnyPublisher<String, Error> {
        // This would integrate with your image upload service
        // For now, returning a mock URL
        return Just("https://example.com/image.jpg")
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension ImageService {
    // Return a local avatar file URL if present for userId
    func localAvatarPath(for userId: String) -> URL? {
        // Try versioned file first if we have stored version metadata
        let version = StorageService.shared.getAvatarVersion(forUserId: userId)
        let fileURL = ImageCache.shared.avatarFileURL(for: userId, version: version)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        // Fallback to non-versioned avatar
        let fallback = ImageCache.shared.avatarFileURL(for: userId, version: nil)
        if FileManager.default.fileExists(atPath: fallback.path) {
            return fallback
        }
        return nil
    }
    
    // Save avatar bytes (e.g., base64 decoded) to disk cache and return URL
    func saveAvatarData(_ data: Data, for userId: String, version: String? = nil) -> URL? {
        ImageCache.shared.storeAvatarData(data, for: userId, version: version)
        let fileURL = ImageCache.shared.avatarFileURL(for: userId, version: version)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}

