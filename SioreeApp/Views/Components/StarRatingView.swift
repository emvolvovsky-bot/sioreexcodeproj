//
//  StarRatingView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct StarRatingView: View {
    let rating: Int
    let maxRating: Int
    let starSize: CGFloat
    let isEditable: Bool
    @Binding var selectedRating: Int?
    
    init(rating: Int, maxRating: Int = 5, starSize: CGFloat = 20, isEditable: Bool = false, selectedRating: Binding<Int?> = .constant(nil)) {
        self.rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.isEditable = isEditable
        self._selectedRating = selectedRating
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: starSize))
                    .foregroundColor(starColor(for: index))
                    .onTapGesture {
                        if isEditable {
                            selectedRating = index
                        }
                    }
            }
        }
    }
    
    private func starImageName(for index: Int) -> String {
        let displayRating = selectedRating ?? rating
        return index <= displayRating ? "star.fill" : "star"
    }
    
    private func starColor(for index: Int) -> Color {
        let displayRating = selectedRating ?? rating
        return index <= displayRating ? Color.sioreeWarmGlow : Color.sioreeLightGrey.opacity(0.5)
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 4)
        StarRatingView(rating: 5, starSize: 30)
        StarRatingView(rating: 3, isEditable: true, selectedRating: .constant(4))
    }
    .padding()
}

