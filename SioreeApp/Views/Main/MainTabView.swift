//
//  MainTabView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    private var profileView: some View {
        Group {
            if let userType = authViewModel.currentUser?.userType {
                switch userType {
                case .host:
                    HostProfileView()
                case .partier:
                    PartierProfileView()
                case .talent:
                    TalentProfileView()
                }
            } else {
                ProfileView() // Fallback to general profile view
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            CreateView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)

            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(3)

            profileView
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(Color.sioreeIcyBlue)
    }
}

#Preview {
    MainTabView()
}

