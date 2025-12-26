//
//  BrandEventsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BrandEventsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.l) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.sioreeIcyBlue)
                    
                    Text("Create and manage events coming soon")
                        .font(.sioreeH4)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.sioreeWhite)
                        .padding(.horizontal, Theme.Spacing.m)
                    
                    Text("You can still monitor your campaigns and insights while we finish this experience.")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.l)
                }
                .padding()
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    BrandEventsView()
}
