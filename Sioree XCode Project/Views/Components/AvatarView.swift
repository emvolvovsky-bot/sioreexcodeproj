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
    let size: AvatarSize
    var showBorder: Bool = false
    
    // Provide explicit initializers to support both old and new call sites.
    init(imageURL: String?, userId: String? = nil, size: AvatarSize, showBorder: Bool = false) {
        self.imageURL = imageURL
        self.userId = userId
        self.size = size
        self.showBorder = showBorder
    }

    init(imageURL: String?, size: AvatarSize, showBorder: Bool = false) {
        self.imageURL = imageURL
        self.userId = nil
        self.size = size
        self.showBorder = showBorder
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
            if let img = ImageCache.shared.getAvatarImage(for: userId) {
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
            
            Group {
                // Render a previously-loaded image if present
                if let loaded = loadedImage {
                    Image(uiImage: loaded)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let userId = userId {
                    // Attempt to load cached avatar off-main thread once
                    placeholderView
                        .onAppear {
                            loadLocalAvatarIfNeeded(userId: userId)
                        }
                } else if let imageURL = imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                            .onAppear {
                                    // Convert to UIImage on main, then persist in background
                                    Task { @MainActor in
                                        if let uiImage = image.asUIImage() {
                                            // show immediately
                                            self.loadedImage = uiImage
                                            DispatchQueue.global(qos: .background).async {
                                                if let data = uiImage.jpegData(compressionQuality: 0.9) {
                                                    ImageCache.shared.storeImage(uiImage, for: url)
                                                    if let uid = userId {
                                                        ImageCache.shared.storeAvatarData(data, for: uid)
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
                } else {
                    placeholderView
                }
            }
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

