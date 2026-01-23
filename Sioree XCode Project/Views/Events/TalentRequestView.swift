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
    @State private var cancellables = Set<AnyCancellable>()

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
                                    .foregroundColor(.sioreeWhite)
                            }

                            Spacer()

                            // Placeholder for symmetry
                            Color.clear.frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.top, Theme.Spacing.m)
                    .background(Color.sioreeBlack.opacity(0.8))

                    // Content
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            // Talent Profile Card
                            VStack(spacing: Theme.Spacing.s) {
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
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                                .frame(width: 60, height: 60)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(talent.name)
                                                .font(.sioreeH4)
                                                .foregroundColor(.white)

                                            if talent.verified {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(.sioreeIcyBlue)
                                                    .font(.system(size: 14))
                                            }
                                        }

                                        Text(talent.category.rawValue)
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeIcyBlue)

                                        if let location = talent.location {
                                            HStack(spacing: Theme.Spacing.xs) {
                                                Image(systemName: "mappin")
                                                    .foregroundColor(.sioreeWhite)
                                                    .font(.system(size: 11))

                                                Text(location)
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeWhite)
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 1) {
                                        if talent.priceRange.min == 0 && talent.priceRange.max == 0 {
                                            Text("Rate not set")
                                                .font(.sioreeCaption)
                                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                        } else {
                                            Text("$\(Int(talent.priceRange.min))-\(Int(talent.priceRange.max))")
                                                .font(.sioreeH4)
                                                .foregroundColor(.sioreeIcyBlue)

                                            Text("/hour")
                                                .font(.sioreeCaption)
                                                .foregroundColor(.sioreeWhite)
                                        }
                                    }
                                }

                                if let bio = talent.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.sioreeBodySmall)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.8))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                }
                            }
                            .padding(Theme.Spacing.s)
                            .background(Color.sioreeCharcoal.opacity(0.3))
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
                                                .foregroundColor(.sioreeWhite)

                                            Text(event.location)
                                                .font(.sioreeCaption)
                                                .foregroundColor(.sioreeWhite)
                                        }
                                    }
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeCharcoal.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .padding(.horizontal, Theme.Spacing.m)
                            }

                            // Request Form
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                Divider()
                                    .background(Color.sioreeCharcoal.opacity(0.5))

                                Text("Send Request")
                                    .font(.sioreeH3)
                                    .foregroundColor(.white)
                                    .padding(.top, Theme.Spacing.xs)

                                // Proposed Rate
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Proposed Rate (optional)")
                                        .font(.sioreeBody)
                                        .foregroundColor(.white)

                                    Text("Helps the talent decide faster.")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                    TextField("$0.000", text: $proposedRate)
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
                                    Text("Introduce yourself and explain why you'd like to work with this talent")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)

                                    ZStack(alignment: .topLeading) {
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .fill(Color.sioreeCharcoal.opacity(0.3))
                                            .frame(height: 140)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                    .stroke(Color.sioreeCharcoal.opacity(0.5), lineWidth: 0.5)
                                            )

                                        TextEditor(text: $messageText)
                                            .font(.sioreeBody)
                                            .foregroundColor(.white)
                                            .tint(.sioreeIcyBlue)
                                            .frame(height: 140)
                                            .padding(Theme.Spacing.m)
                                            .scrollContentBackground(.hidden)

                                        if messageText.isEmpty {
                                            Text("Type your message here...")
                                                .font(.sioreeBody)
                                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                                .padding(.horizontal, Theme.Spacing.m)
                                                .padding(.vertical, Theme.Spacing.l)
                                                .allowsHitTesting(false)
                                        }
                                    }

                                    Text("This message is sent directly to the talent.")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.6))
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
                        .disabled(isSending || (messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && proposedRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))

                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
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
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRate = proposedRate.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMessage.isEmpty || !trimmedRate.isEmpty else {
            errorMessage = "Please enter a message or proposed rate"
            return
        }

        isSending = true
        errorMessage = nil

        // Create the talent request
        let proposedRateValue = Double(proposedRate) ?? nil

        let request = TalentRequest(
            hostId: "currentHostId", // TODO: Get from auth view model when available
            talentId: talent.userId,
            eventId: event?.id,
            eventTitle: event?.title,
            message: trimmedMessage.isEmpty ? "Talent request with proposed rate: $\(proposedRateValue ?? 0)" : trimmedMessage,
            proposedRate: proposedRateValue,
            status: .pending
        )

        // In a real implementation, this would call an API to store the request
        // For now, we'll simulate the API call
        networkService.sendTalentRequest(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isSending = false
                    switch completion {
                    case .finished:
                        self.onTalentRequested?(self.talent)
                        // Success - dismiss the view
                    case .failure(let error):
                        self.errorMessage = "Failed to send request: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in
                    // Request sent successfully
                }
            )
            .store(in: &cancellables)
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
        isRSVPed: false,
        qrCode: nil,
        lookingForTalentType: nil
    )

    TalentRequestView(talent: sampleTalent, event: sampleEvent, onTalentRequested: nil)
}
