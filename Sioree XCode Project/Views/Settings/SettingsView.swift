//
//  SettingsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var notificationsEnabled = true
    @State private var emailNotifications = true
    @State private var pushNotifications = true
    @State private var showPaymentMethods = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showAbout = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List {
                    // Account Section
                    Section {
                        NavigationLink(destination: EditProfileSettingsView()) {
                            SettingsRow(icon: "person.circle", title: "Edit Profile", color: .sioreeIcyBlue)
                        }
                        
                        NavigationLink(destination: PaymentMethodsView()) {
                            SettingsRow(icon: "creditcard", title: "Payment Methods", color: .sioreeIcyBlue)
                        }
                        
                        NavigationLink(destination: BankAccountsView()) {
                            SettingsRow(icon: "building.columns", title: "Bank Accounts", color: .sioreeIcyBlue)
                        }
                    } header: {
                        Text("Account")
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    // Notifications Section
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            SettingsRow(icon: "bell", title: "Notifications", color: .sioreeIcyBlue)
                        }
                        
                        if notificationsEnabled {
                            Toggle(isOn: $emailNotifications) {
                                SettingsRow(icon: "envelope", title: "Email Notifications", color: .sioreeLightGrey)
                            }
                            
                            Toggle(isOn: $pushNotifications) {
                                SettingsRow(icon: "bell.badge", title: "Push Notifications", color: .sioreeLightGrey)
                            }
                        }
                    } header: {
                        Text("Notifications")
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    // Privacy & Security Section
                    Section {
                        NavigationLink(destination: PrivacySettingsView()) {
                            SettingsRow(icon: "lock", title: "Privacy", color: .sioreeIcyBlue)
                        }
                        
                        NavigationLink(destination: SecuritySettingsView()) {
                            SettingsRow(icon: "shield", title: "Security", color: .sioreeIcyBlue)
                        }
                        
                        NavigationLink(destination: BlockedUsersView()) {
                            SettingsRow(icon: "person.crop.circle.badge.xmark", title: "Blocked Users", color: .sioreeLightGrey)
                        }
                    } header: {
                        Text("Privacy & Security")
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    // App Settings Section
                    Section {
                        NavigationLink(destination: LanguageSettingsView()) {
                            SettingsRow(icon: "globe", title: "Language", color: .sioreeIcyBlue)
                        }
                        
                        NavigationLink(destination: DataUsageView()) {
                            SettingsRow(icon: "arrow.down.circle", title: "Data Usage", color: .sioreeLightGrey)
                        }
                    } header: {
                        Text("App Settings")
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    // Support Section
                    Section {
                        NavigationLink(destination: HelpCenterView()) {
                            SettingsRow(icon: "questionmark.circle", title: "Help Center", color: .sioreeIcyBlue)
                        }
                        
                        NavigationLink(destination: ContactSupportView()) {
                            SettingsRow(icon: "message", title: "Contact Support", color: .sioreeIcyBlue)
                        }
                        
                        Button(action: {
                            showTerms = true
                        }) {
                            SettingsRow(icon: "doc.text", title: "Terms of Service", color: .sioreeLightGrey)
                        }
                        
                        Button(action: {
                            showPrivacy = true
                        }) {
                            SettingsRow(icon: "hand.raised", title: "Privacy Policy", color: .sioreeLightGrey)
                        }
                        
                        Button(action: {
                            showAbout = true
                        }) {
                            SettingsRow(icon: "info.circle", title: "About", color: .sioreeLightGrey)
                        }
                    } header: {
                        Text("Support")
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    // Account Actions Section
                    Section {
                        Button(action: {
                            showSignOutAlert = true
                        }) {
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 20))
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                
                                Text("Sign Out")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeIcyBlue)
                                
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            showDeleteAccountAlert = true
                        }) {
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                
                                Text("Delete Account")
                                    .font(.sioreeBody)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Account Actions")
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadNotificationPreferences()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .sheet(isPresented: $showTerms) {
                TermsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                            .scaleEffect(1.5)
                    }
                }
            }
        }
    }
    
    private func signOut() {
        print("🚪 Signing out...")
        authViewModel.logout()
        dismiss()
    }
    
    private func deleteAccount() {
        isDeletingAccount = true
        print("🗑️ Deleting account...")
        let authService = AuthService()
        authService.deleteAccount()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isDeletingAccount = false
                    if case .failure(let error) = completion {
                        print("❌ Error deleting account: \(error)")
                        showDeleteAccountAlert = false
                    } else {
                        print("✅ Account deleted successfully")
                        signOut()
                    }
                },
                receiveValue: { success in
                    isDeletingAccount = false
                    print("✅ Delete account response: \(success)")
                    signOut()
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private func saveNotificationPreferences() {
        // Save notification preferences to UserDefaults
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(emailNotifications, forKey: "emailNotifications")
        UserDefaults.standard.set(pushNotifications, forKey: "pushNotifications")
        
        // Send preferences to backend
        let networkService = NetworkService()
        let body: [String: Any] = [
            "notificationsEnabled": notificationsEnabled,
            "emailNotifications": emailNotifications,
            "pushNotifications": pushNotifications
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        let publisher: AnyPublisher<NotificationPreferencesResponse, Error> = networkService.request("/api/users/notification-preferences", method: "PATCH", body: jsonData)
        
        publisher
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to save notification preferences: \(error)")
                }
            },
            receiveValue: { (_: NotificationPreferencesResponse) in
                print("✅ Notification preferences saved")
            }
        )
        .store(in: &cancellables)
    }

    private struct NotificationPreferencesResponse: Decodable {
        let success: Bool?
        let message: String?
    }
    
    private func loadNotificationPreferences() {
        // Load from UserDefaults
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        emailNotifications = UserDefaults.standard.bool(forKey: "emailNotifications")
        pushNotifications = UserDefaults.standard.bool(forKey: "pushNotifications")
        
        // If preferences are enabled, request authorization
        if notificationsEnabled || pushNotifications {
            NotificationService.shared.requestAuthorization()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.sioreeBody)
                .foregroundColor(.sioreeWhite)
        }
    }
}

#Preview {
    SettingsView()
}

