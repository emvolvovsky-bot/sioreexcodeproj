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
    case profile
    
    var systemIcon: String {
        switch self {
        case .tickets: return "ticket"
        case .inbox: return "bubble.left.and.bubble.right"
        case .home: return "house.fill"
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
                // Home should be the first tab for Partier
                PartierHomeView()
                    .tag(PartierTab.home)
                    .tabItem { EmptyView() }

                PartierInboxView()
                    .tag(PartierTab.inbox)
                    .tabItem { EmptyView() }

                // Tickets moved to the third position
                TicketsView()
                    .tag(PartierTab.tickets)
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
            let tabWidth = geometry.size.width / 4
            
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
                    // Order changed: Home first, Inbox second, Tickets third, Profile fourth
                    tabButton(.home, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.inbox, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.tickets, tabWidth: tabWidth, geometry: geometry)
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
        case .profile:
            return isSelected ? "person.fill" : "person"
        }
    }
}

#Preview {
    PartierTabContainer()
        .environmentObject(AuthViewModel())
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
    static let switchToTicketsTab = Notification.Name("SwitchToTicketsTab")
        // Messaging notifications
        static let messageSavedLocally = Notification.Name("MessageSavedLocally")
        static let messageUpserted = Notification.Name("MessageUpserted")
    static let messageReactionAdded = Notification.Name("MessageReactionAdded")
        static let openConversation = Notification.Name("OpenConversation")
}

