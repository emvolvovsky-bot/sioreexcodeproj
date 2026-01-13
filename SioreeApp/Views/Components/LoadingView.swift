//
//  LoadingView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.sioreeBody)
                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sioreeWhite)
    }
}

#Preview {
    LoadingView()
}

