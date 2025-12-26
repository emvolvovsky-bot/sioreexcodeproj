//
//  SioreeApp.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

@main
struct SioreeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Request push notification permissions on app launch
        NotificationService.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

