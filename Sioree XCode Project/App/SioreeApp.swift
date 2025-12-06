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
    @AppStorage("colorScheme") private var colorScheme: String = "dark"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(colorScheme == "light" ? .light : .dark)
        }
    }
}

