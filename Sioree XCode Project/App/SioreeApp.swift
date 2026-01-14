//
//  SioreeApp.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
// import Stripe  // Temporarily commented out - will uncomment after SDK installation

@main
struct SioreeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var talentViewModel = TalentViewModel()

    init() {
        // Request push notification permissions on app launch
        NotificationService.shared.requestAuthorization()

        // Initialize Stripe
        // Constants.Stripe.configure()  // Temporarily commented out - will uncomment after SDK installation
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

