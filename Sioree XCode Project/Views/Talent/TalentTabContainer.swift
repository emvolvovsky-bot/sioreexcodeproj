//
//  TalentTabContainer.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

enum TalentTab: CaseIterable {
    case gigs
    case inbox
    case profile
}

struct TalentTabContainer: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var talentViewModel: TalentViewModel
    @State private var selectedTab: TalentTab = .gigs
    @State private var hideTabBar = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TalentGigsView()
                    .environmentObject(talentViewModel)
                    .tag(TalentTab.gigs)
                    .tabItem { EmptyView() }

                TalentInboxView()
                    .tag(TalentTab.inbox)
                    .tabItem { EmptyView() }
                
                TalentProfileView()
                    .environmentObject(authViewModel)
                    .tag(TalentTab.profile)
                    .tabItem { EmptyView() }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .tabBar)
            
            if !hideTabBar {
                TalentBottomBar(selectedTab: $selectedTab)
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

private struct TalentBottomBar: View {
    @Binding var selectedTab: TalentTab
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let totalHeight = 70 + safeAreaBottom
            let tabWidth = geometry.size.width / 3
            
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
                    tabButton(.gigs, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.inbox, tabWidth: tabWidth, geometry: geometry)
                    tabButton(.profile, tabWidth: tabWidth, geometry: geometry)
                }
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, safeAreaBottom + Theme.Spacing.xs)
                .frame(width: geometry.size.width, height: totalHeight)
            }
            .frame(width: geometry.size.width, height: totalHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func tabButton(_ tab: TalentTab, tabWidth: CGFloat, geometry: GeometryProxy) -> some View {
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
    
    private func iconName(for tab: TalentTab, isSelected: Bool) -> String {
        switch tab {
        case .gigs:
            return isSelected ? "briefcase.fill" : "briefcase"
        case .inbox:
            return isSelected ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right"
        case .profile:
            return isSelected ? "person.fill" : "person"
        }
    }
}

#Preview {
    TalentTabContainer()
        .environmentObject(AuthViewModel())
        .environmentObject(TalentViewModel())
}
