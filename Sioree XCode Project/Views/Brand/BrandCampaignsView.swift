//
//  BrandCampaignsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct BrandCampaignsView: View {
    @State private var campaigns = MockData.sampleCampaigns
    @State private var showPromoteSheet = false
    
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
                        // Promote Campaign Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Promote Your Campaign")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            Button(action: {
                                showPromoteSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "megaphone.fill")
                                        .font(.system(size: 20))
                                    Text("Create Promotion")
                                        .font(.sioreeBody)
                                }
                                .foregroundColor(Color.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                )
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            
                            Text("Boost your campaign visibility and reach more event hosts")
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeLightGrey)
                                .padding(.horizontal, Theme.Spacing.m)
                        }
                        .padding(.vertical, Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.05))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Campaigns List
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(campaigns) { campaign in
                                CampaignCard(campaign: campaign)
                                    .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Campaigns")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPromoteSheet) {
                PromoteCampaignView()
            }
        }
    }
}

struct CampaignCard: View {
    let campaign: BrandCampaign
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(campaign.brandName)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                    
                    Text(campaign.headline)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeLightGrey)
                }
                
                Spacer()
                
                StatusChip(status: campaign.statusText)
            }
            
            Divider()
                .background(Color.sioreeLightGrey.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Budget")
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                    Text(campaign.budgetText)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeWhite)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text("Goal")
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                    Text(campaign.goalText)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeWhite)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    BrandCampaignsView()
}

