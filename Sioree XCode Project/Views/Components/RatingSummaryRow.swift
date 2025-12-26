//
//  RatingSummaryRow.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct RatingSummaryRow: View {
    let title: String
    let averageRating: Double?
    let reviewCount: Int
    let ctaTitle: String?
    let onCTATap: (() -> Void)?
    let onSeeAll: (() -> Void)?
    
    init(
        title: String,
        averageRating: Double?,
        reviewCount: Int,
        ctaTitle: String? = nil,
        onCTATap: (() -> Void)? = nil,
        onSeeAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.averageRating = averageRating
        self.reviewCount = reviewCount
        self.ctaTitle = ctaTitle
        self.onCTATap = onCTATap
        self.onSeeAll = onSeeAll
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(reviewCount > 0 ? .sioreeWarmGlow : .sioreeLightGrey.opacity(0.6))
                        if let averageRating = averageRating, reviewCount > 0 {
                            Text(String(format: "%.1f", averageRating))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.sioreeWhite)
                            Text("(\(reviewCount) \(reviewCount == 1 ? "review" : "reviews"))")
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                        } else {
                            Text("No ratings yet")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                }
                
                Spacer()
                
                if let onSeeAll = onSeeAll {
                    Button(action: onSeeAll) {
                        Text("See reviews")
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            
            if let ctaTitle = ctaTitle, let onCTATap = onCTATap {
                Button(action: onCTATap) {
                    HStack {
                        Image(systemName: "pencil")
                        Text(ctaTitle)
                    }
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeWhite)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.sioreeIcyBlue.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.25), lineWidth: 1)
        )
    }
}


















