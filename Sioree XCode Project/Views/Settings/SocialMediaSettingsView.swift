//
//  SocialMediaSettingsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine
import AuthenticationServices

struct SocialMediaSettingsView: View {
    @StateObject private var socialService = SocialMediaService.shared
    @State private var connectedAccounts: [ConnectedSocialAccount] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPlatformSelection = false
    
    var body: some View {
        ZStack {
            // Subtle gradient on black background
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
            } else {
                List {
                    Section {
                        ForEach(connectedAccounts) { account in
                            ConnectedAccountRow(account: account) {
                                disconnectAccount(account.id)
                            }
                        }
                        
                        Button(action: {
                            showPlatformSelection = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Connect Account")
                                    .font(.sioreeBody)
                            }
                            .foregroundColor(.sioreeIcyBlue)
                        }
                    } header: {
                        Text("Connected Accounts")
                            .foregroundColor(.sioreeLightGrey)
                    } footer: {
                        Text("Connect your social media accounts to verify your identity and share your content.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Social Media")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadConnectedAccounts()
        }
        .fullScreenCover(isPresented: $showPlatformSelection) {
            PlatformSelectionView(onPlatformSelected: { platform in
                connectPlatform(platform)
            })
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadConnectedAccounts() {
        isLoading = true
        socialService.getConnectedAccounts()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { accounts in
                    self.connectedAccounts = accounts
                }
            )
            .store(in: &cancellables)
    }
    
    private func connectPlatform(_ platform: SocialPlatform) {
        isLoading = true
        let publisher: AnyPublisher<ConnectedSocialAccount, Error>
        
        switch platform {
        case .instagram:
            publisher = socialService.connectInstagram()
        case .tiktok:
            publisher = socialService.connectTikTok()
        case .youtube:
            publisher = socialService.connectYouTube()
        case .spotify:
            publisher = socialService.connectSpotify()
        default:
            publisher = socialService.connectInstagram() // Default fallback
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { account in
                    connectedAccounts.append(account)
                    showPlatformSelection = false
                }
            )
            .store(in: &cancellables)
    }
    
    private func disconnectAccount(_ accountId: String) {
        socialService.disconnectAccount(accountId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { success in
                    if success {
                        connectedAccounts.removeAll { $0.id == accountId }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct ConnectedAccountRow: View {
    let account: ConnectedSocialAccount
    let onDisconnect: () -> Void
    
    var platform: SocialPlatform {
        SocialPlatform.allCases.first { $0.rawValue.lowercased() == account.platform.lowercased() } ?? .instagram
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            // Platform Logo
            PlatformLogoView(platform: platform)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform.rawValue)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                Text(account.username)
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
            }
            
            Spacer()
            
            if account.isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            }
            
            Button(action: onDisconnect) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
            }
        }
    }
}

struct PlatformSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let onPlatformSelected: (SocialPlatform) -> Void
    
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
                    Section {
                        ForEach(SocialPlatform.allCases) { platform in
                            Button(action: {
                                onPlatformSelected(platform)
                            }) {
                                HStack(spacing: Theme.Spacing.m) {
                                    // Platform Logo
                                    PlatformLogoView(platform: platform)
                                        .frame(width: 40, height: 40)
                                    
                                    Text(platform.rawValue)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.sioreeLightGrey)
                                }
                            }
                        }
                    } header: {
                        Text("Select Platform")
                            .foregroundColor(.sioreeLightGrey)
                    } footer: {
                        Text("You'll be asked to sign in to verify your account.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Connect Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
}

// MARK: - Platform Logo View
struct PlatformLogoView: View {
    let platform: SocialPlatform
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(platform.color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(platform.color, lineWidth: 1)
                )
            
            Image(systemName: platformLogoIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(platform.color)
        }
    }
    
    private var platformLogoIcon: String {
        switch platform {
        case .instagram:
            return "camera.fill"
        case .tiktok:
            return "music.note"
        case .youtube:
            return "play.rectangle.fill"
        case .spotify:
            return "music.note.list"
        case .twitter:
            return "at"
        case .soundcloud:
            return "waveform"
        case .appleMusic:
            return "music.note"
        }
    }
}

struct AddSocialLinkView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var links: [SocialLink]
    @State private var selectedPlatform: SocialPlatform = .instagram
    @State private var username = ""
    @State private var url = ""
    
    private var isFormValid: Bool {
        !username.isEmpty && !url.isEmpty
    }
    
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
                
                Form {
                    Section("Platform") {
                        Picker("Platform", selection: $selectedPlatform) {
                            ForEach(SocialPlatform.allCases) { platform in
                                HStack {
                                    Image(systemName: platform.icon)
                                    Text(platform.rawValue)
                                }
                                .tag(platform)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Details") {
                        CustomTextField(placeholder: "Username", text: $username)
                        CustomTextField(placeholder: "URL", text: $url)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Social Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeWhite)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newLink = SocialLink(
                            platform: selectedPlatform,
                            username: username,
                            url: url
                        )
                        links.append(newLink)
                        dismiss()
                    }
                    .foregroundColor(isFormValid ? Color.sioreeIcyBlue : Color.sioreeLightGrey)
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SocialMediaSettingsView()
    }
}

