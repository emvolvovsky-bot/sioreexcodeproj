//
//  TalentMarketplaceProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentMarketplaceProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var earningsViewModel = TalentEarningsViewModel.shared
    @State private var totalGigs = 45
    @State private var avgRating = 4.8
    @State private var showSettings = false
    @State private var showClipsView = false
    @State private var showPortfolioView = false
    @State private var showEditAbout = false
    @State private var isStartingOnboarding = false
    @State private var isLoadingConnectStatus = false
    @State private var connectStatus: BankConnectStatus?
    @State private var payoutErrorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.openURL) private var openURL

    private let bankService = BankAccountService.shared
    
    private var currentUser: User? {
        authViewModel.currentUser
    }
    
    private var aboutText: String {
        currentUser?.bio ?? "Experienced talent with a passion for creating unforgettable experiences."
    }
    
    private var earningsThisMonth: String {
        "$\(earningsViewModel.earningsThisMonth)"
    }
    
    // Mock data for clips, portfolio, and social media
    @State private var clips: [TalentClip] = [
        TalentClip(id: "1", title: "Sunset Rooftop Set", thumbnail: "video.fill", duration: "3:45"),
        TalentClip(id: "2", title: "Warehouse Rave Mix", thumbnail: "music.note.list", duration: "5:20"),
        TalentClip(id: "3", title: "Halloween Party Performance", thumbnail: "party.popper.fill", duration: "4:12"),
        TalentClip(id: "4", title: "Beachside Vibes", thumbnail: "sun.max.fill", duration: "2:58")
    ]
    
    @State private var portfolioItems: [PortfolioItem] = [
        PortfolioItem(id: "1", title: "VIP Lounge Event", image: "star.fill", date: "Oct 2024"),
        PortfolioItem(id: "2", title: "Corporate Mixer", image: "briefcase.fill", date: "Sep 2024"),
        PortfolioItem(id: "3", title: "Underground Rave", image: "music.note", date: "Aug 2024")
    ]
    
    @State private var socialLinks: [SocialLink] = []
    
    private func updateSocialLinks() {
        guard let user = currentUser else { return }
        // Initialize with empty array, can be populated from user data if available
        socialLinks = []
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
                
                Group {
                    if currentUser == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.Spacing.l) {
                                // Profile Header
                                if let user = currentUser {
                                    ProfileHeaderView(user: user)
                                    stripePayoutsCard
                                    
                                    // Stats - Followers, Following, Events, and Username
                                    ProfileStatsView(
                                        followers: user.followerCount,
                                        following: user.followingCount,
                                        username: user.username,
                                        userId: user.id
                                    )
                                }
                        
                        // Metrics (only show if user is talent)
                        if currentUser?.userType == .talent {
                            VStack(spacing: Theme.Spacing.m) {
                                MetricCard(title: "Total Gigs", value: "\(totalGigs)")
                                MetricCard(title: "Avg Rating", value: String(format: "%.1f", avgRating))
                                MetricCard(title: "Earnings This Month", value: earningsThisMonth)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                        
                        // Bio Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            HStack {
                                Text("About")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                
                                Spacer()
                                
                                Button(action: {
                                    showEditAbout = true
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16))
                                        .foregroundColor(.sioreeIcyBlue)
                                }
                            }
                            
                            Text(aboutText)
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Social Media Links
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Connect")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.m) {
                                    ForEach(socialLinks) { link in
                                        SocialLinkButton(link: link)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        
                        // Clips Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            HStack {
                                Text("Clips")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showClipsView = true
                                }
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeIcyBlue)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.m) {
                                    ForEach(clips) { clip in
                                        ClipCard(clip: clip)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        
                        // Portfolio Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            HStack {
                                Text("Portfolio")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showPortfolioView = true
                                }
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeIcyBlue)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.m) {
                                    ForEach(portfolioItems) { item in
                                        PortfolioCard(item: item)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let user = currentUser {
                        Text(user.username)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showClipsView) {
                ClipsView(clips: $clips)
            }
            .sheet(isPresented: $showPortfolioView) {
                PortfolioView(items: $portfolioItems)
            }
            .sheet(isPresented: $showEditAbout) {
                EditAboutView(aboutText: Binding(
                    get: { aboutText },
                    set: { _ in }
                ))
            }
            .alert("Stripe Setup Error", isPresented: .constant(payoutErrorMessage != nil)) {
                Button("OK") {
                    payoutErrorMessage = nil
                }
            } message: {
                if let error = payoutErrorMessage {
                    Text(error)
                }
            }
            .onAppear {
                updateSocialLinks()
                loadStripeConnectStatus()
            }
            .onChange(of: authViewModel.currentUser) { _ in
                updateSocialLinks()
                loadStripeConnectStatus()
            }
        }
    }

    private var stripePayoutsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Stripe payouts")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                    Text(connectStatus?.isReady == true ? "Verified" : "Complete setup to receive payouts")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
                Spacer()
                Button(action: {
                    startStripeOnboarding()
                }) {
                    Text(isStartingOnboarding ? "Starting..." : "Set up")
                        .font(.sioreeBodySmall)
                        .foregroundColor(.sioreeBlack)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.sioreeIcyBlue)
                        .cornerRadius(Theme.CornerRadius.large)
                }
                .disabled(isStartingOnboarding || connectStatus?.isReady == true)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.large)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, Theme.Spacing.s)
    }

    private func loadStripeConnectStatus() {
        guard !isLoadingConnectStatus else { return }
        isLoadingConnectStatus = true
        bankService.fetchOnboardingStatus()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingConnectStatus = false
                    if case .failure(let error) = completion {
                        payoutErrorMessage = error.localizedDescription
                    }
                },
                receiveValue: { status in
                    connectStatus = status
                }
            )
            .store(in: &cancellables)
    }

    private func startStripeOnboarding() {
        guard !isStartingOnboarding else { return }
        isStartingOnboarding = true
        bankService.createOnboardingLink()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isStartingOnboarding = false
                    if case .failure = completion {
                        openStripeFallbackURL()
                    }
                },
                receiveValue: { url in
                    openURL(url)
                }
            )
            .store(in: &cancellables)
    }

    private func openStripeFallbackURL() {
        if let fallbackURL = URL(string: Constants.Stripe.connectOnboardingFallbackURL) {
            openURL(fallbackURL)
        } else {
            payoutErrorMessage = "Unable to start Stripe onboarding. Please try again."
        }
    }
}

