//
//  RoleRootView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct RoleRootView: View {
    @State var role: UserRole
    let onRoleChange: () -> Void
    @State private var selectedTab = 0
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var talentViewModel: TalentViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tab.view
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(index)
            }
        }
        .accentColor(Color.sioreeIcyBlue)
        .onChange(of: selectedRoleRaw) { newValue in
            if let newRole = UserRole(rawValue: newValue) {
                role = newRole
            }
        }
        .toolbarBackground(.hidden, for: .tabBar)
    }
    
    private var tabs: [(title: String, icon: String, view: AnyView)] {
        switch role {
        case .host:
            return [
                ("Home", "house.fill", AnyView(HostHomeView())),
                ("My Events", "calendar", AnyView(MyEventsView())),
                ("Marketplace", "bag.fill", AnyView(HostMarketplaceView())),
                ("Inbox", "envelope.fill", AnyView(HostInboxView())),
                ("Profile", "person.fill", AnyView(HostProfileView()))
            ]
        case .partier:
            return [
                ("Home", "house.fill", AnyView(PartierHomeView())),
                ("Map", "map.fill", AnyView(PartierMapView(viewModel: HomeViewModel(), locationManager: LocationManager()))),
                ("Tickets", "ticket.fill", AnyView(TicketsView())),
                ("Inbox", "envelope.fill", AnyView(PartierInboxView())),
                ("Profile", "person.fill", AnyView(PartierProfileView()))
            ]
        case .talent:
            return [
                ("Gigs", "briefcase.fill", AnyView(TalentGigsView().environmentObject(talentViewModel))),
                ("Map", "map.fill", AnyView(TalentEventsMapView())),
                ("Inbox", "envelope.fill", AnyView(TalentInboxView())),
                ("Profile", "person.fill", AnyView(TalentProfileView().environmentObject(authViewModel)))
            ]
        }
    }
}

#Preview {
    RoleRootView(role: .host, onRoleChange: {})
        .environmentObject(AuthViewModel())
}

