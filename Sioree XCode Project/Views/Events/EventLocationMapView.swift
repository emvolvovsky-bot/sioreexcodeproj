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
    
    // Map state
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // LA default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
    @State private var isGeocoding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Using default scope to avoid namespace issues on older SDKs
                Map(position: $cameraPosition, interactionModes: .all) {
                    UserAnnotation()
                }
                .onMapCameraChange { context in
                    // Keep track of the visible center as the user pans/zooms
                    mapCenter = context.region.center
                    region = context.region
                }
                .ignoresSafeArea()
                
                // Center indicator (pin that shows where selection will be)
                VStack {
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.sioreeIcyBlue)
                        .offset(y: -10)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    Spacer()
                }
                
                // Top helper text instead of a nav title
                VStack {
                    HStack {
                        Text("Move the map so the pin is on your spot")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeWhite)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                        Spacer()
                    }
                    .padding([.top, .horizontal], Theme.Spacing.m)
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Drag the map to move the pin")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeWhite.opacity(0.9))
                            Text("\(mapCenter.latitude, specifier: "%.4f"), \(mapCenter.longitude, specifier: "%.4f")")
                                .font(.caption2)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        Spacer()
                        Button(action: {
                            let location = mapCenter
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
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onAppear {
                // If a location was already chosen, center the map there
                if let preselected = selectedLocation {
                    region.center = preselected
                    cameraPosition = .region(region)
                    mapCenter = preselected
                } else {
                    cameraPosition = .region(region)
                    mapCenter = region.center
                }
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

#Preview {
    EventLocationMapView(selectedLocation: .constant(nil), selectedAddress: .constant(nil))
}

