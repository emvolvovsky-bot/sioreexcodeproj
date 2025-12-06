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
        
        // Check cache first
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map { data, _ in UIImage(data: data) }
            .handleEvents(receiveOutput: { [weak self] image in
                if let image = image {
                    self?.cache.setObject(image, forKey: urlString as NSString)
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

