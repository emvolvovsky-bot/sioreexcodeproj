//
//  EventDetailView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import UIKit
import Combine

struct EventDetailView: View {
    let eventId: String
    let isTalentMapMode: Bool
    @StateObject private var viewModel: EventViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showLocationActionSheet = false
    @State private var showTalentBrowser = false
    // Talent → request-to-help state
    @State private var isRequestingHelp = false
    @State private var requestAlertMessage: String?
    @State private var requestSuccess = false
    @State private var cancellables = Set<AnyCancellable>()
    
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
            // Dark gradient background
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if let event = viewModel.event {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Hero Image with real images or placeholder
                            ZStack {
                                if let firstImage = event.images.first, !firstImage.isEmpty {
                                    AsyncImage(url: URL(string: firstImage)) { phase in
                                        switch phase {
                                        case .empty:
                                            Rectangle()
                                                .fill(Color.sioreeLightGrey.opacity(0.3))
                                                .frame(height: 300)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 300)
                                                .clipped()
                                        case .failure:
                                            Rectangle()
                                                .fill(Color.sioreeLightGrey.opacity(0.3))
                                                .frame(height: 300)
                                        @unknown default:
                                            Rectangle()
                                                .fill(Color.sioreeLightGrey.opacity(0.3))
                                                .frame(height: 300)
                                        }
                                    }
                                } else {
                                    // Enhanced placeholder with gradient
                                    ZStack {
                                        LinearGradient(
                                            colors: [
                                                Color.sioreeIcyBlue.opacity(0.3),
                                                Color.sioreeWarmGlow.opacity(0.2),
                                                Color.sioreeIcyBlue.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        
                                        Image(systemName: "party.popper.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                    }
                                    .frame(height: 300)
                                }
                                
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
                                Text(event.title)
                                    .font(.sioreeH1)
                                    .foregroundColor(.sioreeWhite)

                                if !isTalentMapMode, let need = event.lookingForSummary ?? event.lookingForTalentType, !need.isEmpty {
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
                                
                                NavigationLink(destination: UserProfileView(userId: event.hostId)) {
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
                                
                                // Brand promotion info (if featured)
                                if !isTalentMapMode, event.isFeatured {
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
                                
                                // Message Host Button
                                NavigationLink(destination: UserProfileView(userId: event.hostId)) {
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
                                        // Price
                                        HStack(spacing: Theme.Spacing.m) {
                                            Image(systemName: "dollarsign.circle.fill")
                                                .foregroundColor(.sioreeIcyBlue)
                                                .frame(width: 24)
                                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                                Text("Price")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeWhite.opacity(0.7))
                                                if let price = event.ticketPrice, price > 0 {
                                                    Text(Helpers.formatCurrency(price))
                                                        .font(.sioreeBody)
                                                        .foregroundColor(.sioreeWhite)
                                                } else {
                                                    Text("Free")
                                                        .font(.sioreeBody)
                                                        .foregroundColor(.green)
                                                }
                                            }
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
                    .safeAreaInset(edge: .bottom) {
                        // Sticky RSVP/Pay Button
                        VStack(spacing: 0) {
                            Divider()
                            Group {
                                // Host controls
                                if isHost {
                                    VStack(spacing: Theme.Spacing.s) {
                                        Text("You are the host of this event")
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                        CustomButton(
                                            title: "Request Talent",
                                            variant: .primary,
                                            size: .medium
                                        ) {
                                            showTalentBrowser = true
                                        }
                                    }
                                    .padding(.vertical, Theme.Spacing.m)
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
                                } else if let price = event.ticketPrice, price > 0 {
                                    CustomButton(
                                        title: "Buy",
                                        variant: .primary,
                                        size: .large
                                    ) {
                                        viewModel.showPaymentCheckout = true
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
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeWhite)
                        }
                    }
                    .sheet(isPresented: $viewModel.showPaymentCheckout) {
                        if let price = event.ticketPrice {
                            PaymentCheckoutView(
                                amount: price,
                                description: "Ticket for \(event.title)",
                                bookingId: nil,
                                onPaymentSuccess: { payment in
                                    // After successful payment, RSVP to event
                                    // This will add user to event_attendees and move event to "Upcoming"
                                    viewModel.showPaymentCheckout = false
                                    // Small delay to ensure payment is processed
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        viewModel.rsvpToEvent()
                                    }
                                }
                            )
                        }
                    }
                } else if viewModel.isLoading {
                    LoadingView()
                } else {
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
        }

    // MARK: - Helpers
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
}

struct RSVPConfirmationView: View {
    let event: Event?
    let qrString: String?
    let onClose: () -> Void
    
    private var qrImage: UIImage? {
        let content = qrString ?? event?.qrCode ?? (event != nil ? "sioree:event:\(event!.id)" : nil)
        guard let content else { return nil }
        return QRCodeService.shared.generateQRCode(from: content, size: CGSize(width: 240, height: 240))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.l) {
                Spacer()
                
                VStack(spacing: Theme.Spacing.s) {
                    Text("You’re in!")
                        .font(.sioreeH2)
                        .foregroundColor(.sioreeWhite)
                    Text("View your tickets in the Tickets tab.")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeLightGrey)
                        .multilineTextAlignment(.center)
                }
                
                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                } else {
                    Image(systemName: "qrcode")
                        .font(.system(size: 80))
                        .foregroundColor(.sioreeIcyBlue)
                        .padding()
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(16)
                }
                
                if let title = event?.title {
                    Text(title)
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.m)
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

