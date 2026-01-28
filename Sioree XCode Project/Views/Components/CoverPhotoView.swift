//
//  CoverPhotoView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

// Import for image caching
import Foundation

struct CoverPhotoView: View {
    let imageURL: String?
    let height: CGFloat
    
    init(imageURL: String?, height: CGFloat = 200) {
        self.imageURL = imageURL
        self.height = height
    }
    
    var body: some View {
        Group {
            if let urlString = imageURL, !urlString.isEmpty, !urlString.trimmingCharacters(in: .whitespaces).isEmpty {
                // Validate URL and create URL object
                if let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // While loading, show a very subtle background with loading indicator
                            ZStack {
                                Rectangle()
                                    .fill(Color.sioreeLightGrey.opacity(0.05))
                                    .frame(height: height)
                                ProgressView()
                                    .tint(.sioreeIcyBlue)
                                    .scaleEffect(0.8)
                            }
                    case .success(let image):
                        // CRITICAL: Show the actual image at FULL opacity - NO dimming, NO overlays
                        image
                            .resizable()
                            .renderingMode(.original) // Ensure original rendering - no tinting
                            .aspectRatio(contentMode: .fill)
                            .frame(height: height)
                            .clipped()
                            .opacity(1.0) // Explicitly ensure full opacity - never faded
                            .background(Color.clear) // Ensure no background overlay
                            .onAppear {
                                // Cache the image when it loads successfully
                                if let uiImage = image.asUIImage() {
                                    ImageCache.shared.storeImage(uiImage, for: url)
                                }
                            }
                        case .failure(_):
                            // If image fails to load, show empty space (bug state)
                            Rectangle()
                                .fill(Color.sioreeLightGrey.opacity(0.1))
                                .frame(height: height)
                        @unknown default:
                            Rectangle()
                                .fill(Color.sioreeLightGrey.opacity(0.1))
                                .frame(height: height)
                        }
                    }
                } else {
                    // Invalid URL format
                    Rectangle()
                        .fill(Color.sioreeLightGrey.opacity(0.1))
                        .frame(height: height)
                        .onAppear {
                            // Log error for debugging
                            print("⚠️ Invalid cover photo URL format: \(urlString)")
                        }
                }
            } else {
                // No cover photo URL - show empty space (bug state)
                Rectangle()
                    .fill(Color.sioreeLightGrey.opacity(0.1))
                    .frame(height: height)
            }
        }
    }
}
