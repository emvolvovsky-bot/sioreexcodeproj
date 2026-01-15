//
//  SioreeApp.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
// Stripe import removed - payments not implemented

@main
struct SioreeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var talentViewModel = TalentViewModel()

    init() {
        // Request push notification permissions on app launch
        NotificationService.shared.requestAuthorization()

        // Stripe configuration removed - payments not implemented
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(talentViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

