//
//  MapViewPlaceholder.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapViewPlaceholder: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Default to LA
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedEvent: Event?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: homeViewModel.events) { event in
                    MapAnnotation(coordinate: coordinateForEvent(event)) {
                        EventMapPinView(event: event) {
                            selectedEvent = event
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    requestLocationPermission()
                    if !homeViewModel.hasLoaded {
                        homeViewModel.loadNearbyEvents()
                    }
                }
                .onReceive(locationManager.$location.compactMap { $0 }) { location in
                    withAnimation {
                        region.center = location
                        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    }
                }
                
                // Location button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.sioreeWhite)
                                .frame(width: 44, height: 44)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.trailing, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedEvent) { event in
                EventDetailPlaceholderView(event: event)
            }
        }
    }
    
    private func coordinateForEvent(_ event: Event) -> CLLocationCoordinate2D {
        // Generate coordinates based on event location string
        let hash = abs(event.location.hashValue)
        let lat = 34.0522 + Double(hash % 100) / 1000.0 - 0.05
        let lon = -118.2437 + Double((hash / 100) % 100) / 1000.0 - 0.05
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
}

struct EventMapPinView: View {
    let event: Event
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.sioreeWhite)
                    .frame(width: 32, height: 32)
                    .background(Color.sioreeIcyBlue)
                    .cornerRadius(Theme.CornerRadius.medium)
                
                // Pin point
                Triangle()
                    .fill(Color.sioreeIcyBlue)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    MapViewPlaceholder()
}

