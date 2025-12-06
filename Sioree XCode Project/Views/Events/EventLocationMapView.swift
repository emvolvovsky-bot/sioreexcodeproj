//
//  EventLocationMapView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import CoreLocation

struct EventLocationMapView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // LA default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var mapLocation: CLLocationCoordinate2D?
    @State private var isGeocoding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(coordinateRegion: $region, annotationItems: mapLocation != nil ? [MapPin(coordinate: mapLocation!)] : []) { pin in
                        MapMarker(coordinate: pin.coordinate, tint: .sioreeIcyBlue)
                    }
                    .onTapGesture(coordinateSpace: .local) { location in
                        // Convert tap location to map coordinate
                        if let coordinate = proxy.convert(location, from: .local) {
                            mapLocation = coordinate
                            region.center = coordinate
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                // Update location when drag ends
                                if let coordinate = proxy.convert(value.location, from: .local) {
                                    mapLocation = coordinate
                                    region.center = coordinate
                                }
                            }
                    )
                }
                .ignoresSafeArea()
                
                // Center indicator (pin that shows where selection will be)
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.sioreeIcyBlue)
                        .offset(y: -20)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let location = mapLocation ?? region.center
                            selectedLocation = location
                            geocodeLocation(location)
                        }) {
                            HStack {
                                if isGeocoding {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeWhite))
                                } else {
                                    Text("Use This Location")
                                        .font(.sioreeBody)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeIcyBlue)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .disabled(isGeocoding)
                        .padding(Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onAppear {
                mapLocation = region.center
            }
        }
    }
    
    private func geocodeLocation(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isGeocoding = false
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    // Still set location even if geocoding fails
                    selectedLocation = coordinate
                    dismiss()
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        addressComponents.append(state)
                    }
                    if let zip = placemark.postalCode {
                        addressComponents.append(zip)
                    }
                    
                    let address = addressComponents.joined(separator: " ")
                    selectedAddress = address.isEmpty ? nil : address
                } else {
                    selectedAddress = nil
                }
                
                selectedLocation = coordinate
                dismiss()
            }
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    EventLocationMapView(selectedLocation: .constant(nil), selectedAddress: .constant(nil))
}

