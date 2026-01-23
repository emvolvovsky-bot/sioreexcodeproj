//
//  PartierHomeView.swift
//  Sioree
//hello
//  Created by Sioree Team
//
//
import SwiftUI
import CoreLocation
import UIKit
import MapKit

struct PartierHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showDatePicker = false
    @State private var showMapView = false
    @State private var selectedCategory: EventCategory = .all
    @State private var searchText: String = ""
    @Namespace private var chipAnimation
    @State private var radiusMiles: Double = 15
    @State private var selectedDate: Date? = nil
    @State private var showCodeEntry = false
    @State private var selectedEvent: Event?
    @State private var enteredCodes: [String: String] = [:] // eventId -> entered code
    @State private var cardFrames: [String: CGRect] = [:]
    @State private var animatingEvent: Event?
    @State private var animationPosition: CGPoint = .zero
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 0.0
    @State private var animationSize: CGSize = .zero
    @State private var favoritesTargetPoint: CGPoint = .zero
    @State private var hiddenEventIds: Set<String> = []
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        floatingButtons
                            .padding(.top, Theme.Spacing.m)
                            .frame(maxWidth: .infinity)
                        
                        categoryFilters
                        tabContent
                    }
                    .padding(.vertical, Theme.Spacing.l)
                }
                
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            updateFavoritesTargetPoint(in: proxy)
                        }
                        .onChange(of: proxy.size) { _ in
                            updateFavoritesTargetPoint(in: proxy)
                        }
                    
                    if let animatingEvent {
                        EventSaveThumbnail(event: animatingEvent, accent: .sioreeIcyBlue)
                            .frame(width: animationSize.width, height: animationSize.height)
                            .scaleEffect(animationScale)
                            .opacity(animationOpacity)
                            .position(animationPosition)
                            .shadow(color: Color.sioreeIcyBlue.opacity(0.4), radius: 18, x: 0, y: 10)
                            .allowsHitTesting(false)
                            .zIndex(10)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showDatePicker) {
                DateFilterView(selectedDate: $viewModel.selectedDate) {
                    viewModel.applyDateFilter()
                }
            }
            .sheet(isPresented: $showMapView) {
                MapRadiusView(radiusMiles: $radiusMiles, location: locationManager.location)
                    .presentationDetents([.fraction(0.90)])
            }
            .sheet(isPresented: $showCodeEntry) {
                if let event = selectedEvent {
                    PrivateEventCodeView(
                        event: event,
                        enteredCode: Binding(
                            get: { enteredCodes[event.id] ?? "" },
                            set: { enteredCodes[event.id] = $0 }
                        ),
                        onCodeVerified: { code in
                            enteredCodes[event.id] = code
                            showCodeEntry = false
                        },
                        onDismiss: {
                            showCodeEntry = false
                            selectedEvent = nil
                        }
                    )
                }
            }
            .onAppear {
                viewModel.loadEvents(userLocation: locationManager.location, radiusMiles: Int(radiusMiles))
                locationManager.requestLocation()
            }
            .onReceive(locationManager.$location.compactMap { $0 }) { coordinate in
                applyLocationIfChanged(coordinate)
            }
            .onChange(of: radiusMiles) { newRadius in
                viewModel.loadEvents(userLocation: locationManager.location, radiusMiles: Int(newRadius))
            }
            .onChange(of: selectedDate) { newDate in
                viewModel.selectedDate = newDate
                viewModel.applyDateFilter()
            }
            .alert("Saved to Favorites", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This event has been saved to your favorites.")
            }
        }
    }
}

private extension PartierHomeView {
    func applyLocationIfChanged(_ coordinate: CLLocationCoordinate2D) {
        if let existing = viewModel.lastKnownCoordinate {
            let latDiff = abs(existing.latitude - coordinate.latitude)
            let lonDiff = abs(existing.longitude - coordinate.longitude)
            if latDiff < 0.0005 && lonDiff < 0.0005 { return }
        }
        viewModel.loadEvents(userLocation: coordinate)
    }
    
