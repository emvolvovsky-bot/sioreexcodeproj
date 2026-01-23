//
//  ContentView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var talentViewModel: TalentViewModel
    @State private var showSplash = true
    @State private var appReady = false
    @State private var showBankConnectSheet = false
    @State private var eventDeepLink: EventDeepLink?
    @State private var pendingEventDeepLink: EventDeepLink?
    
    private var activeRole: UserRole? {
        if let userType = authViewModel.currentUser?.userType {
            return UserRole(rawValue: userType.rawValue)
        }
        if let storedType = StorageService.shared.getUserType() {
            return UserRole(rawValue: storedType.rawValue)
        }
        return nil
    }

    var body: some View {
        ZStack {
            Group {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1000)
                } else if authViewModel.isAuthenticated {
                    if let role = activeRole {
                        RoleRootView(role: role)
                            .environmentObject(authViewModel)
                            .environmentObject(talentViewModel)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        LoadingView(useDarkBackground: true)
                            .onAppear {
                                authViewModel.fetchCurrentUser()
                            }
                    }
                } else {
                    OnboardingView()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onChange(of: appReady) { _, isReady in
            if isReady {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Small delay for smooth transition
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
        .onAppear {
            print("📱 ContentView appeared - isAuthenticated: \(authViewModel.isAuthenticated)")

            // Log which server the app is connecting to
            logServerConnection()

            // Show splash until app is ready
            showSplash = true
            checkAppReady()
            presentBankConnectIfNeeded()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, _ in
            presentBankConnectIfNeeded()
            checkAppReady()
            if authViewModel.isAuthenticated, let pendingEventDeepLink {
                eventDeepLink = pendingEventDeepLink
                self.pendingEventDeepLink = nil
            }
        }
        .onChange(of: authViewModel.currentUser?.userType) { _, _ in
            presentBankConnectIfNeeded()
            checkAppReady()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .sheet(isPresented: $showBankConnectSheet, onDismiss: {
            StorageService.shared.clearNeedsBankConnect()
        }) {
            BankConnectOnboardingView(onConnect: { _ in })
        }
        .sheet(item: $eventDeepLink) { deepLink in
            EventDetailView(eventId: deepLink.id, isTalentMapMode: false)
                .environmentObject(authViewModel)
                .environmentObject(talentViewModel)
        }
    }

    private func checkAppReady() {
        // App is ready when:
        // 1. User is not authenticated (show onboarding)
        // 2. User is authenticated AND has a role
        if !authViewModel.isAuthenticated || activeRole != nil {
            appReady = true
        } else {
            appReady = false
        }
    }

    private func presentBankConnectIfNeeded() {
        guard authViewModel.isAuthenticated else { return }
        guard StorageService.shared.needsBankConnect() else { return }
        let userType = authViewModel.currentUser?.userType ?? StorageService.shared.getUserType()
        if userType == .host || userType == .talent {
            showBankConnectSheet = true
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "sioree" else { return }
        guard let eventId = eventIdFromDeepLink(url) else { return }
        let deepLink = EventDeepLink(id: eventId)
        if authViewModel.isAuthenticated {
            eventDeepLink = deepLink
        } else {
            pendingEventDeepLink = deepLink
        }
    }

    private func eventIdFromDeepLink(_ url: URL) -> String? {
        let host = url.host?.lowercased()
        if host == "event" || host == "events" {
            return url.pathComponents.dropFirst().first
        }
        if url.pathComponents.count >= 3, url.pathComponents[1].lowercased() == "event" || url.pathComponents[1].lowercased() == "events" {
            return url.pathComponents.dropFirst(2).first
        }
        return nil
    }

    private func logServerConnection() {
        let useLocal = Constants.shouldUseLocalServer()
        let serverURL = Constants.API.baseURL
        let serverType = useLocal ? "LOCAL DEVELOPMENT" : "RENDER PRODUCTION"
        let serverIcon = useLocal ? "🏠" : "☁️"

        print("\(serverIcon) App connecting to: \(serverType) server (determined by local.txt)")
        print("🔗 API URL: \(serverURL)")
    }
}

private struct EventDeepLink: Identifiable {
    let id: String
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