// MARK: - Supporting Models
struct TalentClip: Identifiable {
    let id: String
    let title: String
    let thumbnail: String
    var videoURL: String?
    var duration: String? // Optional now
}

struct PortfolioItem: Identifiable {
    let id: String
    let title: String
    let image: String
    let date: String
}

enum SocialPlatform: String, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case youtube = "YouTube"
    case spotify = "Spotify"
    case twitter = "Twitter"
    case soundcloud = "SoundCloud"
    case appleMusic = "Apple Music"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .youtube: return "play.rectangle.fill"
        case .spotify: return "music.note.list"
        case .twitter: return "at"
        case .soundcloud: return "waveform"
        case .appleMusic: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram: return Color(red: 0.8, green: 0.3, blue: 0.6)
        case .tiktok: return Color(red: 0, green: 0.8, blue: 0.8)
        case .youtube: return Color(red: 1, green: 0, blue: 0)
        case .spotify: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .twitter: return Color(red: 0.2, green: 0.6, blue: 1)
        case .soundcloud: return Color(red: 1, green: 0.4, blue: 0)
        case .appleMusic: return Color(red: 1, green: 0.3, blue: 0.3)
        }
    }
}

struct SocialLink: Identifiable {
    let id = UUID()
    let platform: SocialPlatform
    let username: String
    let url: String
}

// MARK: - Supporting Views
struct SocialLinkButton: View {
    let link: SocialLink
    
    var body: some View {
        Button(action: {
            if let url = URL(string: link.url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: link.platform.icon)
                    .font(.system(size: 16))
                    .foregroundColor(link.platform.color)
                
                Text(link.platform.rawValue)
                    .font(.sioreeBodySmall)
                    .foregroundColor(Color.sioreeWhite)
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(Color.sioreeLightGrey.opacity(0.1))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(link.platform.color.opacity(0.5), lineWidth: 2)
            )
        }
    }
}

struct ClipCard: View {
    let clip: TalentClip
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.sioreeLightGrey.opacity(0.2))
                    .frame(width: 160, height: 120)
                
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: clip.thumbnail)
                        .font(.system(size: 40))
                        .foregroundColor(Color.sioreeIcyBlue.opacity(0.7))
                    
                    if let duration = clip.duration, !duration.isEmpty {
                        Text(duration)
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.sioreeBlack.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
            }
            
            Text(clip.title)
                .font(.sioreeBodySmall)
                .foregroundColor(Color.sioreeWhite)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
        }
    }
}

struct PortfolioCard: View {
    let item: PortfolioItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.sioreeLightGrey.opacity(0.2))
                    .frame(width: 160, height: 120)
                
                Image(systemName: item.image)
                    .font(.system(size: 40))
                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.sioreeBodySmall)
                    .foregroundColor(Color.sioreeWhite)
                    .lineLimit(1)
                
                Text(item.date)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey)
            }
            .frame(width: 160, alignment: .leading)
        }
    }
}

#Preview {
    TalentMarketplaceProfileView()
}
