//
//  TalentMapView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import CoreLocation

struct TalentMapView: View {
    @StateObject private var viewModel = TalentViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // LA default
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selectedTalent: Talent?
    @State private var showTalentDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: talentAnnotations) { talent in
                    MapAnnotation(coordinate: talent.coordinate) {
                        Button(action: {
                            selectedTalent = talent.talent
                            showTalentDetail = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.sioreeIcyBlue)
                                
                                Text(talent.talent.name)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeWhite)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.sioreeBlack.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Filter overlay
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button("All Categories") {
                                viewModel.selectedCategory = nil
                                viewModel.loadTalent()
                            }
                            ForEach(TalentCategory.allCases, id: \.self) { category in
                                Button(category.rawValue) {
                                    viewModel.selectedCategory = category
                                    viewModel.loadTalent()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                Text(viewModel.selectedCategory?.rawValue ?? "All")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeBlack.opacity(0.8))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(Theme.Spacing.m)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Find Talent")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadTalent()
            }
            .sheet(item: $selectedTalent) { talent in
                TalentDetailView(talent: TalentListing(
                    id: talent.userId,
                    name: talent.name,
                    roleText: talent.category.rawValue,
                    rateText: "$\(Int(talent.priceRange.min))/hour",
                    location: talent.location ?? "Location TBD",
                    rating: talent.rating,
                    imageName: "person.circle.fill"
                ))
            }
        }
    }
    
    private var talentAnnotations: [TalentAnnotation] {
        viewModel.talent.compactMap { talent in
            guard let locationString = talent.location else { return nil }
            // Parse location string to coordinates (simplified - in production use geocoding)
            // For now, return nil if location can't be parsed
            // This is a placeholder - you'd want to geocode addresses or store coordinates
            return TalentAnnotation(
                talent: talent,
                coordinate: region.center // Placeholder - would use actual coordinates
            )
        }
    }
}

struct TalentAnnotation: Identifiable {
    let id = UUID()
    let talent: Talent
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    TalentMapView()
}

