//
//  PartierMapView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import CoreLocation

struct PartierMapView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Default to LA
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedEvent: Event?
    @State private var selectedDate: Date? = nil
    @State private var showDatePicker = false

    // All events combined from featured and nearby
    private var allEvents: [Event] {
        let featured = viewModel.featuredEvents
        let nearby = viewModel.nearbyEvents
        return featured + nearby
    }

    // Filtered events based on selected date
    private var filteredEvents: [Event] {
        guard let selectedDate = selectedDate else {
            return allEvents
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        return allEvents.filter { event in
            let eventDate = calendar.startOfDay(for: event.date)
            return eventDate >= startOfDay && eventDate < endOfDay
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: filteredEvents) { event in
                MapAnnotation(coordinate: coordinateForEvent(event)) {
                    EventDetailMapPinView(event: event) {
                        selectedEvent = event
                    }
                }
                }
                .ignoresSafeArea()
                .onAppear {
                    requestLocationPermission()
                    centerOnEventsIfNeeded()
                }
                .onReceive(locationManager.$location.compactMap { $0 }) { location in
                    if selectedDate == nil { // Only auto-center if no date filter is active
                        withAnimation {
                            region.center = location
                            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        }
                    }
                }

                // Top overlay with controls
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.sioreeWhite)
                                .frame(width: 32, height: 32)
                                .background(Color.sioreeBlack.opacity(0.7))
                                .cornerRadius(Theme.CornerRadius.medium)
                        }

                        Spacer()

                        // Date filter button
                        Button(action: { showDatePicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                Text(selectedDate?.formatted(date: .abbreviated, time: .omitted) ?? "All Dates")
                                    .font(.sioreeCaption)
                            }
                            .foregroundColor(Color.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.s)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Color.sioreeBlack.opacity(0.7))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }

                        if selectedDate != nil {
                            Button(action: { clearDateFilter() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.sioreeLightGrey)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)

                    Spacer()

                    // Bottom controls
                    HStack {
                        Spacer()

                        VStack(spacing: Theme.Spacing.s) {
                            // Location button
                            Button(action: { centerOnUserLocation() }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.sioreeWhite)
                                    .frame(width: 44, height: 44)
                                    .background(Color.sioreeIcyBlue)
                                    .cornerRadius(Theme.CornerRadius.medium)
                            }

                            // Center on events button
                            Button(action: { centerOnEvents() }) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.sioreeWhite)
                                    .frame(width: 44, height: 44)
                                    .background(Color.sioreeWarmGlow)
                                    .cornerRadius(Theme.CornerRadius.medium)
                            }
                        }
                        .padding(.trailing, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.m)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedEvent) { event in
                EventDetailView(eventId: event.id)
            }
            .sheet(isPresented: $showDatePicker) {
                DateFilterView(selectedDate: $selectedDate) {
                    applyDateFilter()
                }
            }
        }
    }

    private func coordinateForEvent(_ event: Event) -> CLLocationCoordinate2D {
        // Generate coordinates based on event location string
        let hash = abs(event.location.hashValue)
        let baseLat = region.center.latitude
        let baseLon = region.center.longitude

        // Spread events around the center with some randomness
        let latOffset = Double(hash % 100) / 10000.0 - 0.005
        let lonOffset = Double((hash / 100) % 100) / 10000.0 - 0.005

        return CLLocationCoordinate2D(latitude: baseLat + latOffset, longitude: baseLon + lonOffset)
    }

    private func requestLocationPermission() {
        locationManager.requestLocation()
    }

    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation {
                region.center = location
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        }
    }

    private func centerOnEvents() {
        guard !filteredEvents.isEmpty else { return }

        let coordinates = filteredEvents.map { coordinateForEvent($0) }
        let minLat = coordinates.map { $0.latitude }.min() ?? region.center.latitude
        let maxLat = coordinates.map { $0.latitude }.max() ?? region.center.latitude
        let minLon = coordinates.map { $0.longitude }.min() ?? region.center.longitude
        let maxLon = coordinates.map { $0.longitude }.max() ?? region.center.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = abs(maxLat - minLat) * 1.2 + 0.01 // Add some padding
        let lonDelta = abs(maxLon - minLon) * 1.2 + 0.01

        withAnimation {
            region.center = center
            region.span = MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        }
    }

    private func centerOnEventsIfNeeded() {
        if !filteredEvents.isEmpty && selectedDate == nil {
            // Small delay to ensure map is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                centerOnEvents()
            }
        }
    }

    private func applyDateFilter() {
        // Re-center on filtered events if we have a date filter
        if selectedDate != nil && !filteredEvents.isEmpty {
            centerOnEvents()
        } else if selectedDate == nil {
            // Clear filter - center on user location if available
            if let location = locationManager.location {
                withAnimation {
                    region.center = location
                    region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                }
            }
        }
    }

    private func clearDateFilter() {
        selectedDate = nil
        applyDateFilter()
    }
}

struct EventDetailMapPinView: View {
    let event: Event
    let action: () -> Void

    private var priceText: String {
        if let price = event.ticketPrice, price > 0 {
            return String(format: "$%.0f", price)
        }
        return "FREE"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Event info bubble
                VStack(spacing: 2) {
                    Text(event.title)
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeWhite)
                        .lineLimit(1)
                        .frame(maxWidth: 120)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 8))
                        Text(event.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color.sioreeLightGrey)

                    Text(priceText)
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeIcyBlue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.sioreeBlack.opacity(0.9))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.sioreeIcyBlue.opacity(0.5), lineWidth: 1)
                )

                // Pin point
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.sioreeWhite)
                    .frame(width: 24, height: 24)
                    .background(Color.sioreeIcyBlue)
                    .cornerRadius(12)

                // Triangle pointer
                Triangle()
                    .fill(Color.sioreeIcyBlue)
                    .frame(width: 8, height: 8)
            }
        }
    }
}


#Preview {
    PartierMapView(viewModel: HomeViewModel(), locationManager: LocationManager())
}
