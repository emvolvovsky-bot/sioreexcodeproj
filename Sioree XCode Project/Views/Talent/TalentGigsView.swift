//
//  TalentGigsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

enum GigStatus: String {
    case requested = "Requested"
    case confirmed = "Confirmed"
    case paid = "Paid"
    case completed = "Completed"
}

struct Gig: Identifiable {
    let id: String
    let eventName: String
    let hostName: String
    let date: Date
    let rate: String
    let status: GigStatus
    
    init(id: String = UUID().uuidString,
         eventName: String,
         hostName: String,
         date: Date,
         rate: String,
         status: GigStatus) {
        self.id = id
        self.eventName = eventName
        self.hostName = hostName
        self.date = date
        self.rate = rate
        self.status = status
    }
}

struct TalentGigsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myGigs: [Gig] = [
        Gig(eventName: "Halloween Mansion Party", hostName: "LindaFlora", date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(), rate: "$500", status: .confirmed),
        Gig(eventName: "Rooftop Sunset Sessions", hostName: "Skyline Events", date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(), rate: "$750", status: .requested),
        Gig(eventName: "Underground Rave Warehouse", hostName: "Midnight Collective", date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(), rate: "$500", status: .paid),
        Gig(eventName: "Beachside Bonfire", hostName: "Coastal Vibes", date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), rate: "$400", status: .completed)
    ]
    @State private var showFindEvents = false
    @State private var selectedTalentType = "DJ"
    @State private var selectedTab = 0 // 0 = My Gigs, 1 = Find Events
    @State private var eventsLookingForTalent: [Event] = []
    @State private var isLoadingEvents = false
    @State private var eventsError: String?
    private let networkService = NetworkService()
    
    var upcomingGigs: [Gig] {
        myGigs.filter { $0.date >= Date() }
    }
    
    var pastGigs: [Gig] {
        myGigs.filter { $0.date < Date() }
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
                
                VStack(spacing: 0) {
                    // Tab Selector
                    Picker("", selection: $selectedTab) {
                        Text("My Gigs").tag(0)
                        Text("Find Events").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    
                    if selectedTab == 0 {
                        // My Gigs Tab
                        ScrollView {
                            VStack(spacing: Theme.Spacing.m) {
                                // Upcoming Section
                                if !upcomingGigs.isEmpty {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                        Text("Upcoming")
                                            .font(.sioreeH4)
                                            .foregroundColor(.sioreeWhite)
                                            .padding(.horizontal, Theme.Spacing.m)
                                        
                                        ForEach(upcomingGigs) { gig in
                                            NavigationLink(destination: GigDetailView(gig: gig)) {
                                                GigRow(gig: gig)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal, Theme.Spacing.m)
                                        }
                                    }
                                    .padding(.top, Theme.Spacing.m)
                                }
                                
                                // Completed Section
                                if !pastGigs.isEmpty {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                        Text("Completed")
                                            .font(.sioreeH4)
                                            .foregroundColor(.sioreeWhite)
                                            .padding(.horizontal, Theme.Spacing.m)
                                        
                                        ForEach(pastGigs) { gig in
                                            NavigationLink(destination: GigDetailView(gig: gig)) {
                                                GigRow(gig: gig)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal, Theme.Spacing.m)
                                        }
                                    }
                                    .padding(.top, Theme.Spacing.m)
                                }
                                
                                if myGigs.isEmpty {
                                    VStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 50))
                                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                        
                                        Text("No gigs yet")
                                            .font(.sioreeH4)
                                            .foregroundColor(.sioreeWhite)
                                        
                                        Text("Switch to 'Find Events' to discover opportunities")
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeLightGrey)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.xl)
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.bottom, Theme.Spacing.m)
                        }
                    } else {
                        // Find Events Tab
                        ScrollView {
                            VStack(spacing: Theme.Spacing.m) {
                                Button(action: {
                                    showFindEvents = true
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 20))
                                        Text("Find events that might need \(selectedTalentType)")
                                            .font(.sioreeBody)
                                    }
                                    .foregroundColor(Color.sioreeWhite)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue.opacity(0.2))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.top, Theme.Spacing.m)
                                
                                if isLoadingEvents {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                                        .padding(.vertical, Theme.Spacing.xl)
                                } else if !eventsLookingForTalent.isEmpty {
                                    // Show events that need this talent type
                                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                        Text("Events Looking For \(selectedTalentType)")
                                            .font(.sioreeH4)
                                            .foregroundColor(.sioreeWhite)
                                            .padding(.horizontal, Theme.Spacing.m)
                                        
                                        ForEach(eventsLookingForTalent) { event in
                                            NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                                EventCard(
                                                    event: event,
                                                    onTap: {},
                                                    onLike: {},
                                                    onSave: {}
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal, Theme.Spacing.m)
                                        }
                                    }
                                } else {
                                    // Show message when no events found
                                    VStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 50))
                                            .foregroundColor(.sioreeLightGrey.opacity(0.5))
                                        
                                        Text("No one needs \(selectedTalentType.lowercased()) yet")
                                            .font(.sioreeH4)
                                            .foregroundColor(.sioreeWhite)
                                        
                                        Text("Check back later for events that need \(selectedTalentType.lowercased())")
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeLightGrey)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.xl)
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.bottom, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Gigs")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFindEvents) {
                FindEventsForTalentView(selectedTalentType: $selectedTalentType)
            }
            .onChange(of: selectedTalentType) { oldValue, newValue in
                loadEventsForTalentType()
            }
            .onAppear {
                // Get talent type from current user if available
                if let user = authViewModel.currentUser,
                   let talentCategory = getTalentCategoryFromUser(user) {
                    selectedTalentType = talentCategory.rawValue
                }
                loadEventsForTalentType()
            }
        }
    }
    
    private func loadEventsForTalentType() {
        guard !selectedTalentType.isEmpty else { return }
        isLoadingEvents = true
        eventsError = nil
        
        networkService.fetchEventsLookingForTalent(talentType: selectedTalentType)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingEvents = false
                    if case .failure(let error) = completion {
                        eventsError = error.localizedDescription
                        print("❌ Failed to load events: \(error)")
                    }
                },
                receiveValue: { events in
                    isLoadingEvents = false
                    eventsLookingForTalent = events
                    print("✅ Loaded \(events.count) events looking for \(selectedTalentType)")
                }
            )
            .store(in: &cancellables)
    }
    
    private func getTalentCategoryFromUser(_ user: User) -> TalentCategory? {
        // TODO: Get talent category from user profile
        // For now, return nil and let user select
        return nil
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct GigRow: View {
    let gig: Gig
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(gig.eventName)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                    
                    Text(gig.hostName)
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeLightGrey)
                    
                    Text(gig.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text(gig.rate)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeIcyBlue)
                    
                    StatusChip(status: gig.status)
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
    TalentGigsView()
}

