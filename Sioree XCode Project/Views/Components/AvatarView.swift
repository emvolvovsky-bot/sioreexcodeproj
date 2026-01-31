//
//  AvatarView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import UIKit

enum AvatarSize {
    case small
    case medium
    case large
    
    var dimension: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 100
        }
    }
}

struct AvatarView: View {
    let imageURL: String?
    let userId: String?
    let avatarVersion: String?
    let size: AvatarSize
    var showBorder: Bool = false
    
    // Provide explicit initializers to support both old and new call sites.
    init(imageURL: String?, userId: String? = nil, size: AvatarSize, showBorder: Bool = false, avatarVersion: String? = nil) {
        self.imageURL = imageURL
        self.userId = userId
        self.size = size
        self.showBorder = showBorder
        self.avatarVersion = avatarVersion
    }

    init(imageURL: String?, size: AvatarSize, showBorder: Bool = false) {
        self.imageURL = imageURL
        self.userId = nil
        self.size = size
        self.showBorder = showBorder
        self.avatarVersion = nil
    }
    
    private let borderWidth: CGFloat = 2
    private let borderGap: CGFloat = 2
    
    private var innerDiameter: CGFloat {
        guard showBorder else { return size.dimension }
        return size.dimension - borderWidth - (borderGap * 2)
    }
    
    private var ringDiameter: CGFloat {
        size.dimension - borderWidth
    }
    
    @State private var loadedImage: UIImage? = nil

    private func loadLocalAvatarIfNeeded(userId: String) {
        // If already loaded or image exists in memory cache, skip
        if loadedImage != nil { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let img = ImageCache.shared.getAvatarImage(for: userId, version: self.avatarVersion ?? StorageService.shared.getAvatarVersion(forUserId: userId)) {
                DispatchQueue.main.async {
                    self.loadedImage = img
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(showBorder ? Color.sioreeIcyBlue : Color.clear, lineWidth: borderWidth)
                .frame(width: size.dimension, height: size.dimension)
            
            if showBorder {
                Circle()
                    .fill(Color.sioreeBlack)
                    .frame(width: ringDiameter, height: ringDiameter)
            }
            
            // Build a single-typed content view to avoid SwiftUI generic inference issues
            var content: AnyView {
                if let loaded = loadedImage {
                    return AnyView(
                        Image(uiImage: loaded)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                }

                if let userId = userId {
                    return AnyView(
                        placeholderView
                            .onAppear {
                                loadLocalAvatarIfNeeded(userId: userId)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: .avatarUpdated)) { note in
                                guard let info = note.userInfo, let updatedUserId = info["userId"] as? String, updatedUserId == userId else { return }
                                loadLocalAvatarIfNeeded(userId: userId)
                            }
                    )
                }

                if let imageURL = imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                    // Append version query parameter if provided to ensure cache-busting when needed
                    var finalURL = url
                    if let uid = userId {
                        let version = avatarVersion ?? StorageService.shared.getAvatarVersion(forUserId: uid)
                        if let v = version, !v.isEmpty, var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                            var query = comps.queryItems ?? []
                            query.append(URLQueryItem(name: "v", value: v))
                            comps.queryItems = query
                            if let u = comps.url { finalURL = u }
                        }
                    }

                    return AnyView(
                        CachedAsyncImage(url: finalURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .onAppear {
                                        Task { @MainActor in
                                            if let uiImage = image.asUIImage() {
                                                self.loadedImage = uiImage
                                                DispatchQueue.global(qos: .background).async {
                                                    if let data = uiImage.jpegData(compressionQuality: 0.9) {
                                                        ImageCache.shared.storeImage(uiImage, for: finalURL)
                                                        if let uid = userId {
                                                            ImageCache.shared.storeAvatarData(data, for: uid, version: self.avatarVersion ?? StorageService.shared.getAvatarVersion(forUserId: uid))
                                                            if let v = self.avatarVersion {
                                                                StorageService.shared.saveAvatarVersion(v, forUserId: uid)
                                                                StorageService.shared.saveLastAvatarCheckAt(Date(), forUserId: uid)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                            default:
                                placeholderView
                            }
                        }
                    )
                }

                return AnyView(placeholderView)
            }

            content
                .frame(width: innerDiameter, height: innerDiameter)
                .clipShape(Circle())
        }
        .frame(width: size.dimension, height: size.dimension)
    }
    
    private var placeholderView: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(Color.sioreeLightGrey)
    }
}

#Preview {
    HStack(spacing: Theme.Spacing.m) {
        AvatarView(imageURL: nil, size: .small)
        AvatarView(imageURL: nil, size: .medium, showBorder: true)
        AvatarView(imageURL: nil, size: .large)
    }
    .padding()
}

