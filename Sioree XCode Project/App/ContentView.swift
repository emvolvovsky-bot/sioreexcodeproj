//
//  ContentView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedUserRole") private var selectedRoleRaw: String = ""
    @AppStorage("hasCompletedRoleSelection") private var hasCompletedRoleSelection: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    @State private var selectedRole: UserRole?
    @State private var showRoleSelection = false
    @State private var showSplash = false
    @State private var isBackendConnected = false

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
                // Restore role from storage if available
                Group {
                    if selectedRole == nil && !selectedRoleRaw.isEmpty,
                       let role = UserRole(rawValue: selectedRoleRaw) {
                        // Role will be set by the onChange handler below
                        EmptyView()
                            .onAppear {
                                selectedRole = role
                                hasCompletedRoleSelection = true
                                print("✅ Restored role from storage: \(role.rawValue)")
                            }
                    } else if let role = selectedRole, hasCompletedRoleSelection {
                        RoleRootView(role: role, onRoleChange: {})
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        RoleSelectionView(selectedRole: $selectedRole, isChangingRole: false)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .onChange(of: selectedRole) { newValue in
                                if let role = newValue {
                                    selectedRoleRaw = role.rawValue
                                    hasCompletedRoleSelection = true
                                    print("✅ Role selected: \(role.rawValue)")
                                }
                            }
                    }
                }
            }

            else {
                if hasSeenOnboarding {
                    LoginView()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    OnboardingView()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .onAppear { hasSeenOnboarding = true }
                }
            }
            }
            
            // Backend Status Indicator - Fire emoji when connected
            if isBackendConnected {
                VStack {
                    HStack {
                        Spacer()
                        Text("🔥")
                            .font(.system(size: 24))
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: selectedRole != nil)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: isBackendConnected)
        .onAppear {
            print("📱 ContentView appeared - isAuthenticated: \(authViewModel.isAuthenticated)")
            print("📱 ContentView - selectedRoleRaw: \(selectedRoleRaw)")
            print("📱 ContentView - hasCompletedRoleSelection: \(hasCompletedRoleSelection)")
            
            if !selectedRoleRaw.isEmpty,
               let role = UserRole(rawValue: selectedRoleRaw) {
                selectedRole = role
                print("✅ Restored role from storage: \(role.rawValue)")
            }

            // Show splash on launch - always show for 2 seconds
            showSplash = true

            // 🔥🔥 TEST BACKEND CONNECTION HERE
            Task {
                await checkBackendConnection()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            print("🔄 Auth state changed: \(oldValue) -> \(newValue)")
            // Don't show splash when logging out - only on initial launch
            // If user just logged in, make sure role is loaded from storage
            if newValue && oldValue == false {
                if !selectedRoleRaw.isEmpty,
                   let role = UserRole(rawValue: selectedRoleRaw) {
                    selectedRole = role
                    print("✅ Restored role from storage: \(role.rawValue)")
                }
            }
        }
    }

    // MARK: - Backend Test
    func checkBackendConnection() async {
        do {
            let response: HealthResponse = try await APIService.shared.request("/health")
            print("🔥 BACKEND CONNECTED → \(response.status)")
            await MainActor.run {
                isBackendConnected = true
            }
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                print("❌ BACKEND ERROR → No Internet")
            case .cannotConnectToHost:
                print("❌ BACKEND ERROR → Cannot Connect to Backend")
            case .timedOut:
                print("❌ BACKEND ERROR → Connection Timeout")
            default:
                print("❌ BACKEND ERROR → \(error.localizedDescription)")
            }
            await MainActor.run {
                isBackendConnected = false
            }
        } catch {
            print("❌ BACKEND ERROR → \(error.localizedDescription)")
            await MainActor.run {
                isBackendConnected = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
