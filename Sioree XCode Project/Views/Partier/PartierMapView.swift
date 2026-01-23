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
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Default to LA, will be updated to user location
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var hasCenteredOnUserLocation = false
    @State private var selectedEvent: Event?
    @State private var selectedDate: Date? = nil
    @State private var showDatePicker = false

    // All events (nearby only, featured removed)
    private var allEvents: [Event] {
        return viewModel.nearbyEvents
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
                    // Small delay to allow location permission and initial location fetch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        centerOnUserLocationInitially()
                    }
                }
                .onReceive(locationManager.$location.compactMap { $0 }) { location in
                    // Only update region if we haven't centered on user location yet
                    if !hasCenteredOnUserLocation && selectedDate == nil {
                        withAnimation {
                            region.center = location
                            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        }
                        hasCenteredOnUserLocation = true
                    }
                }

                // Calendar filter button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showDatePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.sioreeBlack.opacity(0.8))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "calendar")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.system(size: 20, weight: .medium))
                            }
                            .shadow(radius: 4)
                        }
                        .padding(.top, Theme.Spacing.m)
                        .padding(.trailing, Theme.Spacing.m)
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedEvent) { event in
                EventDetailView(eventId: event.id)
            }
            .sheet(isPresented: $showDatePicker) {
                ZStack {
                    Color.sioreeBlack.ignoresSafeArea()

                    VStack(spacing: Theme.Spacing.xl) {
                        HStack {
                            Spacer()
                            Button(action: { showDatePicker = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .medium))
                            }
                        }
                        .padding(.top, Theme.Spacing.m)
                        .padding(.trailing, Theme.Spacing.m)

                        DatePicker(
                            "Select Date",
                            selection: Binding(
                                get: { selectedDate ?? Date() },
                                set: { selectedDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark)
                        .accentColor(.sioreeIcyBlue)
                        .padding(.horizontal, Theme.Spacing.m)

                        Spacer()
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func coordinateForEvent(_ event: Event) -> CLLocationCoordinate2D {
        // Generate stable coordinates based on event location string hash
        // Use a fixed reference point to ensure events don't move when map scrolls
        let hash = abs(event.location.hashValue)

        // Use user location as base if available, otherwise use default LA coordinates
        let baseCoordinate = locationManager.location ??
                            CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

        // Create a deterministic but spread-out distribution around the base coordinate
        // This ensures events stay in the same location regardless of map scrolling
        let latOffset = Double((hash % 200) - 100) / 10000.0  // +/- 0.01 degrees latitude
        let lonOffset = Double(((hash / 200) % 200) - 100) / 10000.0  // +/- 0.01 degrees longitude

        let latitude = baseCoordinate.latitude + latOffset
        let longitude = baseCoordinate.longitude + lonOffset

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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

    private func centerOnUserLocationInitially() {
        if let location = locationManager.location {
            withAnimation {
                region.center = location
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
            hasCenteredOnUserLocation = true
        }
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

