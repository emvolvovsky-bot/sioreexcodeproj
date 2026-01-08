//
//  PartierTabContainer.swift
//  Sioree
//
//  Created by Sioree Team
//
//
import SwiftUI

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
                
                FavoritesPlaceholderView()
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
    }
}

private struct PartierBottomBar: View {
    @Binding var selectedTab: PartierTab
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let totalHeight = 70 + safeAreaBottom
            
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    tabButton(.tickets)
                        .frame(maxWidth: .infinity)
                    tabButton(.inbox)
                        .frame(maxWidth: .infinity)
                    Spacer().frame(width: 76) // space for center notch
                    tabButton(.favorites)
                        .frame(maxWidth: .infinity)
                    tabButton(.profile)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, safeAreaBottom + Theme.Spacing.xs)
                .frame(width: geometry.size.width, height: totalHeight)
                .background(
                    NotchedBarShape()
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
                        .background(.ultraThinMaterial, in: NotchedBarShape())
                        .overlay(
                            NotchedBarShape()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.sioreeIcyBlue.opacity(0.22), radius: 16, x: 0, y: 10)
                )
                
                homeButton
                    .offset(y: -14 - safeAreaBottom)
            }
            .frame(width: geometry.size.width, height: totalHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func tabButton(_ tab: PartierTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: tab.systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.sioreeWhite.opacity(selectedTab == tab ? 0.95 : 0.7))
                .padding(.vertical, Theme.Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .center)
                .shadow(color: Color.sioreeIcyBlue.opacity(selectedTab == tab ? 0.25 : 0.08), radius: selectedTab == tab ? 12 : 4, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
    
    private var homeButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                selectedTab = .home
            }
        } label: {
            Image(systemName: PartierTab.home.systemIcon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.sioreeWhite)
                .frame(width: 64, height: 64)
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
                .shadow(color: Color.sioreeIcyBlue.opacity(0.45), radius: 24, x: 0, y: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PartierTabContainer()
        .environmentObject(AuthViewModel())
}

private struct FavoritesPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: "heart")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundColor(.sioreeIcyBlue)
                Text("Favorites")
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)
                Text("Your saved events will appear here.")
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeLightGrey)
            }
        }
    }
}

// Custom shape with center notch for the floating home button
private struct NotchedBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notchRadius: CGFloat = 36
        let notchWidth: CGFloat = notchRadius * 2 + 16
        let cornerRadius: CGFloat = 26
        let notchDepth: CGFloat = 20
        let notchCenterX = rect.midX
        
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
}

