//
//  BrandInsightsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct BrandInsightsView: View {
    @StateObject private var viewModel = BrandInsightsViewModel()
    
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
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        // Info Banner
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Color.sioreeIcyBlue)
                                Text("Insights Data")
                                    .font(.sioreeH4)
                                    .foregroundColor(Color.sioreeWhite)
                            }
                            
                            Text("These insights are generated from your promoted campaigns and event sponsorships. Promote your campaigns to start tracking performance metrics.")
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeLightGrey)
                        }
                        .padding(Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            MetricCard(title: "Total Impressions", value: viewModel.totalImpressions, subtitle: nil)
                            MetricCard(title: "Avg. Cost per Attendee", value: "N/A", subtitle: nil)
                            MetricCard(title: "Cities Activated", value: viewModel.citiesActivated, subtitle: nil)
                            MetricCard(title: "Campaign ROI", value: "N/A", subtitle: nil)
                            MetricCard(title: "Engagement Rate", value: "N/A", subtitle: nil)
                        }
                    }
                    .padding(.top, -Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.m)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadInsights()
            }
        }
    }
}

#Preview {
    BrandInsightsView()
}

