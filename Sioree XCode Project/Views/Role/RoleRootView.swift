//
//  RoleRootView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct RoleRootView: View {
    let role: UserRole
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var talentViewModel: TalentViewModel
    
    var body: some View {
        Group {
            if role == .partier {
                PartierTabContainer()
            } else {
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
                .toolbarBackground(.hidden, for: .tabBar)
            }
        }
    }
    
    private var tabs: [(title: String, icon: String, view: AnyView)] {
        switch role {
        case .host:
            return [
                ("Home", "house.fill", AnyView(HostHomeView())),
                ("My Events", "calendar", AnyView(MyEventsView())),
                ("Talent Requests", "person.2.circle.fill", AnyView(HostTalentRequestsView())),
                ("Inbox", "envelope.fill", AnyView(HostInboxView())),
                ("Profile", "person.fill", AnyView(HostProfileView()))
            ]
        case .partier:
            return [
                ("Home", "house.fill", AnyView(PartierTabContainer())),
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
    RoleRootView(role: .host)
        .environmentObject(AuthViewModel())
}

