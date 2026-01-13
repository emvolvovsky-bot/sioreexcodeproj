//
//  EventTalentMarketplaceView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct EventTalentMarketplaceView: View {
    let event: Event
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TalentViewModel()
    @State private var selectedFilter: String = "All"
    @State private var searchText: String = ""
    @State private var searchWorkItem: DispatchWorkItem?
    @State private var selectedTalent: Talent?
    @State private var showTalentDetail = false
    @State private var showBookingRequest = false
    @Environment(\.dismiss) var dismiss

    private var filterOptions: [String] {
        ["All"] + event.lookingForRoles.filter { !$0.isEmpty }
    }

    private var filteredTalent: [Talent] {
        let talents = viewModel.talent.filter { talent in
            // Only show talent that matches the event's looking for roles
            if !event.lookingForRoles.isEmpty {
                let talentCategory = talent.category.rawValue.lowercased()
                let matchesRole = event.lookingForRoles.contains { role in
                    role.lowercased().contains(talentCategory) ||
                    talentCategory.contains(role.lowercased())
                }
                if !matchesRole { return false }
            }

            // Apply search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return talent.name.lowercased().contains(searchLower) ||
                       talent.category.rawValue.lowercased().contains(searchLower) ||
                       (talent.bio?.lowercased().contains(searchLower) ?? false) ||
                       (talent.location?.lowercased().contains(searchLower) ?? false)
            }

            return true
        }

        return talents
    }

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
                                Text("Find Talent")
                                    .font(.sioreeH2)
                                    .foregroundColor(.white)

                                Text("for \(event.title)")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Placeholder for symmetry
                            Color.clear.frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.m)

                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                .font(.system(size: 16))

                            TextField("Search talent...", text: $searchText)
                                .font(.sioreeBody)
                                .foregroundColor(.white)
                                .tint(.sioreeWarning)
                                .onChange(of: searchText) { newValue in
                                    searchWorkItem?.cancel()
                                    let workItem = DispatchWorkItem {
                                        // Debounced search
                                    }
                                    searchWorkItem = workItem
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
                                }

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.sioreeCharcoal.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, Theme.Spacing.m)

                        // Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.s) {
                                ForEach(filterOptions, id: \.self) { filter in
                                    FilterPill(
                                        title: filter,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                    .padding(.top, Theme.Spacing.l)
                    .background(Color.sioreeBlack.opacity(0.8))

                    // Talent List
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.s) {
                            ForEach(filteredTalent) { talent in
                                TalentRequestCard(
                                    talent: talent,
                                    event: event
                                ) {
                                    selectedTalent = talent
                                    showBookingRequest = true
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showBookingRequest) {
                if let talent = selectedTalent {
                    BookingRequestView(event: event, talent: talent)
                }
            }
            .onAppear {
                viewModel.loadTalent()
            }
        }
    }
}

struct TalentRequestCard: View {
    let talent: Talent
    let event: Event
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
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
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.sioreeCharcoal.opacity(0.5))
                            .frame(width: 50, height: 50)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(talent.name)
                            .font(.sioreeH4)
                            .foregroundColor(.white)

                        if talent.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.sioreeWarning)
                                .font(.system(size: 12))
                        }
                    }

                    Text(talent.category.rawValue)
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeCharcoal.opacity(0.7))

                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.sioreeWarning)
                            .font(.system(size: 12))

                        Text(String(format: "%.1f", talent.rating))
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                        Text("(\(talent.reviewCount))")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                        if let location = talent.location {
                            Text("•")
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))

                            Text(location)
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(talent.priceRange.min))-\(Int(talent.priceRange.max))")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWarning)

                    Text("/hour")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeCharcoal.opacity(0.7))
                }
            }

            if let bio = talent.bio, !bio.isEmpty {
                Text(bio)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeCharcoal.opacity(0.8))
                    .lineLimit(2)
            }

            // Request Button
            CustomButton(
                title: "Send Request",
                variant: .primary,
                size: .medium
            ) {
                onRequest()
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sioreeCaption)
                .foregroundColor(isSelected ? .sioreeBlack : .white)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.xs)
                .background(isSelected ? Color.sioreeWarning : Color.sioreeCharcoal.opacity(0.3))
                .clipShape(Capsule())
        }
    }
}

struct BookingRequestView: View {
    let event: Event
    let talent: Talent
    @Environment(\.dismiss) var dismiss
    @State private var duration: Int = 4
    @State private var price: Double = 0
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.l) {
                    // Header
                    Text("Booking Request")
                        .font(.sioreeH2)
                        .foregroundColor(.white)

                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            // Event Summary
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Event")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeWarning)

                                        Text("\(event.date.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeCharcoal.opacity(0.7))

                                        Text(event.location)
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                    }

                                    Spacer()
                                }
                            }
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeCharcoal.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Talent Summary
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Talent")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                HStack {
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
                                        Text(talent.name)
                                            .font(.sioreeBody)
                                            .foregroundColor(.white)

                                        Text(talent.category.rawValue)
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeCharcoal.opacity(0.7))
                                    }

                                    Spacer()

                                    Text("$\(Int(talent.priceRange.min))-\(Int(talent.priceRange.max))/hr")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWarning)
                                }
                            }
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeCharcoal.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Duration
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Duration (hours)")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                HStack {
                                    ForEach([2, 4, 6, 8], id: \.self) { hours in
                                        DurationButton(
                                            hours: hours,
                                            isSelected: duration == hours
                                        ) {
                                            duration = hours
                                            updatePrice()
                                        }
                                    }
                                }
                            }

                            // Price
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Offered Price")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                TextField("Enter price", value: $price, format: .currency(code: "USD"))
                                    .font(.sioreeBody)
                                    .foregroundColor(.white)
                                    .tint(.sioreeWarning)
                                    .keyboardType(.decimalPad)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeCharcoal.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onChange(of: price) { newValue in
                                        if newValue < 0 { price = 0 }
                                    }
                            }

                            // Notes
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Message (Optional)")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                TextEditor(text: $notes)
                                    .font(.sioreeBody)
                                    .foregroundColor(.white)
                                    .tint(.sioreeWarning)
                                    .frame(height: 100)
                                    .padding(Theme.Spacing.s)
                                    .background(Color.sioreeCharcoal.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .placeholder(when: notes.isEmpty) {
                                        Text("Add a message to your booking request...")
                                            .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                    }
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }

                    Spacer()

                    // Submit Button
                    VStack(spacing: Theme.Spacing.m) {
                        CustomButton(
                            title: isSubmitting ? "Sending Request..." : "Send Booking Request",
                            variant: .primary,
                            size: .large
                        ) {
                            submitBookingRequest()
                        }
                        .disabled(isSubmitting || price <= 0)

                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeCharcoal.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                }
                .padding(.top, Theme.Spacing.l)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            updatePrice()
        }
    }

    private func updatePrice() {
        let basePrice = Double(talent.priceRange.min + talent.priceRange.max) / 2.0
        price = basePrice * Double(duration)
    }

    private func submitBookingRequest() {
        guard price > 0 else {
            errorMessage = "Please enter a valid price"
            return
        }

        isSubmitting = true
        errorMessage = nil

        // TODO: Implement API call to create booking
        // For now, just simulate success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            dismiss()
            // TODO: Show success message
        }
    }
}

struct DurationButton: View {
    let hours: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(hours)h")
                .font(.sioreeBody)
                .foregroundColor(isSelected ? .sioreeBlack : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.s)
                .background(isSelected ? Color.sioreeWarning : Color.sioreeCharcoal.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
