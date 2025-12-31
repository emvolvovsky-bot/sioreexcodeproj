//
//  TalentRequestView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentRequestView: View {
    let talent: Talent
    let event: Event?
    let onTalentRequested: ((Talent) -> Void)?

    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var proposedRate: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private let networkService = NetworkService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: Theme.Spacing.s) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("Request Talent")
                                    .font(.sioreeH2)
                                    .foregroundColor(.white)

                                Text(talent.name)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            }

                            Spacer()

                            // Placeholder for symmetry
                            Color.clear.frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.top, Theme.Spacing.l)
                    .background(Color.sioreeBlack.opacity(0.8))

                    // Content
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            // Talent Profile Card
                            VStack(spacing: Theme.Spacing.m) {
                                HStack(spacing: Theme.Spacing.m) {
                                    // Avatar
                                    ZStack {
                                        if let avatar = talent.avatar,
                                           let url = URL(string: avatar) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                            }
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                                .frame(width: 80, height: 80)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                        HStack {
                                            Text(talent.name)
                                                .font(.sioreeH3)
                                                .foregroundColor(.white)

                                            if talent.verified {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(.sioreeIcyBlue)
                                                    .font(.system(size: 16))
                                            }
                                        }

                                        Text(talent.category.rawValue)
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeIcyBlue)

                                        HStack(spacing: Theme.Spacing.xs) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.sioreeIcyBlue)
                                                .font(.system(size: 12))

                                            Text(String(format: "%.1f", talent.rating))
                                                .font(.sioreeBody)
                                                .foregroundColor(.white)

                                            Text("(\(talent.reviewCount) reviews)")
                                                .font(.sioreeCaption)
                                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                        }

                                        if let location = talent.location {
                                            HStack(spacing: Theme.Spacing.xs) {
                                                Image(systemName: "mappin")
                                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                                    .font(.system(size: 12))

                                                Text(location)
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(Int(talent.priceRange.min))-\(Int(talent.priceRange.max))")
                                            .font(.sioreeH3)
                                            .foregroundColor(.sioreeIcyBlue)

                                        Text("/hour")
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                    }
                                }

                                if let bio = talent.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.8))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                // Portfolio preview (if available)
                                if !talent.portfolio.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Theme.Spacing.s) {
                                            ForEach(talent.portfolio.prefix(3), id: \.self) { imageUrl in
                                                if let url = URL(string: imageUrl) {
                                                    AsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                    } placeholder: {
                                                        Color.sioreeCharcoal.opacity(0.3)
                                                    }
                                                    .frame(width: 80, height: 80)
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeCharcoal.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.medium)
                            .padding(.horizontal, Theme.Spacing.m)

                            // Event Context (if provided)
                            if let event = event {
                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                    Text("Requesting for Event")
                                        .font(.sioreeH4)
                                        .foregroundColor(.white)

                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.title)
                                                .font(.sioreeBody)
                                                .foregroundColor(.sioreeIcyBlue)

                                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.sioreeCaption)
                                                .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                            Text(event.location)
                                                .font(.sioreeCaption)
                                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                        }
                                    }
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeCharcoal.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .padding(.horizontal, Theme.Spacing.m)
                            }

                            // Request Form
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Send Request")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                // Proposed Rate
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Proposed Rate (optional)")
                                        .font(.sioreeBody)
                                        .foregroundColor(.white)

                                    TextField("e.g. $50/hour", text: $proposedRate)
                                        .font(.sioreeBody)
                                        .foregroundColor(.white)
                                        .tint(.sioreeIcyBlue)
                                        .keyboardType(.decimalPad)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeCharcoal.opacity(0.3))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                }

                                // Message
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Message to Talent")
                                        .font(.sioreeBody)
                                        .foregroundColor(.white)

                                    ZStack(alignment: .topLeading) {
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .fill(Color.sioreeCharcoal.opacity(0.3))
                                            .frame(height: 120)

                                        TextEditor(text: $messageText)
                                            .font(.sioreeBody)
                                            .foregroundColor(.white)
                                            .tint(.sioreeIcyBlue)
                                            .frame(height: 120)
                                            .padding(Theme.Spacing.m)
                                            .scrollContentBackground(.hidden)

                                        if messageText.isEmpty {
                                            Text("Introduce yourself and explain why you'd like to work with this talent...")
                                                .font(.sioreeBody)
                                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                                .padding(.horizontal, Theme.Spacing.m)
                                                .padding(.vertical, Theme.Spacing.l)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                }

                                if let error = errorMessage {
                                    Text(error)
                                        .font(.sioreeCaption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)

                            Spacer()
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }

                    // Send Request Button
                    VStack(spacing: Theme.Spacing.m) {
                        CustomButton(
                            title: isSending ? "Sending Request..." : "Send Talent Request",
                            variant: .primary,
                            size: .large
                        ) {
                            sendTalentRequest()
                        }
                        .disabled(isSending || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.l)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func sendTalentRequest() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a message"
            return
        }

        isSending = true
        errorMessage = nil

        // For now, simulate sending the request
        // In a real implementation, this would call an API to create a talent request
        // The request would be stored and the talent would receive a notification

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSending = false
            onTalentRequested?(talent)
            // Success feedback could be added here
        }
    }
}

#Preview {
    let sampleTalent = Talent(
        id: "talent1",
        userId: "user1",
        name: "John DJ",
        category: .dj,
        bio: "Professional DJ with 5 years experience specializing in house music and event entertainment.",
        avatar: nil,
        portfolio: [],
        rating: 4.5,
        reviewCount: 12,
        priceRange: PriceRange(min: 150, max: 300),
        availability: [],
        verified: true,
        location: "New York, NY",
        createdAt: Date()
    )

    let sampleEvent = Event(
        id: "event1",
        title: "Summer Music Festival",
        description: "A great outdoor music event",
        hostId: "host1",
        hostName: "Festival Productions",
        hostAvatar: nil,
        date: Date(),
        time: Date(),
        location: "Central Park, NYC",
        locationDetails: "40.7829,-73.9654",
        images: [],
        ticketPrice: 50,
        capacity: 1000,
        attendeeCount: 0,
        talentIds: [],
        lookingForRoles: ["DJ", "Bartender"],
        lookingForNotes: "Looking for experienced talent",
        status: .published,
        createdAt: Date(),
        likes: 0,
        isLiked: false,
        isSaved: false,
        isFeatured: false,
        isRSVPed: false,
        qrCode: nil,
        lookingForTalentType: nil
    )

    TalentRequestView(talent: sampleTalent, event: sampleEvent, onTalentRequested: nil)
}
