//
//  ImageCache.swift
//  Sioree
//
//  Created by Sioree Team
//

import UIKit
import SwiftUI

class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        cache.countLimit = 100 // Maximum number of images to cache in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")

        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func getImage(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString

        // Check memory cache first
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Store in memory cache for faster future access
            cache.setObject(image, forKey: key)
            return image
        }

        return nil
    }

    func storeImage(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString

        // Store in memory cache
        cache.setObject(image, forKey: key)

        // Store on disk (in background to avoid blocking UI)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            let fileURL = self.cacheDirectory.appendingPathComponent(key.hash.description)
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL)
            }
        }
    }

    func clearCache() {
        cache.removeAllObjects()

        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// Cached Async Image View
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content

    @State private var currentPhase: AsyncImagePhase = .empty
    @State private var cachedImage: UIImage?

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                content(.success(Image(uiImage: cachedImage)))
            } else {
                AsyncImage(url: url) { phase in
                    content(phase)
                }
                .onAppear {
                    loadCachedImage()
                }
            }
        }
    }

    private func loadCachedImage() {
        guard let url = url else { return }

        if let cachedImage = ImageCache.shared.getImage(for: url) {
            self.cachedImage = cachedImage
        }
    }
}

// Convenience initializer for simple image display
extension CachedAsyncImage where Content == Image {
    init(url: URL?) where Content == Image {
        self.init(url: url) { phase -> Image in
            switch phase {
            case .empty:
                return Image(systemName: "photo")
            case .success(let image):
                return image
            case .failure:
                return Image(systemName: "photo")
            @unknown default:
                return Image(systemName: "photo")
            }
        }
    }
}

// Helper extension to convert SwiftUI Image to UIImage
extension Image {
    @MainActor
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        guard let view = controller.view else { return nil }

        let targetSize = view.intrinsicContentSize
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}