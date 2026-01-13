//
//  ReviewCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Reviewer Info
            HStack(spacing: Theme.Spacing.s) {
                AvatarView(imageURL: review.reviewerAvatar, size: .small)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.sioreeCharcoal)
                    
                    Text("@\(review.reviewerUsername)")
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                }
                
                Spacer()
                
                // Rating
                StarRatingView(rating: review.rating, starSize: 14)
            }
            
            // Comment
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeCharcoal.opacity(0.8))
                    .lineSpacing(4)
            }
            
            // Date
            Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.sioreeCaption)
                .foregroundColor(Color.sioreeCharcoal.opacity(0.5))
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeWhite.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

#Preview {
    ReviewCard(
        review: Review(
            id: "1",
            reviewerId: "r1",
            reviewerName: "John Doe",
            reviewerUsername: "johndoe",
            reviewerAvatar: nil,
            reviewedUserId: "u1",
            rating: 5,
            comment: "Amazing host! The event was fantastic and everything was well organized.",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    .padding()
    .background(Color.sioreeBlack)
}

