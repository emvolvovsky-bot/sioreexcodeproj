//
//  BrandCampaignsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct BrandCampaignsView: View {
    @State private var campaigns = MockData.sampleCampaigns
    @State private var promotedEvents: [PromotedEvent] = []
    @State private var showPromoteSheet = false
    @State private var isLoading = false
    @State private var editingCampaign: BrandCampaign?
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
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
                            
                            Text("Boost and track your campaign visibility and reach more event hosts")
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
                        
                        // Promoted Events with Dates
                        if !promotedEvents.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                Text("Promoted Events")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                    .padding(.horizontal, Theme.Spacing.m)
                                
                                LazyVStack(spacing: Theme.Spacing.m) {
                                    ForEach(promotedEvents) { event in
                                        PromotedEventCard(event: event)
                                            .padding(.horizontal, Theme.Spacing.m)
                                    }
                                }
                            }
                            .padding(.top, Theme.Spacing.m)
                        }
                        
                        // Campaigns List
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(campaigns) { campaign in
                                Button(action: {
                                    editingCampaign = campaign
                                }) {
                                    CampaignCard(campaign: campaign)
                                }
                                .buttonStyle(PlainButtonStyle())
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
            .sheet(item: $editingCampaign) { campaign in
                EditCampaignSheet(campaign: campaign) { updated in
                    if let idx = campaigns.firstIndex(where: { $0.id == updated.id }) {
                        campaigns[idx] = updated
                    }
                    editingCampaign = nil
                }
            }
            .onAppear {
                loadPromotedEvents()
            }
        }
    }
    
    private func loadPromotedEvents() {
        isLoading = true
        networkService.fetchBrandPromotedEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load promoted events: \(error)")
                    }
                },
                receiveValue: { [self] events in
                    promotedEvents = events
                    isLoading = false
                }
            )
            .store(in: &cancellables)
    }
}

// PromotedEvent is defined in NetworkService.swift - use that one

struct PromotedEventCard: View {
    let event: PromotedEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(event.title)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                    
                    HStack(spacing: Theme.Spacing.s) {
                        Label(event.location, systemImage: "location.fill")
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        if let date = event.date {
                            Text("•")
                                .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                            
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeLightGrey)
                        }
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.sioreeLightGrey.opacity(0.3))
            
            HStack {
                if let date = event.date {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Event Date")
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeLightGrey)
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeWhite)
                    }
                }
                
                Spacer()
                
                if event.budget > 0 {
                    VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                        Text("Budget")
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeLightGrey)
                        Text("$\(Int(event.budget))")
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
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
                    
                    StatusPill(status: campaign.statusText)
                }
                
                Spacer()
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

struct EditCampaignSheet: View, Identifiable {
    let id = UUID()
    @Environment(\.dismiss) var dismiss
    @State var campaign: BrandCampaign
    var onSave: (BrandCampaign) -> Void
    
    @State private var brandName: String = ""
    @State private var headline: String = ""
    @State private var budgetText: String = ""
    @State private var goalText: String = ""
    @State private var statusText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Brand Name", text: $brandName)
                    TextField("Headline", text: $headline)
                    TextField("Budget", text: $budgetText)
                    TextField("Goal", text: $goalText)
                }
                
                Section(header: Text("Status")) {
                    Picker("Status", selection: $statusText) {
                        ForEach(["Live", "Finished", "Completed", "Pending", "Draft"], id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Edit Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        campaign = BrandCampaign(
                            id: campaign.id,
                            brandName: brandName,
                            headline: headline,
                            budgetText: budgetText,
                            goalText: goalText,
                            statusText: statusText
                        )
                        onSave(campaign)
                        dismiss()
                    }
                }
            }
            .onAppear {
                brandName = campaign.brandName
                headline = campaign.headline
                budgetText = campaign.budgetText
                goalText = campaign.goalText
                statusText = campaign.statusText
            }
        }
    }
}

struct StatusPill: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.sioreeCaption)
            .fontWeight(.semibold)
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .cornerRadius(12)
    }
    
    private var foreground: Color {
        switch status.lowercased() {
        case "live":
            return Color.green
        case "finished", "completed":
            return Color.orange
        default:
            return Color.sioreeWhite
        }
    }
    
    private var background: Color {
        switch status.lowercased() {
        case "live":
            return Color.green.opacity(0.15)
        case "finished", "completed":
            return Color.orange.opacity(0.15)
        default:
            return Color.sioreeLightGrey.opacity(0.2)
        }
    }
}

#Preview {
    BrandCampaignsView()
}

