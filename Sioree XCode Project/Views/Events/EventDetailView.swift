//
//  EventDetailView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import UIKit
import Combine
import StripePaymentSheet
import StripeCore

struct EventDetailView: View {
    let eventId: String
    let isTalentMapMode: Bool
    @StateObject private var viewModel: EventViewModel
    @StateObject private var checkoutViewModel = CheckoutViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showLocationActionSheet = false
    @State private var showTalentBrowser = false
    // Talent → request-to-help state
    @State private var isRequestingHelp = false
    @State private var requestAlertMessage: String?
    @State private var requestSuccess = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showEditEvent = false
    @State private var didPreparePaymentSheet = false
    @State private var paymentAlertMessage: String?
    private let ticketFeeRate = 0.05
    
    init(eventId: String, isTalentMapMode: Bool = false) {
        self.eventId = eventId
        self.isTalentMapMode = isTalentMapMode
        _viewModel = StateObject(wrappedValue: EventViewModel(eventId: eventId))
    }
    
    private var isHost: Bool {
        guard let event = viewModel.event,
              let currentUserId = authViewModel.currentUser?.id else {
            return false
        }
        return event.hostId == currentUserId
    }
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        // Share action
                    }
                }
            }
            .onAppear {
                // Track impression when event detail is viewed
                if let event = viewModel.event, event.isFeatured {
                    viewModel.trackImpression()
                }

                // Fetch bookings for hosts
                if isHost {
                    viewModel.fetchEventBookings()
                }
            }
            .onChange(of: viewModel.event) { newEvent in
                guard let event = newEvent,
                      !didPreparePaymentSheet,
                      let ticketPrice = event.ticketPrice,
                      ticketPrice > 0,
                      !isHost else {
                    return
                }
                didPreparePaymentSheet = true
                checkoutViewModel.preparePaymentSheet(amount: totalPrice(for: ticketPrice), eventId: event.id)
            }
            .confirmationDialog("Open Location", isPresented: $showLocationActionSheet, titleVisibility: .visible) {
                if let event = viewModel.event {
                    Button("Open in Maps") {
                        openLocationInMaps(location: event.location)
                    }
                    Button("Open in Google Maps") {
                        openLocationInGoogleMaps(location: event.location)
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .sheet(isPresented: $viewModel.showRSVPSheet) {
                RSVPConfirmationView(
                    event: viewModel.event,
                    qrString: viewModel.rsvpQRCode
                ) {
                    viewModel.showRSVPSheet = false
                    // Dismiss the event detail view after RSVP - navigate back to home
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTalentBrowser) {
                TalentBrowserView(event: viewModel.event, onTalentRequested: { talent in
                    // Handle talent request callback
                    print("Requested talent: \(talent.name)")
                    // In a real implementation, this would create a booking request
                    // and send a notification to the talent
                    showTalentBrowser = false
                })
            }
            .sheet(isPresented: $showEditEvent) {
                if let event = viewModel.event {
                    EventEditView(event: event) {
                        // Reload event after editing
                        viewModel.loadEvent()
                        showEditEvent = false
                    }
                    .environmentObject(authViewModel)
                }
            }
            .alert(isPresented: Binding(
                get: { requestAlertMessage != nil },
                set: { _ in requestAlertMessage = nil }
            )) {
                Alert(
                    title: Text(requestSuccess ? "Request Sent" : "Request Failed"),
                    message: Text(requestAlertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: Binding(
                get: { paymentAlertMessage != nil },
                set: { _ in paymentAlertMessage = nil }
            )) {
                Alert(
                    title: Text("Payment Failed"),
                    message: Text(paymentAlertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }

    private var backgroundView: some View {
        // Dark gradient background
        LinearGradient(
            colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var contentView: some View {
        if let event = viewModel.event {
            eventScrollView(event)
        } else if viewModel.isLoading {
            LoadingView()
        } else {
            errorView
        }
    }

    private func eventScrollView(_ event: Event) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image - Cover photo ONLY, no fallback
                ZStack {
                    CoverPhotoView(imageURL: event.images.first, height: 300)

                    // Brand promotion badge overlay (if featured)
                    if event.isFeatured {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.sioreeWarmGlow)
                                    Text("FEATURED")
                                        .font(.sioreeCaption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.sioreeWhite)
                                }
                                .padding(.horizontal, Theme.Spacing.s)
                                .padding(.vertical, 4)
                                .background(Color.sioreeIcyBlue.opacity(0.9))
                                .cornerRadius(Theme.CornerRadius.small)
                                .padding(Theme.Spacing.m)
                            }
                            Spacer()
                        }
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    HStack(alignment: .center) {
                        Text(event.title)
                            .font(.sioreeH1)
                            .foregroundColor(.sioreeWhite)

                        Spacer()

                        // Edit button for host on upcoming events only
                        if isHost, let event = viewModel.event, event.date >= Date() {
                            Button(action: {
                                showEditEvent = true
                            }) {
                                Text("✏️")
                                    .font(.system(size: 24))
                            }
                            .padding(.leading, Theme.Spacing.s)
                        }
                    }

                    if !isTalentMapMode, let need = event.lookingForSummary ?? event.lookingForTalentType, !need.isEmpty, need.lowercased() != "general talent" {
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "person.3.sequence.fill")
                                .foregroundColor(.sioreeIcyBlue)
                            Text("Looking for \(need)")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                            Spacer()
                        }
                        .padding(Theme.Spacing.m)
                        .background(Color.sioreeIcyBlue.opacity(0.15))
                        .cornerRadius(Theme.CornerRadius.medium)
                    }

                    // Only show host profile and message host button if user is not the host
                    if !isHost {
                        NavigationLink(destination: InboxProfileView(userId: event.hostId)) {
                            HStack(spacing: Theme.Spacing.s) {
                                AvatarView(imageURL: event.hostAvatar, size: .small)
                                Text(event.hostName)
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.sioreeIcyBlue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()

                        // Message Host Button
                        NavigationLink(destination: InboxProfileView(userId: event.hostId)) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text("Message Host")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeIcyBlue)
                                Spacer()
                            }
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeIcyBlue.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                    }

                    // Brand promotion info (if featured)
                    if !isTalentMapMode, event.isFeatured {
                        Divider()

                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.sioreeWarmGlow)
                            Text("Promoted by Brand")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeWhite.opacity(0.7))
                            Spacer()
                        }
                        .padding(Theme.Spacing.s)
                        .background(Color.sioreeIcyBlue.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.small)
                    }

                    Divider()

                    // Event Details Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text("Event Details")
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)

                        // Place - Tappable to open in Maps
                        Button(action: {
                            showLocationActionSheet = true
                        }) {
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Location")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeWhite.opacity(0.7))
                                    Text(event.location)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    if let locationDetails = event.locationDetails, !locationDetails.isEmpty, !isTalentMapMode {
                                        Text(locationDetails)
                                            .font(.sioreeBodySmall)
                                            .foregroundColor(.sioreeWhite.opacity(0.7))
                                            .padding(.top, 2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.system(size: 16))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Time
                        HStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.sioreeIcyBlue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Date & Time")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeWhite.opacity(0.7))
                                Text("\(event.date.formattedEventDate()) at \(event.time.formattedEventTime())")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                            }
                        }

                        if !isTalentMapMode {
                            // Price + Buy Button
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Total (incl. 5% fee)")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeWhite.opacity(0.7))
                                    if let ticketPrice = event.ticketPrice, ticketPrice > 0 {
                                        Text(Helpers.formatCurrency(totalPrice(for: ticketPrice)))
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeWhite)
                                    } else {
                                        Text("Free")
                                            .font(.sioreeBody)
                                            .foregroundColor(.green)
                                    }
                                }
                                Spacer()
                            }

                            if let ticketPrice = event.ticketPrice, ticketPrice > 0, !isHost {
                                paymentSection(ticketPrice: ticketPrice, eventId: event.id)
                            }
                        }

                        // Attendees
                        if isTalentMapMode {
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Attendees")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeWhite.opacity(0.7))
                                    Text("\(event.attendeeCount) People Going")
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeIcyBlue)
                                }
                                Spacer()
                            }
                        } else {
                            NavigationLink(destination: EventAttendeesView(eventId: event.id, eventName: event.title)) {
                                HStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "person.3.fill")
                                        .foregroundColor(.sioreeIcyBlue)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                        Text("Attendees")
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeWhite.opacity(0.7))
                                        Text("\(event.attendeeCount) People Going")
                                            .font(.sioreeBody)
                                            .foregroundColor(Color.sioreeIcyBlue)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.sioreeIcyBlue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Talent for this Event (Host only)
                    if isHost && !viewModel.eventBookings.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            HStack {
                                Text("Talent for this Event")
                                    .font(.sioreeH3)
                                    .foregroundColor(.sioreeWhite)

                                Spacer()

                                Text("\(viewModel.eventBookings.count) booking\(viewModel.eventBookings.count == 1 ? "" : "s")")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            }

                            ForEach(viewModel.eventBookings, id: \.id) { booking in
                                EventTalentBookingRow(booking: booking) {
                                    // Handle booking actions here
                                }
                            }
                        }
                    }

                    if !isTalentMapMode {
                        Divider()

                        // Description
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("About")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                            Text(event.description.isEmpty ? "No description provided." : event.description)
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite.opacity(0.9))
                                .lineSpacing(4)
                        }

                        // Capacity info (if available)
                        if let capacity = event.capacity, capacity > 0 {
                            Divider()
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Capacity")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeWhite.opacity(0.7))
                                    Text("\(event.attendeeCount) / \(capacity) spots")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.l)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .safeAreaInset(edge: .bottom) {
            if shouldShowBottomAction(for: event) {
                // Sticky RSVP/Pay Button
                VStack(spacing: 0) {
                    Divider()
                    Group {
                        // Host controls - no special buttons for host since edit is in header
                        if isHost {
                            // Host sees nothing special in bottom bar
                            EmptyView()
                        } else if authViewModel.currentUser?.userType == .talent {
                            CustomButton(
                                title: isRequestingHelp ? "Sending..." : (isTalentMapMode ? "Request to Work" : "Request to Help"),
                                variant: .primary,
                                size: .large
                            ) {
                                requestToHelp(event: event)
                            }
                            .disabled(isRequestingHelp)
                        } else if viewModel.isRSVPed || event.isRSVPed {
                            CustomButton(
                                title: "Cancel RSVP",
                                variant: .secondary,
                                size: .large
                            ) {
                                viewModel.cancelRSVP()
                            }
                        } else {
                            CustomButton(
                                title: "Attend",
                                variant: .primary,
                                size: .large
                            ) {
                                viewModel.rsvpToEvent()
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.s)
                    .background(Color.sioreeWhite)
                }
            }
        }
        .onReceive(checkoutViewModel.$paymentResult.compactMap { $0 }) { result in
            switch result {
            case .completed:
                viewModel.rsvpToEvent()
                NotificationCenter.default.post(name: .switchToTicketsTab, object: nil)
            case .failed(let error):
                paymentAlertMessage = "Payment failed. \(error.localizedDescription)"
            case .canceled:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EventRSVPSuccess"))) { _ in
            // Auto-dismiss after a short delay to show the confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if viewModel.showRSVPSheet {
                    viewModel.showRSVPSheet = false
                    dismiss()
                }
            }
        }
    }

    private var errorView: some View {
        // Error or empty state
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.sioreeIcyBlue.opacity(0.5))

            if let errorMessage = viewModel.errorMessage {
                Text("Failed to load event")
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)
                Text(errorMessage)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.l)
            } else {
                Text("Event not found")
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)
                Text("This event may have been removed or doesn't exist.")
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.l)
            }

            Button(action: {
                viewModel.loadEvent()
            }) {
                Text("Retry")
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.m)
                    .background(Color.sioreeIcyBlue)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
        }
        .padding(Theme.Spacing.xl)
    }

    // MARK: - Helpers
    private func totalPrice(for ticketPrice: Double) -> Double {
        ticketPrice * (1 + ticketFeeRate)
    }

    private func openLocationInMaps(location: String) {
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?q=\(encodedLocation)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openLocationInGoogleMaps(location: String) {
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "comgooglemaps://?q=\(encodedLocation)"
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                let webURLString = "https://www.google.com/maps/search/?api=1&query=\(encodedLocation)"
                if let webURL = URL(string: webURLString) {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }

    private func getImageFromBundle(_ imageName: String) -> UIImage? {
        if let imagePath = Bundle.main.path(forResource: imageName, ofType: nil, inDirectory: "media"),
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        if let image = UIImage(named: imageName) {
            return image
        }
        return nil
    }

    private func requestToHelp(event: Event) {
        guard let currentUser = authViewModel.currentUser else {
            requestAlertMessage = "Please log in to contact the host."
            requestSuccess = false
            return
        }

        isRequestingHelp = true
        let messageText = "Hi! I'm a \(currentUser.userType.rawValue) and can help at \"\(event.title)\"."

        MessagingService.shared
            .getOrCreateConversation(with: event.hostId)
            .flatMap { convo in
                MessagingService.shared.sendMessage(
                    conversationId: convo.id,
                    receiverId: event.hostId,
                    text: messageText,
                    senderRole: nil
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isRequestingHelp = false
                if case .failure(let error) = completion {
                    requestSuccess = false
                    requestAlertMessage = "Could not send request: \(error.localizedDescription)"
                }
            } receiveValue: { _ in
                requestSuccess = true
                requestAlertMessage = "The host will see your request in their messages."
            }
            .store(in: &cancellables)
    }

    @ViewBuilder
    private func paymentSection(ticketPrice: Double, eventId: String) -> some View {
        let total = totalPrice(for: ticketPrice)
        return paymentActionButton(totalPrice: total, eventId: eventId)
    }

    @ViewBuilder
    private func paymentActionButton(totalPrice: Double, eventId: String) -> some View {
        paymentActionContent(totalPrice: totalPrice, eventId: eventId)
    }

    @ViewBuilder
    private func paymentActionContent(totalPrice: Double, eventId: String) -> some View {
        if let paymentSheet = checkoutViewModel.paymentSheet {
            Button(action: {
                logStripePublishableKey()
                presentPaymentSheet(paymentSheet)
            }) {
                buyButtonLabel(
                    title: "Buy Ticket",
                    subtitle: Helpers.formatCurrency(totalPrice),
                    showsSpinner: false
                )
            }
            .buttonStyle(PlainButtonStyle())
        } else if checkoutViewModel.paymentSheetErrorMessage != nil {
            Button(action: {
                checkoutViewModel.preparePaymentSheet(amount: totalPrice, eventId: eventId)
            }) {
                buyButtonLabel(
                    title: "Tap to retry payment",
                    subtitle: Helpers.formatCurrency(totalPrice),
                    showsSpinner: false
                )
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            buyButtonLabel(
                title: "Preparing payment...",
                subtitle: Helpers.formatCurrency(totalPrice),
                showsSpinner: checkoutViewModel.isPreparingPaymentSheet
            )
        }
    }

    private func presentPaymentSheet(_ paymentSheet: PaymentSheet) {
        guard let viewController = topViewController() else {
            paymentAlertMessage = "Unable to present payment sheet. Please try again."
            return
        }

        paymentSheet.present(from: viewController) { result in
            checkoutViewModel.onPaymentCompletion(result: result)
        }
    }

    private func logStripePublishableKey() {
        let currentKey = StripeAPI.defaultPublishableKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fallbackKey = Constants.Stripe.publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyToLog = currentKey.isEmpty ? fallbackKey : currentKey
        print("Stripe publishable key: \(keyToLog)")
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private func buyButtonLabel(title: String, subtitle: String, showsSpinner: Bool) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            if showsSpinner {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .sioreeWhite))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                Text(subtitle)
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeWhite.opacity(0.8))
            }
            Spacer()
            Image(systemName: "creditcard.fill")
                .foregroundColor(.sioreeWhite)
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.sioreeIcyBlue)
        )
    }

    private func shouldShowBottomAction(for event: Event) -> Bool {
        if isHost {
            return false
        }
        if authViewModel.currentUser?.userType == .talent {
            return true
        }
        if viewModel.isRSVPed || event.isRSVPed {
            return true
        }
        if let price = event.ticketPrice, price > 0 {
            return false
        }
        return true
    }
}

struct RSVPConfirmationView: View {
    let event: Event?
    let qrString: String?
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.l) {
                Spacer()
                
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.sioreeIcyBlue)
                    
                    Text("You're in!")
                        .font(.sioreeH2)
                        .foregroundColor(.sioreeWhite)
                    
                    Text("More information in tickets tab.")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.l)
                }
                
                Spacer()
                
                CustomButton(
                    title: "Close",
                    variant: .primary,
                    size: .large,
                    action: onClose
                )
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sioreeBlack.ignoresSafeArea())
        }
    }
}

#Preview {
    EventDetailView(eventId: "test-id")
}

