//
//  PartierHomeView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import CoreLocation
import UIKit

struct PartierHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showDatePicker = false
    @State private var selectedTab: HomeTab = .featured
    
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        tabPicker
                        tabContent
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showDatePicker) {
                DateFilterView(selectedDate: $viewModel.selectedDate) {
                    viewModel.applyDateFilter()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showDatePicker = true }) {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
            }
            .onAppear {
                viewModel.loadEvents(userLocation: locationManager.location)
                locationManager.requestLocation()
            }
            .onReceive(locationManager.$location.compactMap { $0 }) { coordinate in
                applyLocationIfChanged(coordinate)
            }
        }
    }
}

private extension PartierHomeView {
    var tabPicker: some View {
        Picker("Home Tab", selection: $selectedTab) {
            Text(HomeTab.featured.title).tag(HomeTab.featured)
            Text(HomeTab.nearby.title).tag(HomeTab.nearby)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.m)
    }
    
    @ViewBuilder
    var tabContent: some View {
        if viewModel.isLoading && !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxl)
        } else if selectedTab == .nearby && !locationAllowed {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: "location.slash")
                    .font(.system(size: 64))
                    .foregroundColor(Color.sioreeLightGrey)
                Text("Enable location in Settings to see events near you")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                    .multilineTextAlignment(.center)
                Button(action: openSettings) {
                    Text("Open Settings")
                        .font(.sioreeBody)
                        .foregroundColor(.sioreeWhite)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.sioreeIcyBlue)
                        .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xxl)
        } else if featuredDataSource.isEmpty && nearbyDataSource.isEmpty && viewModel.hasLoaded {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 64))
                    .foregroundColor(Color.sioreeLightGrey)
                Text("No events yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Check back later for new parties")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xxl)
        } else {
            switch selectedTab {
            case .featured:
                featuredList
            case .nearby:
                nearbyList
            }
        }
    }
    
    var featuredList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            ForEach(groupEventsByDay(featuredDataSource), id: \.date) { group in
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack {
                        Text(dayLabel(for: group.date))
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)
                        Spacer()
                        Label("Verified hosts & talents", systemImage: "checkmark.seal.fill")
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                    Divider()
                        .background(Color.sioreeLightGrey.opacity(0.4))
                    
                    LazyVStack(spacing: Theme.Spacing.s) {
                        ForEach(group.events) { event in
                            NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                HomeEventListRow(
                                    event: event,
                                    accentColor: Color.sioreeIcyBlue
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
    }
    
    var nearbyList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            ForEach(groupEventsByDay(nearbyDataSource), id: \.date) { group in
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack {
                        Text(dayLabel(for: group.date))
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)
                        Spacer()
                        Label("Close by", systemImage: "mappin.and.ellipse")
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeWarmGlow)
                    }
                    Divider()
                        .background(Color.sioreeLightGrey.opacity(0.4))
                    
                    LazyVStack(spacing: Theme.Spacing.s) {
                        ForEach(group.events) { event in
                            NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                HomeEventListRow(
                                    event: event,
                                    accentColor: Color.sioreeWarmGlow
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
    }
    
    var filteredNearbyEvents: [Event] {
        let currentUserId = authViewModel.currentUser?.id
        return viewModel.nearbyEvents.filter { event in
            guard let currentUserId else { return true }
            return event.hostId != currentUserId
        }
    }
    
    var featuredDataSource: [Event] {
        if !viewModel.featuredEvents.isEmpty {
            return viewModel.featuredEvents
        }
        return viewModel.hasLoaded ? viewModel.generatePlaceholderFeaturedEvents() : []
    }
    
    var nearbyDataSource: [Event] {
        if !filteredNearbyEvents.isEmpty {
            return filteredNearbyEvents
        }
        return viewModel.hasLoaded ? viewModel.generatePlaceholderNearbyEvents() : []
    }
    
    func groupEventsByDay(_ events: [Event]) -> [(date: Date, events: [Event])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.date) }
        let sortedDates = grouped.keys.sorted()
        return sortedDates.map { date in
            let dailyEvents = grouped[date]?.sorted(by: { $0.date < $1.date }) ?? []
            return (date: date, events: dailyEvents)
        }
    }
    
    func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    func applyLocationIfChanged(_ coordinate: CLLocationCoordinate2D) {
        if let existing = viewModel.lastKnownCoordinate {
            let latDiff = abs(existing.latitude - coordinate.latitude)
            let lonDiff = abs(existing.longitude - coordinate.longitude)
            if latDiff < 0.0005 && lonDiff < 0.0005 { return }
        }
        viewModel.loadEvents(userLocation: coordinate)
    }
    
    var locationAllowed: Bool {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

private enum HomeTab: String {
    case featured
    case nearby
    
    var title: String {
        switch self {
        case .featured:
            return "Featured"
        case .nearby:
            return "Near You"
        }
    }
}

private struct HomeEventListRow: View {
    let event: Event
    let accentColor: Color
    
    private var priceText: String {
        if let price = event.ticketPrice, price > 0 {
            return String(format: "$%.0f", price)
        }
        return "FREE"
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.sioreeBlack.opacity(0.75))
                .overlay(
                    LinearGradient(
                        colors: [accentColor.opacity(0.15), Color.sioreeCharcoal.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(Theme.CornerRadius.medium)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(accentColor.opacity(0.35), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 8) {
                            Label(event.hostName, systemImage: "checkmark.seal.fill")
                                .font(.sioreeCaption)
                                .foregroundColor(accentColor)
                                .lineLimit(1)
                            
                            Text("•")
                                .foregroundColor(.sioreeLightGrey.opacity(0.6))
                            
                            Text(event.location)
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text(priceText)
                        .font(.sioreeH4)
                        .foregroundColor(accentColor)
                }
                
                HStack {
                    Label(event.date.formatted(date: .omitted, time: .shortened), systemImage: "clock.fill")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                    Spacer()
                    if let lookingFor = event.lookingForSummary {
                        Label(lookingFor, systemImage: "music.mic")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                            .lineLimit(1)
                    }
                }
            }
            .padding(Theme.Spacing.m)
        }
    }
}

// Date Filter View
struct DateFilterView: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) var dismiss
    let onDateSelected: () -> Void
    @State private var tempDate: Date = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.l) {
                    Text("Select Event Date")
                        .font(.sioreeH3)
                        .foregroundColor(.sioreeWhite)
                        .padding(.top, Theme.Spacing.l)
                    
                    DatePicker(
                        "Event Date",
                        selection: $tempDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.sioreeIcyBlue)
                    .padding()
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, Theme.Spacing.m)
                    
                    HStack(spacing: Theme.Spacing.m) {
                        Button(action: {
                            selectedDate = nil
                            onDateSelected()
                            dismiss()
                        }) {
                            Text("Clear Filter")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.medium)
                        }
                        
                        Button(action: {
                            selectedDate = tempDate
                            onDateSelected()
                            dismiss()
                        }) {
                            Text("Apply Filter")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(
                                    LinearGradient(
                                        colors: [Color.sioreeIcyBlue.opacity(0.8), Color.sioreeIcyBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(Theme.CornerRadius.medium)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.m)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDate = tempDate
                        onDateSelected()
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
        .onAppear {
            tempDate = selectedDate ?? Date()
        }
    }
}

#Preview {
    PartierHomeView()
}


