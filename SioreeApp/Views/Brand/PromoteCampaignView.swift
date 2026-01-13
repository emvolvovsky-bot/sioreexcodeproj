//
//  PromoteCampaignView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct PromoteCampaignView: View {
    @Environment(\.dismiss) var dismiss
    @State private var campaignName = ""
    @State private var budget = ""
    @State private var targetAudience = ""
    @State private var promotionType = "Featured Listing"
    
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
                    VStack(spacing: Theme.Spacing.xl) {
                        Text("Create a promotion to increase your campaign visibility")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        VStack(spacing: Theme.Spacing.m) {
                            CustomTextField(placeholder: "Campaign Name", text: $campaignName)
                            CustomTextField(placeholder: "Promotion Budget", text: $budget, keyboardType: .decimalPad)
                            CustomTextField(placeholder: "Target Audience", text: $targetAudience)
                            
                            Picker("Promotion Type", selection: $promotionType) {
                                Text("Featured Listing").tag("Featured Listing")
                                Text("Homepage Banner").tag("Homepage Banner")
                                Text("Event Feed Promotion").tag("Event Feed Promotion")
                            }
                            .pickerStyle(.menu)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeLightGrey.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        Button(action: {
                            print("Creating promotion for: \(campaignName)")
                            dismiss()
                        }) {
                            Text("Create Promotion")
                                .font(.sioreeBody)
                                .fontWeight(.semibold)
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
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Promote Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeIcyBlue)
                }
            }
        }
    }
}

#Preview {
    PromoteCampaignView()
}



