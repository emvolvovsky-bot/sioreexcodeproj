//
//  LogoView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

enum LogoSize {
    case small
    case medium
    case large
    case extraLarge
    
    var dimension: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 100
        case .large: return 150
        case .extraLarge: return 360
        }
    }
}

struct LogoView: View {
    let size: LogoSize
    var isSpinning: Bool = false
    
    var body: some View {
        Image("Logo256x256")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.dimension, height: size.dimension)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(isSpinning ? Animation.linear(duration: 2.0).repeatForever(autoreverses: false) : .default, value: isSpinning)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.m) {
        LogoView(size: .small)
        LogoView(size: .medium)
        LogoView(size: .large)
    }
    .padding()
}

