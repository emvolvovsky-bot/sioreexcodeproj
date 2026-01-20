//
//  RoleRootView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct RoleRootView: View {
    let role: UserRole
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var talentViewModel: TalentViewModel
    
    var body: some View {
        Group {
            switch role {
            case .partier:
                PartierTabContainer()
            case .host:
                HostTabContainer()
            case .talent:
                TalentTabContainer()
            }
        }
    }
}

#Preview {
    RoleRootView(role: .host)
        .environmentObject(AuthViewModel())
}

