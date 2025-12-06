//
//  HostHomeView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct HostHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var recommendedTalent = Array(MockData.sampleTalent.prefix(5))
    
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
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        // Tonight on Sioree
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Tonight on Sioree")
                                .font(.sioreeH2)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.top, -Theme.Spacing.m)
                            
                            if viewModel.isLoading && !viewModel.hasLoaded {
                                ProgressView()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            } else if viewModel.events.isEmpty && viewModel.hasLoaded {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color.sioreeLightGrey)
                                    Text("No events nearby")
                                        .font(.sioreeH4)
                                        .foregroundColor(Color.sioreeLightGrey)
                                    Text("Check back later for new events")
                                        .font(.sioreeBodySmall)
                                        .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xl)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Spacing.m) {
                                        ForEach(viewModel.events.filter { $0.isFeatured }) { event in
                                            AppEventCard(event: event) {
                                                // Navigate to event detail
                                            }
                                            .frame(width: 320)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                        }
                        
                        // Recommended Talent
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Recommended Talent")
                                .font(.sioreeH2)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.m) {
                                    ForEach(recommendedTalent) { talent in
                                        TalentCard(talent: talent) {
                                            // Navigate to talent detail
                                        }
                                        .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Host Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !viewModel.hasLoaded {
                    viewModel.loadNearbyEvents()
                }
            }
        }
    }
}

#Preview {
    HostHomeView()
}

