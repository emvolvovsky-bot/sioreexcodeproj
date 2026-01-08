//
//  HostTabContainer.swift
//  Sioree
//
//  Created by Sioree Team
//
//
import SwiftUI

enum HostTab: CaseIterable {
    case notifications
    case inbox
    case home
    case talentRequests
    case profile
    
    var systemIcon: String {
        switch self {
        case .notifications: return "bell.fill"
        case .inbox: return "bubble.left.and.bubble.right"
        case .home: return "house.fill"
        case .talentRequests: return "person.2.circle.fill"
        case .profile: return "person"
        }
    }
}

struct HostTabContainer: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: HostTab = .home
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var sharedLocationManager = LocationManager()
    @State private var hideTabBar = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HostNotificationsView()
                    .tag(HostTab.notifications)
                    .tabItem { EmptyView() }
                
                HostInboxView()
                    .tag(HostTab.inbox)
                    .tabItem { EmptyView() }
                
                HostMyEventsView()
                    .tag(HostTab.home)
                    .tabItem { EmptyView() }
                
                HostTalentRequestsView()
                    .tag(HostTab.talentRequests)
                    .tabItem { EmptyView() }
                
                HostProfileView()
                    .tag(HostTab.profile)
                    .tabItem { EmptyView() }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .tabBar)
            
            if !hideTabBar {
                HostBottomBar(selectedTab: $selectedTab)
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

private struct HostBottomBar: View {
    @Binding var selectedTab: HostTab
    @Namespace private var tabAnimation
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let totalHeight = 70 + safeAreaBottom
            let tabWidth = (geometry.size.width - 76 - Theme.Spacing.s * 2) / 4 // Account for center notch and padding
            
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    tabButton(.notifications, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.inbox, tabWidth: tabWidth, geometry: geometry)
                    Spacer().frame(width: 76) // space for center notch
                    tabButton(.talentRequests, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.profile, tabWidth: tabWidth, geometry: geometry)
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
                .overlay(alignment: .top) {
                    // Sliding indicator for regular tabs - overlay on top of HStack
                    if selectedTab != .home {
                        slidingIndicator(tabWidth: tabWidth, geometry: geometry)
                            .offset(y: 8) // Positioned lower, centered on icons
                    }
                }
                
                homeButton
                    .offset(y: -14 - safeAreaBottom)
            }
            .frame(width: geometry.size.width, height: totalHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func tabButton(_ tab: HostTab, tabWidth: CGFloat, geometry: GeometryProxy) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                Image(systemName: tab.systemIcon)
                    .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(.sioreeWhite.opacity(isSelected ? 1.0 : 0.65))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
            }
            .frame(width: tabWidth, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func slidingIndicator(tabWidth: CGFloat, geometry: GeometryProxy) -> some View {
        let padding = Theme.Spacing.s
        let centerNotchWidth: CGFloat = 76
        
        // Calculate the center X position of the selected tab
        let centerX: CGFloat = {
            switch selectedTab {
            case .notifications:
                return padding + tabWidth / 2
            case .inbox:
                return padding + tabWidth * 1.5
            case .talentRequests:
                return padding + tabWidth * 2 + centerNotchWidth + tabWidth / 2
            case .profile:
                return padding + tabWidth * 2 + centerNotchWidth + tabWidth * 1.5
            case .home:
                return geometry.size.width / 2 // Center (shouldn't be used, but fallback)
            }
        }()
        
        return RoundedRectangle(cornerRadius: 28)
            .fill(
                LinearGradient(
                    colors: [
                        Color.sioreeIcyBlue.opacity(0.06),
                        Color.sioreeIcyBlue.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .frame(width: 56, height: 48)
            .offset(x: centerX - geometry.size.width / 2) // Offset from center of screen
            .matchedGeometryEffect(id: "tabIndicator", in: tabAnimation)
    }
    
    private var homeButton: some View {
        let isSelected = selectedTab == .home
        
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = .home
            }
        } label: {
            Image(systemName: HostTab.home.systemIcon)
                .font(.system(size: isSelected ? 24 : 22, weight: .bold))
                .foregroundColor(.sioreeWhite)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.sioreeIcyBlue.opacity(isSelected ? 1.0 : 0.9),
                                    Color.sioreeIcyBlue.opacity(isSelected ? 0.95 : 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Color.sioreeIcyBlue.opacity(isSelected ? 0.55 : 0.45),
                    radius: isSelected ? 28 : 24,
                    x: 0,
                    y: isSelected ? 12 : 10
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.3 : 0.25), lineWidth: isSelected ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
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

#Preview {
    HostTabContainer()
        .environmentObject(AuthViewModel())
}

