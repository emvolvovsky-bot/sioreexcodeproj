//
//  EventsMapView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct EventsMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Default to LA
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedEvent: Event?
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: viewModel.events) { event in
                MapAnnotation(coordinate: coordinateForEvent(event)) {
                    EventMapPin(event: event) {
                        selectedEvent = event
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                requestLocationPermission()
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
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                eventId: event.id,
                isTalentMapMode: authViewModel.currentUser?.userType == .talent
            )
        }
        .onAppear {
            viewModel.refreshFeed()
        }
    }
    
    private func coordinateForEvent(_ event: Event) -> CLLocationCoordinate2D {
        // For demo purposes, generate coordinates based on event location string
        // In production, events should have lat/long coordinates
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

struct EventMapPin: View {
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

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}

#Preview {
    EventsMapView()
        .environmentObject(AuthViewModel())
}

