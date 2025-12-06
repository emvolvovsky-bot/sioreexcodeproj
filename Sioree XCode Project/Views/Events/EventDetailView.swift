//
//  EventDetailView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct EventDetailView: View {
    let eventId: String
    @StateObject private var viewModel: EventViewModel
    @Environment(\.dismiss) var dismiss
    
    init(eventId: String) {
        self.eventId = eventId
        _viewModel = StateObject(wrappedValue: EventViewModel(eventId: eventId))
    }
    
    var body: some View {
        ZStack {
            // White to grey gradient for light mode
            LinearGradient(
                colors: [Color(white: 0.98), Color(white: 0.95), Color(white: 0.92)],
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
                                    .foregroundColor(Color.sioreeCharcoal)
                                
                                NavigationLink(destination: UserProfileView(userId: event.hostId)) {
                                    HStack(spacing: Theme.Spacing.s) {
                                        AvatarView(imageURL: event.hostAvatar, size: .small)
                                        Text(event.hostName)
                                            .font(.sioreeBody)
                                            .foregroundColor(Color.sioreeCharcoal)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.sioreeIcyBlue)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                
                                // Brand promotion info (if featured)
                                if event.isFeatured {
                                    HStack(spacing: Theme.Spacing.s) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.sioreeWarmGlow)
                                        Text("Promoted by Brand")
                                            .font(.sioreeCaption)
                                            .foregroundColor(Color.sioreeCharcoal.opacity(0.7))
                                        Spacer()
                                    }
                                    .padding(Theme.Spacing.s)
                                    .background(Color.sioreeIcyBlue.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.small)
                                }
                                
                                // Message Host Button (for partiers)
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
                                        .foregroundColor(Color.sioreeCharcoal)
                                    
                                    // Place
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                            Text("Location")
                                                .font(.sioreeCaption)
                                                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                                            Text(event.location)
                                                .font(.sioreeBody)
                                                .foregroundColor(Color.sioreeCharcoal)
                                            if let locationDetails = event.locationDetails, !locationDetails.isEmpty {
                                                Text(locationDetails)
                                                    .font(.sioreeBodySmall)
                                                    .foregroundColor(Color.sioreeCharcoal.opacity(0.7))
                                                    .padding(.top, 2)
                                            }
                                        }
                                    }
                                    
                                    // Time
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                            Text("Date & Time")
                                                .font(.sioreeCaption)
                                                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                                            Text("\(event.date.formattedEventDate()) at \(event.time.formattedEventTime())")
                                                .font(.sioreeBody)
                                                .foregroundColor(Color.sioreeCharcoal)
                                        }
                                    }
                                    
                                    // Price
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                            Text("Price")
                                                .font(.sioreeCaption)
                                                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                                            if let price = event.ticketPrice, price > 0 {
                                                Text(Helpers.formatCurrency(price))
                                                    .font(.sioreeBody)
                                                    .foregroundColor(Color.sioreeCharcoal)
                                            } else {
                                                Text("Free")
                                                    .font(.sioreeBody)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                    
                                    // Attendees
                                    NavigationLink(destination: EventAttendeesView(eventId: event.id, eventName: event.title)) {
                                        HStack(spacing: Theme.Spacing.m) {
                                            Image(systemName: "person.3.fill")
                                                .foregroundColor(.sioreeIcyBlue)
                                                .frame(width: 24)
                                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                                Text("Attendees")
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
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
                                
                                Divider()
                                
                                // Description
                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                    Text("About")
                                        .font(.sioreeH3)
                                        .foregroundColor(Color.sioreeCharcoal)
                                    Text(event.description.isEmpty ? "No description provided." : event.description)
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeCharcoal.opacity(0.8))
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
                                                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                                            Text("\(event.attendeeCount) / \(capacity) spots")
                                                .font(.sioreeBody)
                                                .foregroundColor(Color.sioreeCharcoal)
                                        }
                                        Spacer()
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
                                if viewModel.isRSVPed {
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
                                    viewModel.rsvpToEvent()
                                    viewModel.showPaymentCheckout = false
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
                                .foregroundColor(.sioreeCharcoal)
                            Text(errorMessage)
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.l)
                        } else {
                            Text("Event not found")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeCharcoal)
                            Text("This event may have been removed or doesn't exist.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
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
        }
    }
    
    private func getImageFromBundle(_ imageName: String) -> UIImage? {
        // Try to load from media folder
        if let imagePath = Bundle.main.path(forResource: imageName, ofType: nil, inDirectory: "media"),
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        // Try without directory
        if let image = UIImage(named: imageName) {
            return image
        }
        return nil
    }


#Preview {
    EventDetailView(eventId: "test-id")
}

