//
//  TalentMarketplaceView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct TalentMarketplaceView: View {
    @StateObject private var viewModel = TalentViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.sioreeWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.s) {
                            FilterChip(
                                title: "All",
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.filterByCategory(nil)
                            }
                            
                            ForEach(TalentCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.filterByCategory(category)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.s)
                    
                    // Talent List
                    if viewModel.isLoading {
                        LoadingView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(viewModel.talent) { talent in
                                    TalentCardView(talent: talent)
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Talent Marketplace")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TalentCardView: View {
    let talent: Talent
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            AvatarView(imageURL: talent.avatar, size: .medium)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(talent.name)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeCharcoal)
                    
                    if talent.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color.sioreeIcyBlue)
                            .font(.caption)
                    }
                }
                
                Text(talent.category.rawValue)
                    .font(.sioreeBodySmall)
                    .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                
                HStack {
                    if talent.rating > 0 {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color.sioreeWarmGlow)
                                .font(.caption)
                            Text(String(format: "%.1f", talent.rating))
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeCharcoal.opacity(0.7))
                        }
                    }
                    
                    if talent.priceRange.min > 0 {
                        Text(Helpers.formatCurrency(talent.priceRange.min))
                            .font(.sioreeBodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}

#Preview {
    TalentMarketplaceView()
}

