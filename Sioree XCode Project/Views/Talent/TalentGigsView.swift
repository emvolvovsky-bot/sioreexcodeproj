//
//  TalentGigsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine
import UIKit

// Assuming Constants is in the same module
// If not, you may need to import the appropriate module

enum GigStatus: String {
    case requested = "Requested"
    case waitingForPayment = "Waiting for Payment"
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
    @EnvironmentObject var talentViewModel: TalentViewModel
    @State private var myGigs: [Gig] = [
        Gig(eventName: "Halloween Mansion Party", hostName: "LindaFlora", date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(), rate: "$500", status: .confirmed),
        Gig(eventName: "Rooftop Sunset Sessions", hostName: "Skyline Events", date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(), rate: "$750", status: .requested),
        Gig(eventName: "Underground Rave Warehouse", hostName: "Midnight Collective", date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(), rate: "$500", status: .paid),
        Gig(eventName: "Beachside Bonfire", hostName: "Coastal Vibes", date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), rate: "$400", status: .completed)
    ]
    @State private var selectedSegment = 0 // 0 = Pending, 1 = Upcoming, 2 = Past
    @State private var selectedGigForMessaging: Gig?
    @State private var showMessageView = false
    @State private var showWithdrawConfirmation = false
    @State private var gigToWithdraw: Gig?
    @State private var selectedTalentType = "DJ"
    @State private var currentTalent: Talent?
    @State private var isTalentAvailable: Bool = false
    @State private var talentPrice: Double = 0
    @State private var showTalentTypeSelector = false
    @State private var selectedEventId: String?
    @State private var showEventDetail = false
    private let networkService = NetworkService()
    private let messagingService = MessagingService()
    
    var pendingBookings: [Gig] {
        myGigs.filter { $0.status == .requested || $0.status == .waitingForPayment }
    }

    var upcomingBookings: [Gig] {
        myGigs.filter { $0.status == .paid && $0.date >= Date() }
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
                                            } : nil, onAccept: selectedSegment == 0 && booking.status == .requested ? {
                                                // Accept the booking request - change status to waiting for payment
                                                acceptBooking(booking)
                                            } : nil, onReject: selectedSegment == 0 && booking.status == .requested ? {
                                                rejectBooking(booking)
                                            } : nil, onViewEvent: selectedSegment == 2 ? {
                                                // Navigate to this event in the host's profile
                                                // For now, show a placeholder
                                                print("Navigate to event '\(booking.eventName)' in host profile")
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
                                                Text("Hosts will send you booking requests here")
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
                }
            }
            .navigationTitle("Gigs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showTalentTypeSelector = true
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isTalentAvailable ? Color.green : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(isTalentAvailable ? "On Market as \(selectedTalentType)" : "Go On Market")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeWhite)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.sioreeWhite)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.sioreeCharcoal.opacity(0.8))
                        .cornerRadius(16)
                    }
                }
            }
            .sheet(isPresented: $showTalentTypeSelector) {
                TalentTypeSelectorView(
                    selectedTalentType: $selectedTalentType,
                    isTalentAvailable: $isTalentAvailable,
                    price: $talentPrice,
                    existingTalent: currentTalent,
                    onStripeCheck: isStripeSetup,
                    onSave: {
                        // Save the talent type, availability, and pricing
                        if let talent = currentTalent {
                            talentViewModel.updateAvailability(talentId: talent.id, isAvailable: isTalentAvailable)
                            // TODO: Save pricing information to backend
                            print("Saving talent profile - Type: \(selectedTalentType), Price: $\(talentPrice)")
                        }
                        showTalentTypeSelector = false
                    }
                )
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
                loadCurrentTalent()
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

    private func acceptBooking(_ booking: Gig) {
        // Check if Stripe is set up (only required in production)
        if Constants.API.environment == .production && !isStripeSetup() {
            // Show alert that Stripe setup is required
            let alert = UIAlertController(
                title: "Stripe Setup Required",
                message: "You must set up Stripe payouts before accepting bookings.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
            return
        }

        // Update the booking status to waiting for payment
        if let index = myGigs.firstIndex(where: { $0.id == booking.id }) {
            myGigs[index] = Gig(
                id: booking.id,
                eventName: booking.eventName,
                hostName: booking.hostName,
                date: booking.date,
                rate: booking.rate,
                status: .waitingForPayment
            )
        }

        // In a real app, you'd call an API to accept the booking
        print("Accepted booking for event: \(booking.eventName)")
    }

    private func rejectBooking(_ booking: Gig) {
        // Remove the booking from the list
        myGigs.removeAll { $0.id == booking.id }

        // In a real app, you'd call an API to reject the booking
        print("Rejected booking for event: \(booking.eventName)")
    }

    private func isStripeSetup() -> Bool {
        // This would check if the talent has completed Stripe onboarding
        // For now, return false to simulate not being set up
        return false
    }

    

    private func toggleAvailability() {
        guard let talent = currentTalent else { return }

        let newAvailability = !isTalentAvailable
        isTalentAvailable = newAvailability
        talentViewModel.updateAvailability(talentId: talent.id, isAvailable: newAvailability)
    }
    
    @State private var cancellables = Set<AnyCancellable>()

    private func getTalentCategoryFromUser(_ user: User) -> TalentCategory? {
        // TODO: Get talent category from user profile
        // For now, return nil and let user select
        return nil
    }

    private func loadCurrentTalent() {
        guard let userId = authViewModel.currentUser?.id else { return }

        networkService.fetchTalentProfile(talentId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load talent profile: \(error)")
                    }
                },
                receiveValue: { talent in
                    currentTalent = talent
                    isTalentAvailable = talent.isAvailable
                    selectedTalentType = talent.category.rawValue
                    talentPrice = talent.priceRange.min // Use min as the single price
                }
            )
            .store(in: &cancellables)
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
    let onAccept: (() -> Void)?
    let onReject: (() -> Void)?
    let onViewEvent: (() -> Void)?

    private var actionButtonTitle: String {
        switch segment {
        case 0: // Pending
            return "View Details"
        case 1: // Upcoming
            return "Message Host"
        case 2: // Past
            return "View Event"
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
                        if segment == 1 { // Upcoming (paid gigs)
                            Text("Confirmed")
                                .font(.sioreeCaption)
                                .foregroundColor(.green)
                        } else { // Pending
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
            }

            // Action buttons
            HStack(spacing: Theme.Spacing.s) {
                if segment == 0 {
                    if booking.status == .requested {
                        // Requested bookings: View Details, Accept, Reject, Message Host
                        VStack(spacing: Theme.Spacing.xs) {
                            HStack(spacing: Theme.Spacing.xs) {
                                CustomButton(
                                    title: "View Details",
                                    variant: .secondary,
                                    size: .small
                                ) {
                                    onAction()
                                }

                                CustomButton(
                                    title: "Message Host",
                                    variant: .secondary,
                                    size: .small
                                ) {
                                    // For now, show placeholder - this would open messaging
                                    print("Message host for booking: \(booking.eventName)")
                                }
                            }

                            HStack(spacing: Theme.Spacing.xs) {
                                CustomButton(
                                    title: "Accept",
                                    variant: .primary,
                                    size: .small
                                ) {
                                    onAccept?()
                                }

                                CustomButton(
                                    title: "Reject",
                                    variant: .destructive,
                                    size: .small
                                ) {
                                    onReject?()
                                }
                            }
                        }
                    } else if booking.status == .waitingForPayment {
                        // Waiting for payment: just Message Host
                        CustomButton(
                            title: "Message Host",
                            variant: .primary,
                            size: .small
                        ) {
                            // For now, show placeholder - this would open messaging
                            print("Message host for booking: \(booking.eventName)")
                        }
                    }
                } else if segment == 2 {
                    // Past events: single button to view event
                    CustomButton(
                        title: "View Event",
                        variant: .primary,
                        size: .small
                    ) {
                        onViewEvent?()
                    }
                } else {
                    // Upcoming: Message Host
                    CustomButton(
                        title: "Message Host",
                        variant: .primary,
                        size: .small
                    ) {
                        onAction()
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
        case .waitingForPayment:
            return .orange
        case .confirmed:
            return .green
        case .paid:
            return .sioreeIcyBlue
        case .completed:
            return .gray
        }
    }
}

struct TalentTypeSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTalentType: String
    @Binding var isTalentAvailable: Bool
    @Binding var price: Double
    let existingTalent: Talent?
    let onStripeCheck: () -> Bool

    let onSave: () -> Void


    private var talentTypes: [String] {
        TalentCategory.allCases.map { $0.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                    Text("Set Up Your Talent Profile")
                        .font(.sioreeH3)
                        .foregroundColor(.sioreeWhite)
                        .padding(.top, Theme.Spacing.m)

                    Text("Choose your talent type, set your price per event, and availability")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                        .multilineTextAlignment(.center)

                    VStack(spacing: Theme.Spacing.m) {
                        ForEach(talentTypes, id: \.self) { type in
                            Button(action: {
                                selectedTalentType = type
                            }) {
                                HStack {
                                    Text(type)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)

                                    Spacer()

                                    if selectedTalentType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeCharcoal.opacity(selectedTalentType == type ? 0.6 : 0.3))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                        }
                    }

                    VStack(spacing: Theme.Spacing.m) {
                        Text("Set Your Price Per Event")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Price")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)

                            TextField("0.00", text: Binding(
                                get: { price > 0 ? String(format: "%.2f", price) : "" },
                                set: { newValue in
                                    if let value = Double(newValue), value >= 0 {
                                        price = value
                                    } else if newValue.isEmpty {
                                        price = 0
                                    }
                                }
                            ))
                                .keyboardType(.decimalPad)
                                .padding(Theme.Spacing.s)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .foregroundColor(.sioreeWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.bottom, Theme.Spacing.s)
                    }
                    .onAppear {
                        // Load existing pricing if available
                        if let talent = existingTalent {
                            price = talent.priceRange.min // Use min as the single price
                        }
                    }

                    VStack(spacing: Theme.Spacing.m) {
                        Text("Availability")
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: Theme.Spacing.m) {
                            Button(action: {
                                isTalentAvailable = false
                            }) {
                                HStack {
                                    Text("Off Market")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)

                                    Spacer()

                                    if !isTalentAvailable {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeCharcoal.opacity(!isTalentAvailable ? 0.6 : 0.3))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }

                            Button(action: {
                                // Check if Stripe is set up before allowing talent to go on market (only in production)
                                if Constants.API.environment == .production && !onStripeCheck() {
                                    // Show alert that Stripe setup is required
                                    let alert = UIAlertController(
                                        title: "Stripe Setup Required",
                                        message: "You must set up Stripe payouts before going on market.",
                                        preferredStyle: .alert
                                    )
                                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootViewController = windowScene.windows.first?.rootViewController {
                                        rootViewController.present(alert, animated: true)
                                    }
                                    return
                                }
                                isTalentAvailable = true
                            }) {
                                HStack {
                                    Text("On Market")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)

                                    Spacer()

                                    if isTalentAvailable {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeCharcoal.opacity(isTalentAvailable ? 0.6 : 0.3))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                        }
                    }

                    Spacer()

                    CustomButton(
                        title: "Save & Continue",
                        variant: .primary,
                        size: .large
                    ) {
                        // Validate pricing
                        if price <= 0 {
                            // Show validation error
                            let alert = UIAlertController(
                                title: "Invalid Pricing",
                                message: "Please set a valid price greater than $0.",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(alert, animated: true)
                            }
                            return
                        }

                        onSave()
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.xl)
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.sioreeWhite)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text("Talent Type")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
            }
        }
    }
}

#Preview {
    TalentGigsView()
}

