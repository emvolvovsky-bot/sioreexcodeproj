//
//  TalentEventsMapView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import Combine

// Assuming Event model is in the same module
// If not, you'll need to import the appropriate module

struct TalentEventsMapView: View {
    @StateObject private var viewModel = TalentEventsMapViewModel()
    @State private var selectedEvent: Event?
    @State private var showEventDetail = false
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Default to NYC
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    private var filteredEvents: [Event] {
        viewModel.events.filter { event in
            // Filter events by selected date (same day)
            let calendar = Calendar.current
            return calendar.isDate(event.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()

                VStack(spacing: 0) {

                    // Map
                    ZStack {
                        Map(coordinateRegion: $region, annotationItems: filteredEvents) { event in
                            MapAnnotation(coordinate: CLLocationCoordinate2D(
                                latitude: event.locationDetails != nil ? parseLatitude(from: event.locationDetails!) ?? 40.7128 : 40.7128,
                                longitude: event.locationDetails != nil ? parseLongitude(from: event.locationDetails!) ?? -74.0060 : -74.0060
                            )) {
                                TalentEventMapPin(event: event) {
                                    selectedEvent = event
                                    showEventDetail = true
                                }
                            }
                        }
                        .accentColor(.sioreeWarning)
                        .ignoresSafeArea()

                        // Loading overlay
                        if viewModel.isLoading {
                            Color.black.opacity(0.5)
                                .ignoresSafeArea()

                            VStack {
                                ProgressView()
                                    .tint(.sioreeWarning)
                                Text("Loading events...")
                                    .font(.sioreeBody)
                                    .foregroundColor(.white)
                                    .padding(.top, Theme.Spacing.s)
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
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(eventId: event.id, isTalentMapMode: true)
                }
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
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark)
                        .accentColor(.sioreeWarning)
                        .padding(.horizontal, Theme.Spacing.m)

                        Spacer()
                    }
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                viewModel.fetchEvents()
            }
        }
    }

    private func parseLatitude(from locationString: String) -> Double? {
        // Simple parsing - in a real app you'd use proper geocoding
        // For now, return default NYC coordinates
        return 40.7128
    }

    private func parseLongitude(from locationString: String) -> Double? {
        // Simple parsing - in a real app you'd use proper geocoding
        // For now, return default NYC coordinates
        return -74.0060
    }
}

struct TalentEventMapPin: View {
    let event: Event
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Main pin icon
                ZStack {
                    Circle()
                        .fill(Color.sioreeWarning)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.sioreeWarning.opacity(0.3), radius: 4, x: 0, y: 2)

                    Image(systemName: "music.note")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }

                // Event info card
                VStack(spacing: 3) {
                    Text(event.title)
                        .font(.sioreeCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.sioreeBlack)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .frame(maxWidth: 140)

                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.sioreeCaptionSmall)
                        .foregroundColor(.sioreeCharcoal.opacity(0.8))

                    if let lookingFor = event.lookingForSummary {
                        Text(lookingFor)
                            .font(.sioreeCaptionSmall)
                            .foregroundColor(.sioreeWarning)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .frame(maxWidth: 140)
                    }
                }
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.vertical, Theme.Spacing.s)
                .background(Color.white)
                .cornerRadius(Theme.CornerRadius.medium)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class TalentEventsMapViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()

    func fetchEvents() {
        isLoading = true
        errorMessage = nil

        // Fetch events looking for talent
        let publisher = networkService.fetchEventsLookingForTalent(talentType: "")
            .receive(on: DispatchQueue.main)

        let cancellable = publisher.sink(
            receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    print("❌ Failed to load events: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] (events: [Event]) in
                guard let self = self else { return }
                // Filter to only show published events with location info
                let validEvents = events.filter { event in
                    event.status == .published &&
                    !event.location.isEmpty
                }
                self.events = validEvents
                print("✅ Loaded \(validEvents.count) events on map")
            }
        )

        cancellable.store(in: &cancellables)
    }
}

struct TalentEventsMapView_Previews: PreviewProvider {
    static var previews: some View {
        TalentEventsMapView()
    }
}
