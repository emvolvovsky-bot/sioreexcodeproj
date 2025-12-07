//
//  HostHomeView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct HostHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var recommendedTalent = Array(MockData.sampleTalent.prefix(5))
    @State private var recentSignups: [EventSignup] = []
    @State private var isLoadingSignups = false
    @State private var signupsError: String?
    private let networkService = NetworkService()
    
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        // Header
                        Text("Recent Signups")
                            .font(.sioreeH2)
                            .foregroundColor(Color.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.top, Theme.Spacing.m)
                        
                        if isLoadingSignups {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xl)
                        } else if recentSignups.isEmpty {
                            // Empty state
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                
                                Text("No recent signups")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                
                                Text("People who sign up for your events will appear here")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Theme.Spacing.xl)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.xxl)
                        } else {
                            // Signups list
                            VStack(spacing: Theme.Spacing.s) {
                                ForEach(recentSignups) { signup in
                                    NavigationLink(destination: UserProfileView(userId: signup.userId)) {
                                        RecentSignupRow(signup: signup)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.top, Theme.Spacing.s)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Host Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !viewModel.hasLoaded {
                    viewModel.loadNearbyEvents()
                }
                loadRecentSignups()
            }
        }
    }
    
    private func loadRecentSignups() {
        isLoadingSignups = true
        signupsError = nil
        
        networkService.fetchRecentEventSignups()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingSignups = false
                    if case .failure(let error) = completion {
                        signupsError = error.localizedDescription
                        print("❌ Failed to load recent signups: \(error)")
                    }
                },
                receiveValue: { signups in
                    isLoadingSignups = false
                    recentSignups = signups
                    print("✅ Loaded \(signups.count) recent signups")
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct RecentSignupRow: View {
    let signup: EventSignup
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            AvatarView(imageURL: signup.userAvatar, size: .medium)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(signup.userName)
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.sioreeWhite)
                    
                    Text("signed up for")
                        .font(.sioreeBodySmall)
                        .foregroundColor(.sioreeLightGrey)
                }
                
                Text(signup.eventTitle)
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeIcyBlue)
                
                Text(timeAgoString(from: signup.signedUpAt))
                    .font(.sioreeCaption)
                    .foregroundColor(.sioreeLightGrey.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.sioreeLightGrey)
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    HostHomeView()
}

