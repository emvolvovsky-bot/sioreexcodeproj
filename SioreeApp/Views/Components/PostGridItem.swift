//
//  PostGridItem.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PostGridItem: View {
    let post: Post
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.sioreeLightGrey.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
            
            if let firstImage = post.images.first, !firstImage.isEmpty {
                AsyncImage(url: URL(string: firstImage)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.sioreeIcyBlue)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    @unknown default:
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.sioreeLightGrey.opacity(0.5))
            }
            
            // Show multiple images indicator
            if post.images.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "square.on.square")
                                .font(.system(size: 12))
                            Text("\(post.images.count)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.sioreeWhite)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    PostGridItem(
        post: Post(
            id: "1",
            userId: "user1",
            userName: "Test User",
            userAvatar: nil,
            images: [],
            caption: "Test post",
            likes: 0,
            comments: 0,
            isLiked: false,
            createdAt: Date()
        )
    )
    .frame(width: 100, height: 100)
}