    var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeBlack,
                    Color.sioreeBlack.opacity(0.98),
                    Color.sioreeCharcoal.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -120, y: -320)
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: 160, y: 220)
        }
    }
    
    var floatingButtons: some View {
        HStack(spacing: Theme.Spacing.m) {
            Button(action: { showMapView = true }) {
                Image(systemName: "map.fill")
                    .font(.body.bold())
                    .foregroundColor(.sioreeWhite)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.4), radius: 16, x: 0, y: 8)
            }
            
            Button(action: { showDatePicker = true }) {
                Image(systemName: "calendar")
                    .font(.body.bold())
                    .foregroundColor(.sioreeWhite)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.4), radius: 16, x: 0, y: 8)
            }
        }
    }
    
    var locationPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption)
            Text(currentLocationLabel)
                .font(.sioreeBodySmall)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .foregroundColor(.sioreeWhite)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
    
    var searchField: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.sioreeLightGrey)
            TextField("find events in...", text: $searchText)
                .foregroundColor(.sioreeWhite)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    var filterButton: some View {
        Button(action: { showDatePicker = true }) {
            Image(systemName: "slider.horizontal.3")
                .font(.body.weight(.semibold))
                .foregroundColor(.sioreeWhite)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.sioreeIcyBlue.opacity(0.35), radius: 18, x: 0, y: 8)
        }
    }
    
    var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                ForEach(EventCategory.allCases, id: \.self) { category in
                    GlassChip(
                        title: category.label,
                        isSelected: selectedCategory == category,
                        accent: .sioreeIcyBlue,
                        animation: chipAnimation
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }
    
    @ViewBuilder
    var tabContent: some View {
        if viewModel.isLoading && !viewModel.hasLoaded {
            LoadingView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xxl)
        } else if nearbyDataSource.isEmpty && viewModel.hasLoaded {
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
            eventList
        }
    }
    
    var eventList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if filteredEvents.isEmpty && !hiddenEventIds.isEmpty {
                        Text("You have \(hiddenEventIds.count) event\(hiddenEventIds.count == 1 ? "" : "s") saved in favorites")
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)
                    } else {
                        Text("\(filteredEvents.count) Events")
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)
                    }
                }
                        Spacer()
                    }
            .padding(.horizontal, listPadding)
                    
            LazyVStack(spacing: Theme.Spacing.m) {
                let events = filteredEvents
                ForEach(events, id: \.id) { (event: Event) in
                    Group {
                        if event.isPrivate, let requiredCode = event.accessCode {
                            if let savedCode = enteredCodes[event.id], savedCode == requiredCode {
                                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                    NightEventCard(event: event, accent: .sioreeIcyBlue) {
                                        handleSave(event)
                                    }
                                    .anchorPreference(key: EventCardFrameKey.self, value: .bounds) { [event.id: $0] }
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    selectedEvent = event
                                    showCodeEntry = true
                                }) {
                                    NightEventCard(event: event, accent: .sioreeIcyBlue) {
                                        handleSave(event)
                                    }
                                    .anchorPreference(key: EventCardFrameKey.self, value: .bounds) { [event.id: $0] }
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                NightEventCard(event: event, accent: .sioreeIcyBlue) {
                                    handleSave(event)
                                }
                                .anchorPreference(key: EventCardFrameKey.self, value: .bounds) { [event.id: $0] }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .overlayPreferenceValue(EventCardFrameKey.self) { anchors in
                GeometryReader { proxy in
                    let frames = anchors.mapValues { proxy[$0] }
                    Color.clear
                        .onAppear {
                            cardFrames = frames
                        }
                        .onChange(of: frames) { newFrames in
                            cardFrames = newFrames
                        }
                }
            }
            .padding(.horizontal, listPadding)
            .padding(.bottom, Theme.Spacing.l)
        }
    }

    var listPadding: CGFloat { Theme.Spacing.l }
    
    func circleDiameter(for radius: Double) -> CGFloat {
        // Visual scale for the radius overlay ring
        let clamped = max(1, min(radius, 50))
        let normalized = (clamped - 1) / 49
        return 80 + CGFloat(normalized) * 160
    }
    
    var filteredNearbyEvents: [Event] {
        let currentUserId = authViewModel.currentUser?.id
        return viewModel.nearbyEvents.filter { event in
            guard let currentUserId else { return true }
            return event.hostId != currentUserId
        }
    }
    
    
    var nearbyDataSource: [Event] {
        if !filteredNearbyEvents.isEmpty {
            return filteredNearbyEvents
        }
        return []
    }
    
    var currentLocationLabel: String {
        if let location = authViewModel.currentUser?.location, !location.isEmpty {
            return location
        }
        if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
            return "Nearby"
        }
        return "Everywhere"
    }
    
    var filteredEvents: [Event] {
        let events: [Event] = baseEvents.filter { event in
            // Ensure both free and paid events are included - no price-based filtering
            matchesCategory(event) && matchesSearch(event)
        }
        let finalEvents = events.filter { !hiddenEventIds.contains($0.id) }

        // Debug: Print event counts and prices to console
        print("📊 Event filtering debug:")
        print("   Base events: \(baseEvents.count)")
        print("   After category/search filter: \(events.count)")
        print("   After hidden filter: \(finalEvents.count)")
        print("   Paid events in final list: \(finalEvents.filter { ($0.ticketPrice ?? 0) > 0 }.count)")
        print("   Free events in final list: \(finalEvents.filter { ($0.ticketPrice ?? 0) == 0 }.count)")

        return finalEvents
    }
    
    var baseEvents: [Event] {
        return nearbyDataSource
    }
    
    func matchesSearch(_ event: Event) -> Bool {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
        return event.title.localizedCaseInsensitiveContains(searchText) ||
        event.location.localizedCaseInsensitiveContains(searchText)
    }
    
    func matchesCategory(_ event: Event) -> Bool {
        switch selectedCategory {
        case .all:
            return true
        default:
            let keyword = selectedCategory.keyword.lowercased()
            let titleMatch = event.title.lowercased().contains(keyword)
            let locationMatch = event.location.lowercased().contains(keyword)
            let lookingMatch = event.lookingForSummary?.lowercased().contains(keyword) ?? false
            return titleMatch || locationMatch || lookingMatch
        }
    }
    
    func handleSave(_ event: Event) {
        if !event.isSaved {
            startSaveAnimation(for: event)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                hiddenEventIds.insert(event.id)
            }
            // Show saved alert after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSavedAlert = true
            }
        }
        viewModel.toggleSaveEvent(event)
    }
    
    func startSaveAnimation(for event: Event) {
        guard let frame = cardFrames[event.id] else { return }
        let targetPoint = favoritesTargetPoint == .zero
        ? CGPoint(x: UIScreen.main.bounds.width * 0.7, y: UIScreen.main.bounds.height - 100)
        : favoritesTargetPoint
        
        animatingEvent = event
        animationSize = frame.size
        animationPosition = CGPoint(x: frame.midX, y: frame.midY)
        animationScale = 1.0
        animationOpacity = 1.0
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            animationPosition = targetPoint
            animationScale = 0.1
            animationOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animatingEvent = nil
        }
    }
    
    func updateFavoritesTargetPoint(in geometry: GeometryProxy) {
        let tabWidth = geometry.size.width / 5
        let x = tabWidth * 3.5
        let y = geometry.size.height - geometry.safeAreaInsets.bottom - 30
        favoritesTargetPoint = CGPoint(x: x, y: y)
    }

}

