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
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024 // 200MB

    private init() {
        cache.countLimit = 100 // Maximum number of images to cache in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")

        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        // Create avatars subdirectory
        try? fileManager.createDirectory(at: cacheDirectory.appendingPathComponent("avatars"), withIntermediateDirectories: true)
        // Enforce disk cache size limit
        enforceDiskCacheLimit()
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

    // Avatar helpers - store avatar by userId + version for deterministic lookup.
    // Filenames: avatars/<userId>_v<version>.jpg
    func avatarFileURL(for userId: String, version: String?) -> URL {
        let avatarsDir = cacheDirectory.appendingPathComponent("avatars")
        if let v = version, !v.isEmpty {
            let safe = "\(userId)_v\(v).jpg"
            return avatarsDir.appendingPathComponent(safe)
        } else {
            return avatarsDir.appendingPathComponent("\(userId).jpg")
        }
    }

    func storeAvatarData(_ data: Data, for userId: String, version: String?) {
        let fileURL = avatarFileURL(for: userId, version: version)
        DispatchQueue.global(qos: .background).async {
            try? data.write(to: fileURL)
            if let image = UIImage(data: data) {
                let key = fileURL.absoluteString as NSString
                self.cache.setObject(image, forKey: key)
                // Notify UI that avatar updated for this user so views can reload
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .avatarUpdated, object: nil, userInfo: ["userId": userId, "version": version ?? ""])
                }
            }
        }
    }

    func getAvatarImage(for userId: String, version: String?) -> UIImage? {
        // Try versioned file first
        let fileURL = avatarFileURL(for: userId, version: version)
        let key = fileURL.absoluteString as NSString
        if let img = cache.object(forKey: key) {
            return img
        }
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            cache.setObject(image, forKey: key)
            return image
        }

        // Fallback to non-versioned avatar file
        if version != nil {
            let fallbackURL = avatarFileURL(for: userId, version: nil)
            let fallbackKey = fallbackURL.absoluteString as NSString
            if let img = cache.object(forKey: fallbackKey) {
                return img
            }
            if let data = try? Data(contentsOf: fallbackURL), let image = UIImage(data: data) {
                cache.setObject(image, forKey: fallbackKey)
                return image
            }
        }

        return nil
    }

    func clearCache() {
        cache.removeAllObjects()

        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: cacheDirectory.appendingPathComponent("avatars"), withIntermediateDirectories: true)
    }

    private func enforceDiskCacheLimit() {
        DispatchQueue.global(qos: .background).async {
            let folderURL = self.cacheDirectory
            guard let files = try? self.fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles) else { return }
            // Compute total size
            var fileInfos: [(url: URL, size: Int, date: Date)] = []
            var totalSize = 0
            for url in files {
                if let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                   let size = attrs.fileSize,
                   let date = attrs.contentModificationDate {
                    fileInfos.append((url: url, size: size, date: date))
                    totalSize += size
                }
            }
            if totalSize <= self.maxDiskCacheSize { return }
            // Sort by oldest first
            fileInfos.sort { $0.date < $1.date }
            var bytesToFree = totalSize - self.maxDiskCacheSize
            for info in fileInfos {
                guard bytesToFree > 0 else { break }
                try? self.fileManager.removeItem(at: info.url)
                bytesToFree -= info.size
            }
        }
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
        DispatchQueue.global(qos: .userInitiated).async {
            if let cachedImage = ImageCache.shared.getImage(for: url) {
                DispatchQueue.main.async {
                    self.cachedImage = cachedImage
                }
            }
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
    func asUIImage(maxDimension: CGFloat = 2048) -> UIImage? {
        // Helper that performs all UIKit/view work on the main thread synchronously.
        func renderOnMain() -> UIImage? {
            let controller = UIHostingController(rootView: self)
            guard let view = controller.view else { return nil }

            // Ensure the view has a chance to layout its content
            view.setNeedsLayout()
            view.layoutIfNeeded()

            // Start with intrinsic content size but fall back if it's invalid
            var targetSize = view.intrinsicContentSize
            if targetSize.width <= 0 || targetSize.height <= 0 {
                targetSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                if targetSize.width <= 0 || targetSize.height <= 0 {
                    // Last resort: small default size to avoid huge allocations
                    targetSize = CGSize(width: 100, height: 100)
                }
            }

            // Cap logical dimensions to avoid excessive memory use
            let cappedWidth = min(maxDimension, max(1, targetSize.width))
            let cappedHeight = min(maxDimension, max(1, targetSize.height))
            var cappedSize = CGSize(width: cappedWidth, height: cappedHeight)

            // Also ensure pixel dimensions aren't astronomical (consider screen scale)
            let scale = UIScreen.main.scale
            let maxPixelDim: CGFloat = 8192 // conservative maximum per-dimension in pixels
            let pixelWidth = cappedSize.width * scale
            let pixelHeight = cappedSize.height * scale
            if pixelWidth > maxPixelDim || pixelHeight > maxPixelDim {
                let factor = min(maxPixelDim / pixelWidth, maxPixelDim / pixelHeight)
                cappedSize = CGSize(width: cappedSize.width * factor, height: cappedSize.height * factor)
            }

            view.bounds = CGRect(origin: .zero, size: cappedSize)
            view.backgroundColor = .clear

            let renderer = UIGraphicsImageRenderer(size: cappedSize)
            return renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
        }

        if Thread.isMainThread {
            return renderOnMain()
        } else {
            var image: UIImage?
            DispatchQueue.main.sync {
                image = renderOnMain()
            }
            return image
        }
    }
}

// Notification names for avatar updates
extension Notification.Name {
    static let avatarUpdated = Notification.Name("AvatarUpdatedNotification")
}