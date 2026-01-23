//
//  ProposedRateView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ProposedRateView: View {
    let event: Event
    let onRateProposed: (Double) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var proposedRate = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.l) {
                    // Header
                    VStack(spacing: Theme.Spacing.m) {
                        Text("Propose Rate")
                            .font(.sioreeH2)
                            .foregroundColor(.sioreeWhite)

                        Text("for \(event.title)")
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.l)
                    }

                    // Rate Input
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Rate to Pay if Accepted ($)")
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)

                        HStack {
                            Text("$")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)

                            TextField("0.000", text: $proposedRate)
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                                .keyboardType(.decimalPad)
                                .tint(.sioreeIcyBlue)
                        }
                        .padding(Theme.Spacing.m)
                        .background(Color.sioreeCharcoal.opacity(0.3))
                        .cornerRadius(Theme.CornerRadius.medium)
                    }
                    .padding(.horizontal, Theme.Spacing.l)

                    Spacer()

                    // Action Buttons
                    VStack(spacing: Theme.Spacing.m) {
                        CustomButton(
                            title: isSubmitting ? "Proposing..." : "Propose Rate",
                            variant: .primary,
                            size: .large,
                            action: proposeRate
                        )
                        .disabled(isSubmitting || proposedRate.isEmpty || Double(proposedRate) == nil || (Double(proposedRate) ?? 0) <= 0)

                        CustomButton(
                            title: "Cancel",
                            variant: .secondary,
                            size: .large,
                            action: { dismiss() }
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.l)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func proposeRate() {
        guard let rate = Double(proposedRate), rate > 0 else {
            // Invalid input - should not happen due to button being disabled
            return
        }

        isSubmitting = true

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            onRateProposed(rate)
        }
    }
}

#Preview {
    // Create a mock event for preview
    let mockEvent = Event(
        id: "mock-id",
        title: "Sample Event",
        description: "A sample event for preview",
        hostId: "host-id",
        hostName: "Host Name",
        hostAvatar: nil,
        date: Date(),
        time: Date(),
        location: "Sample Location",
        locationDetails: nil,
        images: [],
        ticketPrice: nil,
        capacity: nil,
        attendeeCount: 0,
        talentIds: [],
        lookingForRoles: [],
        lookingForNotes: nil,
        status: .published,
        createdAt: Date(),
        likes: 0,
        isLiked: false,
        isSaved: false,
        isRSVPed: false,
        qrCode: nil,
        lookingForTalentType: nil,
        isPrivate: false,
        accessCode: nil
    )
    ProposedRateView(event: mockEvent, onRateProposed: { rate in
        print("Proposed rate: $\(rate)")
    })
}