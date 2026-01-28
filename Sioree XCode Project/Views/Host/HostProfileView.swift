//
//  HostProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct HostProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var selectedEventForPhotos: Event? = nil
    @State private var selectedEventForPost: Event?
    @State private var isStartingOnboarding = false
    @State private var isLoadingConnectStatus = false
    @State private var connectStatus: BankConnectStatus?
    @State private var payoutErrorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    private let bankService = BankAccountService.shared
    
    private var currentUser: User? {
        authViewModel.currentUser
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.sioreeBlack,
                Color.sioreeBlack.opacity(0.98),
                Color.sioreeCharcoal.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var mainContent: some View {
        Group {
            if currentUser == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let user = currentUser {
                userProfileContent(user: user)
            }
        }
    }

    private func userProfileContent(user: User) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader(user: user)
                stripePayoutsCard
                eventsSection
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func profileHeader(user: User) -> some View {
        InstagramStyleProfileHeader(
            user: user,
            postsCount: viewModel.events.count,
            followerCount: viewModel.followerCount,
            followingCount: viewModel.followingCount,
            onEditProfile: {
                showEditProfile = true
            },
            onFollowersTap: {
                showFollowersList = true
            },
            onFollowingTap: {
                showFollowingList = true
            },
            showEventsStat: false,
            showEditButton: true
        )
        .padding(.top, 8)
    }

    private var eventsSection: some View {
        eventsContent
    }

    // ✅ CHANGED: label becomes "View" when verified, button stays clickable when verified,
    // and it still opens your existing Express onboarding/dashboard link from Render.
    private var stripePayoutsCard: some View {
        let status = connectStatus?.status

        let statusText: String = {
            switch status {
            case "verified":
                return "Verified"
            case "in_review":
                return "In review"
            case "more_info_needed":
                return "More information needed"
            case "not_started":
                return "Complete your payout setup on Stripe using the same email you use for your Sioree account"
            default:
                return connectStatus?.isReady == true
                    ? "Verified"
                    : "Complete your payout setup on Stripe using the same email you use for your Sioree account."
            }
        }()

        let isVerified = (status == "verified" || connectStatus?.isReady == true)

        let buttonLabel: String = {
            if isVerified { return "View" }
            if status == "more_info_needed" { return "Provide info" }
            return "Set up"
        }()

        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Stripe payouts")
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                    Text(statusText)
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
                Spacer()
                Button(action: {
    if isVerified {
        if let url = URL(string: "https://connect.stripe.com/express_login") {
            openURL(url)
        } else {
            payoutErrorMessage = "Unable to open Stripe Express dashboard."
        }
    } else {
        startStripeOnboarding()
    }
}) {

                    Text(isStartingOnboarding ? "Starting..." : buttonLabel)
                        .font(.sioreeBodySmall)
                        .foregroundColor(.sioreeBlack)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.sioreeIcyBlue)
                        .cornerRadius(Theme.CornerRadius.large)
                }
                // Only disable while the request is actively starting
                .disabled(isStartingOnboarding)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.large)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, Theme.Spacing.s)
    }

    private var eventsContent: some View {
        Group {
            if viewModel.events.isEmpty {
                emptyEventsView
            } else {
                eventsGridView
            }
        }
    }

    private var emptyEventsView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
            VStack(spacing: Theme.Spacing.s) {
                Text("No events hosted yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Your hosted events and photos will appear here")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var eventsGridView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.m), count: 3)
        
        return LazyVGrid(columns: columns, spacing: Theme.Spacing.l) {
            ForEach(Array(viewModel.events.prefix(9)), id: \.id) { event in
                VStack(spacing: Theme.Spacing.xs) {
                    EventHighlightCircle(event: event)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                // Check if event has photos
                                let coverKey = "event_cover_\(event.id)"
                                let hasCover = UserDefaults.standard.string(forKey: coverKey) != nil
                                let hasEventImages = !event.images.isEmpty
                                
                                if !hasCover && !hasEventImages {
                                    // If no photos, go directly to add photos
                                    selectedEventForPost = event
                                } else {
                                    selectedEventForPhotos = event
                                }
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                selectedEventForPost = event
                            }) {
                                Label("Add Photos", systemImage: "photo.fill")
                            }
                        }
                    
                    // Event name below (like Instagram highlights)
                    Text(event.title)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.sioreeWhite)
                        .lineLimit(1)
                        .frame(maxWidth: 100)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.m)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                mainContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.sioreeBlack.opacity(0.8), for: .navigationBar)
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
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.sioreeWhite)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditView(user: currentUser)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showFollowersList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .followers, userType: .host)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .following, userType: .host)
                }
            }
            .fullScreenCover(item: $selectedEventForPhotos) { event in
                EventStoryViewer(event: event)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $selectedEventForPost) { event in
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
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
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
                loadStripeConnectStatus()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
                loadStripeConnectStatus()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    loadStripeConnectStatus()
                }
            }
        }
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

#Preview {
    HostProfileView()
        .environmentObject(AuthViewModel())
}
