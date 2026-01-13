//
//  EventTalentBookingRow.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct EventTalentBookingRow: View {
    let booking: Booking
    let onAction: () -> Void

    private var statusColor: Color {
        switch booking.status {
        case .requested:
            return .sioreeWarning
        case .accepted:
            return .sioreeIcyBlue
        case .awaiting_payment:
            return .yellow
        case .confirmed:
            return .green
        case .declined:
            return .red
        case .expired:
            return .gray
        case .canceled:
            return .red
        case .completed:
            return .green
        }
    }

    private var statusText: String {
        switch booking.status {
        case .requested:
            return "Requested"
        case .accepted:
            return "Accepted"
        case .awaiting_payment:
            return "Awaiting Payment"
        case .confirmed:
            return "Confirmed"
        case .declined:
            return "Declined"
        case .expired:
            return "Expired"
        case .canceled:
            return "Canceled"
        case .completed:
            return "Completed"
        }
    }

    private var actionButtonTitle: String {
        switch booking.status {
        case .accepted:
            return "Pay to Confirm"
        case .awaiting_payment:
            return "Complete Payment"
        case .confirmed:
            return "Message"
        case .requested:
            return "Cancel Request"
        default:
            return "Message"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.m) {
                // Talent Avatar
                ZStack {
                    if let avatar = booking.talent?.avatar,
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
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.sioreeCharcoal.opacity(0.5))
                            .frame(width: 40, height: 40)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(booking.talent?.name ?? "Unknown Talent")
                            .font(.sioreeH4)
                            .foregroundColor(.white)

                        // Status Badge
                        Text(statusText)
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeBlack)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(statusColor)
                            .clipShape(Capsule())
                    }

                    Text(booking.talent?.category.rawValue ?? "Talent")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeCharcoal.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(booking.price))")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWarning)

                    Text("for \(booking.duration)h")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeCharcoal.opacity(0.7))
                }
            }

            // Action Buttons
            HStack(spacing: Theme.Spacing.s) {
                CustomButton(
                    title: actionButtonTitle,
                    variant: .primary,
                    size: .small
                ) {
                    onAction()
                }

                if booking.status == .requested || booking.status == .accepted {
                    CustomButton(
                        title: "Cancel",
                        variant: .secondary,
                        size: .small
                    ) {
                        // Handle cancel action
                    }
                }

                Spacer()

                // Show date/time if relevant
                if booking.status == .confirmed || booking.status == .completed {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(booking.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                    }
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EventTalentBookingRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()

            let talent = Talent(
                id: "talent1",
                userId: "user1",
                name: "John DJ",
                category: .dj,
                bio: "Professional DJ with 5 years experience",
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

            EventTalentBookingRow(
                booking: Booking(
                    id: "1",
                    eventId: "event1",
                    talentId: "talent1",
                    hostId: "host1",
                    date: Date(),
                    time: Date(),
                    duration: 4,
                    status: .requested,
                    price: 200.0,
                    paymentStatus: .pending,
                    notes: "Looking forward to working together!",
                    createdAt: Date(),
                    talent: talent
                )
            ) {
                // Action handler
            }
            .padding(.horizontal, Theme.Spacing.m)
        }
    }
}
