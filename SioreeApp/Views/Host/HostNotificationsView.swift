//
//  HostNotificationsView.swift
//  Sioree
//
//  Created by Sioree Team
//
//
import SwiftUI
import Combine

struct HostNotificationsView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var recentSignups: [EventSignup] = []
    @State private var isLoadingSignups = false
    @State private var signupsError: String?
    @State private var lastUpdated: Date?
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.08, blue: 0.15), location: 0.0),
                        .init(color: Color.sioreeBlack.opacity(0.92), location: 0.45),
                        .init(color: Color.sioreeBlack.opacity(0.98), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 60,
                        endRadius: 420
                    )
                    .blendMode(.screen)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.35),
                            Color.clear,
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        header
                        recentSignupsSection
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.l)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if !viewModel.hasLoaded {
                    viewModel.loadNearbyEvents()
                }
                loadRecentSignups()
            }
            .onReceive(refreshTimer) { _ in
                loadRecentSignups()
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Notifications")
                .font(.sioreeH1)
                .foregroundColor(.sioreeWhite)
                .padding(.top, Theme.Spacing.l)
            
            Text("Track your recent signups.")
                .font(.sioreeBodySmall)
                .foregroundColor(.sioreeLightGrey.opacity(0.8))
        }
    }
    
    private var recentSignupsSection: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(spacing: Theme.Spacing.s) {
                    Text("Recent signups")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                    Spacer()
                    Text(updatedLabel)
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey.opacity(0.85))
                    Button(action: loadRecentSignups) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.sioreeIcyBlue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.sioreeIcyBlue.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Group {
                    if isLoadingSignups {
                        skeletonList
                    } else if let signupsError {
                        InfoBanner(
                            systemImage: "wifi.exclamationmark",
                            message: signupsError,
                            tint: .sioreeWarmGlow
                        )
                    } else if recentSignups.isEmpty {
                        Text("No recent signups yet.")
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.vertical, Theme.Spacing.s)
                    } else {
                        LazyVStack(spacing: Theme.Spacing.s) {
                            ForEach(recentSignups.sorted { $0.signedUpAt > $1.signedUpAt }) { signup in
                                NavigationLink(destination: UserProfileView(userId: signup.userId)) {
                                    RecentSignupRow(signup: signup)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var updatedLabel: String {
        if let lastUpdated {
            return "Updated \(timeAgoString(from: lastUpdated))"
        }
        return "Updated just now"
    }
    
    private func dashboardCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.sioreeCharcoal.opacity(0.7),
                                Color.sioreeBlack.opacity(0.75),
                                Color.sioreeCharcoal.opacity(0.55)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.08),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.screen)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.sioreeIcyBlue.opacity(0.45), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 14)
            .shadow(color: Color.sioreeIcyBlue.opacity(0.2), radius: 22, x: 0, y: 10)
    }
    
    private var refreshTimer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 20, on: .main, in: .common).autoconnect()
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
                    lastUpdated = Date()
                    print("✅ Loaded \(signups.count) recent signups")
                }
            )
            .store(in: &cancellables)
    }
    
    private var skeletonList: some View {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(0..<3) { _ in ShimmerRow() }
        }
    }
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

#Preview {
    HostNotificationsView()
}

