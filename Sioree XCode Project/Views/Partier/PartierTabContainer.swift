//
//  PartierTabContainer.swift
//  Sioree
//
//  Created by Sioree Team
//
//
import SwiftUI
import Combine

enum PartierTab: CaseIterable {
    case tickets
    case inbox
    case home
    case favorites
    case profile
    
    var systemIcon: String {
        switch self {
        case .tickets: return "ticket"
        case .inbox: return "bubble.left.and.bubble.right"
        case .home: return "house.fill"
        case .favorites: return "heart"
        case .profile: return "person"
        }
    }
}

struct PartierTabContainer: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: PartierTab = .home
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var sharedLocationManager = LocationManager()
    @State private var hideTabBar = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TicketsView()
                    .tag(PartierTab.tickets)
                    .tabItem { EmptyView() }
                
                PartierInboxView()
                    .tag(PartierTab.inbox)
                    .tabItem { EmptyView() }
                
                PartierHomeView()
                    .tag(PartierTab.home)
                    .tabItem { EmptyView() }
                
                FavoritesView()
                    .tag(PartierTab.favorites)
                    .tabItem { EmptyView() }
                
                PartierProfileView()
                    .tag(PartierTab.profile)
                    .tabItem { EmptyView() }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .tabBar)
            
            if !hideTabBar {
                PartierBottomBar(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            UITabBar.appearance().isHidden = true
        }
        .onDisappear {
            UITabBar.appearance().isHidden = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .hideTabBar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                hideTabBar = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTabBar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                hideTabBar = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTicketsTab)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = .tickets
                hideTabBar = false
            }
        }
    }
}

private struct PartierBottomBar: View {
    @Binding var selectedTab: PartierTab
    @Namespace private var tabAnimation
    @State private var indicatorStretch: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let totalHeight = 70 + safeAreaBottom
            let tabWidth = geometry.size.width / 5
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.sioreeBlack.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.22), radius: 16, x: 0, y: 10)
                    .frame(width: geometry.size.width, height: totalHeight)
                
                HStack(spacing: 0) {
                    tabButton(.tickets, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.inbox, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.home, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.favorites, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.profile, tabWidth: tabWidth, geometry: geometry)
                }
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, safeAreaBottom + Theme.Spacing.xs)
                .frame(width: geometry.size.width, height: totalHeight)
            }
            .frame(width: geometry.size.width, height: totalHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onChange(of: selectedTab) { newValue in
                indicatorStretch = 1.0
                withAnimation(.spring(response: 0.25, dampingFraction: 0.55, blendDuration: 0.1)) {
                    indicatorStretch = 1.22
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.2).delay(0.08)) {
                    indicatorStretch = 1.0
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func tabButton(_ tab: PartierTab, tabWidth: CGFloat, geometry: GeometryProxy) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.sioreeWhite)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 4)
                }
                
                Image(systemName: iconName(for: tab, isSelected: isSelected))
                    .font(.system(size: isSelected ? 22 : 21, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .sioreeBlack : .sioreeWhite.opacity(0.7))
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .frame(width: tabWidth, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func iconName(for tab: PartierTab, isSelected: Bool) -> String {
        switch tab {
        case .tickets:
            return isSelected ? "ticket.fill" : "ticket"
        case .inbox:
            return isSelected ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right"
        case .home:
            return isSelected ? "house.fill" : "house"
        case .favorites:
            return isSelected ? "heart.fill" : "heart"
        case .profile:
            return isSelected ? "person.fill" : "person"
        }
    }
}

#Preview {
    PartierTabContainer()
        .environmentObject(AuthViewModel())
}

struct FavoritesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = FavoritesViewModel()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                    NightEventCard(event: event, accent: .sioreeIcyBlue) {
                                        viewModel.toggleSaveEvent(event)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                    NightEventCard(event: event, accent: .sioreeIcyBlue) {
                                        viewModel.toggleSaveEvent(event)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.l)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.loadFavorites()
            }
            .onReceive(NotificationCenter.default.publisher(for: .favoriteStatusChanged)) { _ in
                // Refresh favorites when favorite status changes
                viewModel.loadFavorites()
            }
        }
    }
    
    private var backgroundGlow: some View {
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
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "heart")
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(.sioreeIcyBlue.opacity(0.5))
            Text("No Favorites Yet")
                .font(.sioreeH3)
                .foregroundColor(.sioreeWhite)
            Text("Save events you're interested in and they'll appear here.")
                .font(.sioreeBody)
                .foregroundColor(.sioreeLightGrey)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

class FavoritesViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .favoriteStatusChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let event = notification.userInfo?["event"] as? Event else { return }
                self?.applyFavoriteChange(event)
            }
            .store(in: &cancellables)
    }
    
    func loadFavorites() {
        isLoading = true
        errorMessage = nil

        networkService.fetchSavedEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        // On failure, try to load cached saved events from StorageService
                        if let currentUserId = StorageService.shared.getUserId() {
                            let cached = StorageService.shared.getSavedEvents(forUserId: currentUserId)
                            if !cached.isEmpty {
                                self?.events = cached
                                self?.errorMessage = nil
                                return
                            }
                        }
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] events in
                    self?.events = events
                    self?.isLoading = false
                    // Persist saved events locally for offline/failed-fetch fallback
                    if let currentUserId = StorageService.shared.getUserId() {
                        StorageService.shared.saveSavedEvents(events, forUserId: currentUserId)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshFavorites() {
        loadFavorites()
    }
    
    func toggleSaveEvent(_ event: Event) {
        // Optimistic update
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isSaved.toggle()
        }
        
        networkService.toggleEventSave(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert optimistic update
                        if let index = self?.events.firstIndex(where: { $0.id == event.id }) {
                            self?.events[index].isSaved.toggle()
                        }
                    } else {
                        // If unsaved, remove from favorites list
                        if let index = self?.events.firstIndex(where: { $0.id == event.id }) {
                            if !(self?.events[index].isSaved ?? false) {
                                self?.events.remove(at: index)
                            }
                        }
                        // Persist saved-events cache to reflect the confirmed change
                        if let currentUserId = StorageService.shared.getUserId() {
                            var cached = StorageService.shared.getSavedEvents(forUserId: currentUserId)
                            if let updated = self?.events.first(where: { $0.id == event.id }) {
                                if updated.isSaved {
                                    if !cached.contains(where: { $0.id == updated.id }) {
                                        cached.insert(updated, at: 0)
                                    } else if let idx = cached.firstIndex(where: { $0.id == updated.id }) {
                                        cached[idx] = updated
                                    }
                                } else {
                                    cached.removeAll(where: { $0.id == updated.id })
                                }
                            } else {
                                // event no longer in favorites list -> ensure removed from cache
                                cached.removeAll(where: { $0.id == event.id })
                            }
                            StorageService.shared.saveSavedEvents(cached, forUserId: currentUserId)
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    private func applyFavoriteChange(_ event: Event) {
        if event.isSaved {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
            } else {
                events.insert(event, at: 0)
            }
        } else if let index = events.firstIndex(where: { $0.id == event.id }) {
            events.remove(at: index)
        }
    }
}

private struct FavoritesPlaceholderView: View {
    var body: some View {
        FavoritesView()
    }
}

// Custom shape with center notch for the floating home button
private struct NotchedBarShape: Shape {
    var notchCenterX: CGFloat? = nil
    
    func path(in rect: CGRect) -> Path {
        let notchRadius: CGFloat = 36
        let notchWidth: CGFloat = notchRadius * 2 + 16
        let cornerRadius: CGFloat = 26
        let notchDepth: CGFloat = 20
        let minCenterX = rect.minX + notchWidth / 2
        let maxCenterX = rect.maxX - notchWidth / 2
        let notchCenterX = min(max(notchCenterX ?? rect.midX, minCenterX), maxCenterX)
        
        var path = Path()
        
        // Start bottom-left
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        
        // Right to notch start
        path.addLine(to: CGPoint(x: notchCenterX + notchWidth / 2, y: rect.minY))
        
        // Smooth wave notch
        path.addCurve(
            to: CGPoint(x: notchCenterX, y: rect.minY - notchDepth),
            control1: CGPoint(x: notchCenterX + notchRadius * 0.65, y: rect.minY),
            control2: CGPoint(x: notchCenterX + notchRadius * 0.35, y: rect.minY - notchDepth)
        )
        path.addCurve(
            to: CGPoint(x: notchCenterX - notchWidth / 2, y: rect.minY),
            control1: CGPoint(x: notchCenterX - notchRadius * 0.35, y: rect.minY - notchDepth),
            control2: CGPoint(x: notchCenterX - notchRadius * 0.65, y: rect.minY)
        )
        
        // Left side
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        
        path.closeSubpath()
        return path
    }
}

extension Notification.Name {
    static let hideTabBar = Notification.Name("HideTabBar")
    static let showTabBar = Notification.Name("ShowTabBar")
    static let refreshInbox = Notification.Name("RefreshInbox")
    static let favoriteStatusChanged = Notification.Name("FavoriteStatusChanged")
    static let switchToTicketsTab = Notification.Name("SwitchToTicketsTab")
        // Messaging notifications
        static let messageSavedLocally = Notification.Name("MessageSavedLocally")
        static let messageUpserted = Notification.Name("MessageUpserted")
        static let openConversation = Notification.Name("OpenConversation")
}

