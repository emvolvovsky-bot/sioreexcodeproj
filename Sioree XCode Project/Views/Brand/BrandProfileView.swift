//
//  BrandProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct BrandProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var campaigns = MockData.sampleCampaigns
    @State private var promotedCount = 0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showEventsList = false
    @State private var isLoadingPromoted = false
    private let networkService = NetworkService()
    
    private var currentUser: User? {
        authViewModel.currentUser
    }
    
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
                
                Group {
                    if currentUser == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let user = currentUser {
                        ScrollView {
                            VStack(spacing: 0) {
                                BrandProfileHeader(
                                    user: user,
                                    promotedEventsCount: promotedCount,
                                    onEditProfile: { showEditProfile = true },
                                    onEventsTap: { showEventsList = true }
                                )
                                .padding(.top, 8)
                                
                            }
                            .padding(.bottom, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let user = currentUser {
                        Text("\(user.username) • \(user.userType.rawValue)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.sioreeWhite)
                            .font(.system(size: 20, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditView(user: currentUser)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showEventsList) {
                if let userId = currentUser?.id {
                    BrandPromotedListView(campaigns: campaigns.filter { isPromotedStatus($0.statusText) })
                }
            }
            .onAppear {
                viewModel.loadUserContent()
                refreshPromotedCount()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.loadUserContent()
                refreshPromotedCount()
            }
        }
    }
    
    private func refreshPromotedCount() {
        // Count live + finished campaigns (as promoted)
        promotedCount = campaigns.filter { campaign in
            isPromotedStatus(campaign.statusText)
        }.count
        
        // Also try backend promoted events; if returned, override count with filtered live/finished if status exists later
        isLoadingPromoted = true
        networkService.fetchBrandPromotedEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    isLoadingPromoted = false
                },
                receiveValue: { _ in
                    // Keep existing count logic tied to campaigns status
                    isLoadingPromoted = false
                }
            )
            .store(in: &cancellables)
    }
    
    private func isPromotedStatus(_ status: String) -> Bool {
        let s = status.lowercased()
        return s == "live" || s == "finished"
    }
}

private struct BrandProfileHeader: View {
    let user: User
    let promotedEventsCount: Int
    let onEditProfile: () -> Void
    let onEventsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                AvatarView(
                    imageURL: user.avatar,
                    size: .large,
                    showBorder: user.verified
                )
                .frame(width: 90, height: 90)
                
                VStack(spacing: Theme.Spacing.s) {
                    Text("Promoted")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeLightGrey)
                    
                    Button(action: onEventsTap) {
                        VStack(spacing: 8) {
                            Text("\(promotedEventsCount)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.sioreeWhite)
                            Text("Events")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.sioreeIcyBlue.opacity(0.4), lineWidth: 2)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                if !user.name.isEmpty {
                    Text(user.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.sioreeWhite)
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(.sioreeWhite)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let location = user.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(location)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.sioreeLightGrey)
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            Button(action: onEditProfile) {
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.sioreeWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        LinearGradient(
                            colors: [Color.sioreeIcyBlue.opacity(0.8), Color.sioreeIcyBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

private struct BrandPromotedListView: View {
    let campaigns: [BrandCampaign]
    @Environment(\.dismiss) var dismiss
    @State private var editingCampaign: BrandCampaign?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCampaigns) { campaign in
                    Button(action: {
                        editingCampaign = campaign
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(campaign.headline)
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            HStack(spacing: 8) {
                                Text(campaign.brandName)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                                
                                StatusPill(status: campaign.statusText)
                            }
                            Text("Budget \(campaign.budgetText) • Goal \(campaign.goalText)")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.sioreeBlack)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
            .navigationTitle("Promoted")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingCampaign) { campaign in
                EditCampaignSheet(campaign: campaign) { _ in
                    // No persistence here; campaign editing is handled in Campaigns screen
                    editingCampaign = nil
                }
            }
        }
    }
    
    private var sortedCampaigns: [BrandCampaign] {
        let priority: (String) -> Int = { status in
            let s = status.lowercased()
            if s == "live" { return 0 }
            if s == "finished" || s == "completed" { return 1 }
            return 2
        }
        return campaigns.sorted { lhs, rhs in
            let lp = priority(lhs.statusText)
            let rp = priority(rhs.statusText)
            if lp != rp { return lp < rp }
            return lhs.headline < rhs.headline
        }
    }
}


#Preview {
    BrandProfileView()
        .environmentObject(AuthViewModel())
}

