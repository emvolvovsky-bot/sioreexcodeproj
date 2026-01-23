//
//  LoadingView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct LoadingView: View {
    var useDarkBackground: Bool = true

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            LogoView(size: .large, isSpinning: true)

            Text("Loading...")
                .font(.sioreeBody)
                .foregroundColor(useDarkBackground ? Color.sioreeLightGrey.opacity(0.6) : Color.sioreeCharcoal.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(useDarkBackground ? Color.clear : Color.sioreeWhite)
    }
}

#Preview {
    LoadingView()
}

