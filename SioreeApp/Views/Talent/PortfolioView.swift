//
//  PortfolioView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PortfolioView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var items: [PortfolioItem]
    @State private var showAddItem = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if items.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                        
                        Text("No portfolio items yet")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: Theme.Spacing.m),
                            GridItem(.flexible(), spacing: Theme.Spacing.m)
                        ], spacing: Theme.Spacing.m) {
                            ForEach(items) { item in
                                PortfolioCard(item: item)
                            }
                        }
                        .padding(Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
        }
    }
}

#Preview {
    PortfolioView(items: .constant([]))
}



