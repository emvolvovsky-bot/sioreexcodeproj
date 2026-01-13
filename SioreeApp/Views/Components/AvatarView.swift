//
//  AvatarView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

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
    let size: AvatarSize
    var showBorder: Bool = false
    
    var body: some View {
        Group {
            if let imageURL = imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(showBorder ? Color.sioreeIcyBlue : Color.clear, lineWidth: 2)
        )
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

