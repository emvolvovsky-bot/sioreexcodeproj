//
//  TalentGigsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine
import UIKit

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
    @State private var selectedTab = 0 // 0 = My Gigs, 1 = Browse Events
    @State private var selectedSegment = 0 // 0 = Pending, 1 = Upcoming, 2 = Past
    @State private var eventsLookingForTalent: [Event] = []
    @State private var isLoadingEvents = false
    @State private var eventsError: String?
    @State private var selectedGigForMessaging: Gig?
    @State private var showMessageView = false
    @State private var showWithdrawConfirmation = false
    @State private var gigToWithdraw: Gig?
    @State private var selectedEventId: String?
    @State private var showEventDetail = false
    private let networkService = NetworkService()
    private let messagingService = MessagingService()
    
    var pendingBookings: [Gig] {
        myGigs.filter { $0.status == .requested }
    }

    var upcomingBookings: [Gig] {
        myGigs.filter { ($0.status == .confirmed || $0.status == .paid) && $0.date >= Date() }
    }

    var pastBookings: [Gig] {
        myGigs.filter { $0.status == .completed || $0.date < Date() }
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
                        Text("My Bookings").tag(0)
                        Text("Browse Events").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    
                    if selectedTab == 0 {
                        // My Bookings Tab
                        VStack(spacing: 0) {
                            // Segment Picker
                            Picker("", selection: $selectedSegment) {
                                Text("Pending").tag(0)
                                Text("Upcoming").tag(1)
                                Text("Past").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.s)

                            // Content based on selected segment
                            ScrollView {
                                VStack(spacing: Theme.Spacing.m) {
                                    let currentBookings = selectedSegment == 0 ? pendingBookings :
                                                         selectedSegment == 1 ? upcomingBookings : pastBookings
                                    let sectionTitle = selectedSegment == 0 ? "Pending" :
                                                      selectedSegment == 1 ? "Upcoming" : "Past"

                                    if !currentBookings.isEmpty {
                                        ForEach(currentBookings) { booking in
                                            TalentBookingRow(booking: booking, segment: selectedSegment, onAction: {
                                                handleBookingAction(for: booking, segment: selectedSegment)
                                            }, onWithdraw: selectedSegment == 0 ? {
                                                withdrawApplication(for: booking)
                                            } : nil)
                                            .padding(.horizontal, Theme.Spacing.m)
                                        }
                                    } else {
                                        VStack(spacing: Theme.Spacing.m) {
                                            Image(systemName: selectedSegment == 0 ? "clock" :
                                                                 selectedSegment == 1 ? "calendar" : "checkmark.circle")
                                                .font(.system(size: 50))
                                                .foregroundColor(.sioreeLightGrey.opacity(0.5))

                                            Text("No \(sectionTitle.lowercased()) bookings")
                                                .font(.sioreeH4)
                                                .foregroundColor(.sioreeWhite)

                                            if selectedSegment == 0 {
                                                Text("Apply to events to see pending bookings here")
                                                    .font(.sioreeBody)
                                                    .foregroundColor(.sioreeLightGrey.opacity(0.7))
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, Theme.Spacing.l)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.top, Theme.Spacing.xl)
                                    }
                                }
                                .padding(.bottom, Theme.Spacing.xl)
                            }
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
                                } else if eventsLookingForTalent.isEmpty {
                                    emptyState
                                } else {
                                    eventsList
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
            .sheet(isPresented: $showMessageView) {
                if let gig = selectedGigForMessaging {
                    TalentMessageHostView(gig: gig, authViewModel: authViewModel)
                }
            }
            .sheet(isPresented: $showEventDetail) {
                if let eventId = selectedEventId {
                    EventDetailView(eventId: eventId, isTalentMapMode: true)
                }
            }
            .alert("Withdraw Application", isPresented: $showWithdrawConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Withdraw", role: .destructive) {
                    confirmWithdraw()
                }
            } message: {
                if let gig = gigToWithdraw {
                    Text("Are you sure you want to withdraw your application for \(gig.eventName)?")
                }
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

    private func handleBookingAction(for booking: Gig, segment: Int) {
        switch segment {
        case 0: // Pending - View Details
            // For now, show an alert since we don't have event ID mapping
            let alert = UIAlertController(
                title: "View Details",
                message: "Event details for \(booking.eventName) would open here.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        case 1: // Upcoming - Message Host
            selectedGigForMessaging = booking
            showMessageView = true
        case 2: // Past - Rate & Review
            let alert = UIAlertController(
                title: "Rate & Review",
                message: "Rating and review for \(booking.eventName) would open here.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        default:
            break
        }
    }

    private func withdrawApplication(for booking: Gig) {
        gigToWithdraw = booking
        showWithdrawConfirmation = true
    }

    private func confirmWithdraw() {
        guard let gig = gigToWithdraw else { return }

        // Remove from local gigs array
        myGigs.removeAll { $0.id == gig.id }

        // In a real app, you'd call an API to withdraw the application
        // For now, just update the local state

        showWithdrawConfirmation = false
        gigToWithdraw = nil
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
    
    // MARK: - Subviews
    private var eventsList: some View {
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
                    .overlay(alignment: .topLeading) {
                        if let need = event.lookingForSummary ?? event.lookingForTalentType, !need.isEmpty {
                            Label("Looking for \(need)", systemImage: "person.3.sequence.fill")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeWhite)
                                .padding(8)
                                .background(Color.sioreeIcyBlue.opacity(0.8))
                                .cornerRadius(8)
                                .padding(8)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
    }
    
    private var emptyState: some View {
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

struct TalentBookingRow: View {
    let booking: Gig
    let segment: Int // 0 = Pending, 1 = Upcoming, 2 = Past
    let onAction: () -> Void
    let onWithdraw: (() -> Void)?

    private var actionButtonTitle: String {
        switch segment {
        case 0: // Pending
            return "View Details"
        case 1: // Upcoming
            return "Message Host"
        case 2: // Past
            return "Rate & Review"
        default:
            return "View"
        }
    }

    private var canDismiss: Bool {
        segment == 2 // Only past bookings can be dismissed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.m) {
                // Event Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.sioreeCharcoal.opacity(0.3))
                        .frame(width: 50, height: 50)

                    Image(systemName: "calendar")
                        .foregroundColor(.sioreeIcyBlue)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.eventName)
                        .font(.sioreeH4)
                        .foregroundColor(.white)

                    Text(booking.hostName)
                        .font(.sioreeCaption)
                        .foregroundColor(.white)

                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "calendar")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12))

                        Text(booking.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeCaption)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(booking.rate)
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWarning)

                    // Status badge for pending/upcoming
                    if segment < 2 {
                        Text(booking.status.rawValue)
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(statusColor(for: booking.status))
                            .clipShape(Capsule())
                    }
                }
            }

            // Action buttons
            HStack(spacing: Theme.Spacing.s) {
                CustomButton(
                    title: actionButtonTitle,
                    variant: .primary,
                    size: .small
                ) {
                    onAction()
                }

                if segment == 0 {
                    // Pending bookings can be withdrawn
                    CustomButton(
                        title: "Withdraw",
                        variant: .secondary,
                        size: .small
                    ) {
                        onWithdraw?()
                    }
                } else if segment == 2 && canDismiss {
                    // Past bookings can be dismissed
                    CustomButton(
                        title: "Dismiss",
                        variant: .secondary,
                        size: .small
                    ) {
                        // Handle dismiss action
                    }
                }

                Spacer()
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusColor(for status: GigStatus) -> Color {
        switch status {
        case .requested:
            return .sioreeWarning
        case .confirmed:
            return .green
        case .paid:
            return .sioreeIcyBlue
        case .completed:
            return .gray
        }
    }
}

#Preview {
    TalentGigsView()
}

