//
//  BrandInsightsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BrandInsightsView: View {
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
                        
                        MetricCard(title: "Total Impressions", value: "125K", subtitle: "+12% from last month")
                        MetricCard(title: "Avg. Cost per Attendee", value: "$2.50", subtitle: "Below industry avg")
                        MetricCard(title: "Cities Activated", value: "8", subtitle: "3 new this month")
                        MetricCard(title: "Campaign ROI", value: "340%", subtitle: "Above target", progress: 0.85)
                        MetricCard(title: "Engagement Rate", value: "8.2%", subtitle: "Industry leading", progress: 0.82)
                    }
                    .padding(.top, -Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.m)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    BrandInsightsView()
}