private struct EventCardFrameKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct EventSaveThumbnail: View {
    let event: Event
    let accent: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.sioreeCharcoal.opacity(0.8), Color.sioreeBlack.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Image(systemName: "heart.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(accent)
                .shadow(color: accent.opacity(0.6), radius: 8, x: 0, y: 4)
        }
    }
}

private struct GlassChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    var animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(isSelected ? 0.35 : 0.12), radius: isSelected ? 18 : 10, x: 0, y: 6)
                    .overlay(
                        Group {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [accent.opacity(0.9), accent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "chip_fill_\(title)", in: animation)
                            }
                        }
                    )
                
                Text(title)
                    .font(.sioreeBodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.sioreeWhite)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }
}

struct NightEventCard: View {
    let event: Event
    let accent: Color
    let actionLabel: String
    let showsFavoriteButton: Bool
    var onSave: (() -> Void)? = nil
    
    init(
        event: Event,
        accent: Color,
        actionLabel: String = "Get Now",
        showsFavoriteButton: Bool = true,
        onSave: (() -> Void)? = nil
    ) {
        self.event = event
        self.accent = accent
        self.actionLabel = actionLabel
        self.showsFavoriteButton = showsFavoriteButton
        self.onSave = onSave
    }
    
    private var priceText: String {
        if let price = event.ticketPrice, price > 0 {
            return String(format: "$%.0f", price)
        }
        return "FREE"
    }
    
    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.date)
    }
    
    private var dayNumberText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: event.date)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: accent.opacity(0.16), radius: 24, x: 0, y: 12)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                ZStack(alignment: .topLeading) {
                    heroImage
                        .frame(height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    VStack(alignment: .leading) {
                        dateBadge
                        Spacer()
                    }
                    .padding(Theme.Spacing.m)
                    
                    if showsFavoriteButton {
                        VStack {
                            HStack {
                                Spacer()
                                heartButton
                            }
                            Spacer()
                        }
                        .padding(Theme.Spacing.m)
                    }
                }
                
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                            .lineLimit(2)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(accent.opacity(0.9))
                            Text(event.location)
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text(priceText)
                        .font(.sioreeH4)
                            .foregroundColor(.sioreeWhite)
                }
                
                    if let lookingFor = event.lookingForSummary, lookingFor.lowercased() != "general talent" {
                        Label(lookingFor, systemImage: "music.quarternote.3")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if event.attendeeCount > 0 {
                            attendeeStack
                                .padding(.leading, Theme.Spacing.xs)
                        }
                        Spacer()
                        Text(actionLabel)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.xxl * 1.6)
                            .padding(.vertical, Theme.Spacing.s)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [accent.opacity(0.9), accent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: accent.opacity(0.35), radius: 16, x: 0, y: 8)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                            .allowsHitTesting(false)
                    }
                    .padding(.top, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.bottom, Theme.Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var heroImage: some View {
        ZStack {
            if let first = event.images.first, let url = URL(string: first) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    shimmer
                }
            } else {
                shimmer
            }
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var shimmer: some View {
        LinearGradient(
            colors: [
                Color.sioreeCharcoal.opacity(0.6),
                Color.sioreeBlack.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var dateBadge: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(dateText.uppercased())
                .font(.sioreeCaption)
                .foregroundColor(.sioreeWhite)
            Text(dayNumberText)
                .font(.sioreeBody)
                .fontWeight(.semibold)
                .foregroundColor(.sioreeWhite)
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
    }
    
    private var heartButton: some View {
        Button(action: {
            onSave?()
        }) {
            Image(systemName: event.isSaved ? "heart.fill" : "heart")
                .font(.body.bold())
                .foregroundColor(event.isSaved ? accent : .sioreeWhite)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: accent.opacity(0.3), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
    
    private var attendeeStack: some View {
        let displayed = Array(sampleAvatars.prefix(2))
        let remaining = max(event.attendeeCount - displayed.count, 0)
        
        return HStack(spacing: -16) {
            ForEach(displayed) { avatar in
                AvatarBubble(initials: avatar.initials, color: avatar.color, opaque: true)
            }
            
            if remaining > 0 {
                Text("+\(remaining)")
                    .font(.sioreeCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.sioreeWhite)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color.sioreeCharcoal)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
        }
    }
    
    private var sampleAvatars: [AvatarParticipant] {
        let initials = event.hostName.split(separator: " ").compactMap { $0.first }.prefix(2)
        let hostInitials = String(initials)
        return [
            AvatarParticipant(initials: hostInitials.isEmpty ? "S" : hostInitials, color: accent),
            AvatarParticipant(initials: "DJ", color: Color.sioreeWarmGlow),
            AvatarParticipant(initials: "VIP", color: Color.sioreeLightGrey)
        ]
    }
}

private struct AvatarBubble: View {
    let initials: String
    let color: Color
    var opaque: Bool = false
    
    var body: some View {
        Text(initials)
            .font(.sioreeCaption)
            .fontWeight(.semibold)
            .foregroundColor(.sioreeWhite)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(opaque ? color : color.opacity(0.85))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

private struct AvatarParticipant: Identifiable, Hashable {
    let id = UUID()
    let initials: String
    let color: Color
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

private struct MapRadiusView: View {
    @Binding var radiusMiles: Double
    let location: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss
    @State private var tempRadius: Double
    @State private var region: MKCoordinateRegion
    
    init(radiusMiles: Binding<Double>, location: CLLocationCoordinate2D?) {
        self._radiusMiles = radiusMiles
        self.location = location
        self._tempRadius = State(initialValue: radiusMiles.wrappedValue)
        
        let center = location ?? CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        self._region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
    
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
                    if location != nil {
                        ZStack {
                            Map(coordinateRegion: $region)
                                .frame(height: 450)
                                .cornerRadius(Theme.CornerRadius.large)
                            
                            Circle()
                                .stroke(Color.sioreeIcyBlue.opacity(0.6), lineWidth: 2)
                                .frame(width: circleDiameter(for: tempRadius), height: circleDiameter(for: tempRadius))
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    
                    VStack(spacing: Theme.Spacing.m) {
                        HStack {
                            Text("Search Radius")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            Spacer()
                            Text("\(Int(tempRadius)) mi")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeIcyBlue)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        Slider(value: $tempRadius, in: 1...50, step: 1)
                            .tint(.sioreeIcyBlue)
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        Button(action: {
                            radiusMiles = tempRadius
                            dismiss()
                        }) {
                            Text("Apply")
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
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.top, Theme.Spacing.m)
                }
                .padding(.vertical, Theme.Spacing.l)
            }
            .navigationTitle("Set Search Radius")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        radiusMiles = tempRadius
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
    
    private func circleDiameter(for radius: Double) -> CGFloat {
        let clamped = max(1, min(radius, 50))
        let normalized = (clamped - 1) / 49
        return 60 + CGFloat(normalized) * 240
    }
}

private struct PrivateEventCodeView: View {
    let event: Event
    @Binding var enteredCode: String
    let onCodeVerified: (String) -> Void
    let onDismiss: () -> Void
    @State private var codeInput: String = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.sioreeBlack,
                        Color.sioreeBlack.opacity(0.98),
                        Color.sioreeCharcoal.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.sioreeIcyBlue)
                            .shadow(color: Color.sioreeIcyBlue.opacity(0.5), radius: 16)
                        
                        Text("Private Event")
                            .font(.sioreeH2)
                            .foregroundColor(.sioreeWhite)
                        
                        Text(event.title)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.l)
                        
                        Text("Enter the access code to view this event")
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeLightGrey.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.l)
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    
                    VStack(spacing: Theme.Spacing.m) {
                        TextField("Access Code", text: $codeInput)
                            .textContentType(.oneTimeCode)
                            .autocapitalization(.allCharacters)
                            .foregroundColor(.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(codeFieldBackground)
                            .shadow(color: showError ? Color.red.opacity(0.2) : Color.sioreeIcyBlue.opacity(0.15), radius: 12, x: 0, y: 6)
                        
                        if showError {
                            Text("Incorrect code. Please try again.")
                                .font(.sioreeCaption)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        
                        Button(action: verifyCode) {
                            Text("Verify Code")
                                .font(.sioreeBody)
                                .fontWeight(.semibold)
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(verifyButtonGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.sioreeIcyBlue.opacity(0.4), radius: 16, x: 0, y: 8)
                        }
                        .disabled(codeInput.isEmpty)
                        .opacity(codeInput.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
    
    private var codeFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(showError ? Color.red.opacity(0.6) : Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1.5)
            )
    }
    
    private var verifyButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func verifyCode() {
        guard let requiredCode = event.accessCode else { return }
        
        if codeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == requiredCode.uppercased() {
            enteredCode = codeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            onCodeVerified(enteredCode)
            dismiss()
        } else {
            showError = true
            codeInput = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showError = false
            }
        }
    }
}

#Preview {
    PartierHomeView()
}

