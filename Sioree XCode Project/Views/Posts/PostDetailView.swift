//
//  PostDetailView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // Post images
                if !post.images.isEmpty {
                    TabView {
                        ForEach(post.images, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(.sioreeIcyBlue)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.sioreeLightGrey)
                                @unknown default:
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.sioreeLightGrey)
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 400)
                }
                
                // Post info
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    // User info
                    HStack {
                        AvatarView(imageURL: post.userAvatar, size: .small)
                        Text(post.userName)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                        Spacer()
                    }
                    
                    // Caption
                    if let caption = post.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                    }
                    
                    // Engagement
                    HStack(spacing: Theme.Spacing.l) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.sioreeIcyBlue)
                            Text("\(post.likes)")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "message.fill")
                                .foregroundColor(.sioreeIcyBlue)
                            Text("\(post.comments)")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                }
                .padding(Theme.Spacing.m)
            }
        }
        .background(Color.sioreeBlack)
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            post: Post(
                id: "1",
                userId: "user1",
                userName: "Test User",
                userAvatar: nil,
                images: [],
                caption: "Test post caption",
                likes: 10,
                comments: 5,
                isLiked: false,
                createdAt: Date()
            )
        )
    }
}

