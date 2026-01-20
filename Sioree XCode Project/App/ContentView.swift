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
    @State private var showSplash = false
    @State private var showBankConnectSheet = false
    
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
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSplash = false
                            }
                        }
                    }
            }

                else if authViewModel.isAuthenticated {
                    if let role = activeRole {
                        RoleRootView(role: role)
                            .environmentObject(authViewModel)
                            .environmentObject(talentViewModel)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        LoadingView()
                            .onAppear {
                                authViewModel.fetchCurrentUser()
                            }
                    }
            }

            else {
                OnboardingView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onAppear {
            print("📱 ContentView appeared - isAuthenticated: \(authViewModel.isAuthenticated)")

            // Show splash on launch - always show for 2 seconds
            showSplash = true
            presentBankConnectIfNeeded()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, _ in
            presentBankConnectIfNeeded()
        }
        .onChange(of: authViewModel.currentUser?.userType) { _, _ in
            presentBankConnectIfNeeded()
        }
        .sheet(isPresented: $showBankConnectSheet, onDismiss: {
            StorageService.shared.clearNeedsBankConnect()
        }) {
            BankConnectOnboardingView(onConnect: { _ in })
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
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
