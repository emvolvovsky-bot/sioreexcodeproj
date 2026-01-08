//
//  PartierProfileView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct PartierProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(useAttendedEvents: true)
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var selectedEventForPhotos: Event? = nil
    @State private var selectedEventForPost: Event?
    
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
                Text("No events attended yet")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Your attended events and photos will appear here")
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
                    UserListListView(userId: userId, listType: .followers, userType: .partier)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = currentUser?.id {
                    UserListListView(userId: userId, listType: .following, userType: .partier)
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
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadUserContent()
            }
        }
    }
}

struct EventCollageItem: View {
    let event: Event
    
    private var coverImageUrl: String? {
        // Check for stored cover image first (from first photo upload)
        let coverKey = "event_cover_\(event.id)"
        if let storedCover = UserDefaults.standard.string(forKey: coverKey), !storedCover.isEmpty {
            return storedCover
        }
        // Fallback to event's first image
        return event.images.first
    }
    
    private var availableImages: [String] {
        var images: [String] = []
        
        // Add cover image if available
        if let cover = coverImageUrl {
            images.append(cover)
        }
        
        // Add other event images (excluding the cover if it's already there)
        for image in event.images {
            if image != coverImageUrl && !images.contains(image) {
                images.append(image)
            }
        }
        
        // Limit to 4 photos for the collage
        return Array(images.prefix(4))
    }
    
    private var collageHeight: CGFloat {
        // Dynamic height based on number of photos
        switch availableImages.count {
        case 1:
            return 280
        case 2:
            return 240
        case 3, 4:
            return 300
        default:
            return 280
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let images = availableImages
                let imageCount = images.count
                
                if imageCount == 0 {
                    // No photos - subtle gradient placeholder
                    LinearGradient(
                        colors: [
                            Color.sioreeCharcoal.opacity(0.5),
                            Color.sioreeCharcoal.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width, height: collageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                } else if imageCount == 1 {
                    // Single photo - full width
                    if let url = URL(string: images[0]) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                                Color.sioreeCharcoal
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                    .frame(width: geometry.size.width, height: collageHeight)
                                    .clipped()
                        case .failure:
                                Color.sioreeCharcoal
                        @unknown default:
                                Color.sioreeCharcoal
                            }
                        }
                        .frame(width: geometry.size.width, height: collageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                    }
                } else if imageCount == 2 {
                    // Two photos - side by side with subtle overlap
                    HStack(spacing: 0) {
                        // Left photo
                        if let url = URL(string: images[0]) {
                            AsyncImage(url: url) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width * 0.52, height: collageHeight)
                                        .clipped()
                                } else {
                                    Color.sioreeCharcoal
                                }
                            }
                            .frame(width: geometry.size.width * 0.52, height: collageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                            .zIndex(1)
                        }
                        
                        // Right photo - slightly overlapping
                        if let url = URL(string: images[1]) {
                            AsyncImage(url: url) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width * 0.52, height: collageHeight)
                                        .clipped()
                                } else {
                                    Color.sioreeCharcoal
                                }
                            }
                            .frame(width: geometry.size.width * 0.52, height: collageHeight)
                            .offset(x: -geometry.size.width * 0.04)
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                            .zIndex(0)
                        }
                    }
                } else if imageCount == 3 {
                    // Three photos - one large, two smaller overlapping
                    HStack(spacing: 0) {
                        // Left large photo
                        if let url = URL(string: images[0]) {
                            AsyncImage(url: url) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width * 0.6, height: collageHeight)
                                        .clipped()
                                } else {
                                    Color.sioreeCharcoal
                                }
                            }
                            .frame(width: geometry.size.width * 0.6, height: collageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                            .zIndex(1)
                        }
                        
                        // Right stack of two photos
                        VStack(spacing: 0) {
                            // Top right photo
                            if let url = URL(string: images[1]) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.42, height: collageHeight * 0.52)
                                            .clipped()
                                    } else {
                                        Color.sioreeCharcoal
                                    }
                                }
                                .frame(width: geometry.size.width * 0.42, height: collageHeight * 0.52)
                                .offset(x: -geometry.size.width * 0.02)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                                .zIndex(2)
                            }
                            
                            // Bottom right photo
                            if let url = URL(string: images[2]) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.42, height: collageHeight * 0.52)
                                            .clipped()
                                    } else {
                                        Color.sioreeCharcoal
                                    }
                                }
                                .frame(width: geometry.size.width * 0.42, height: collageHeight * 0.52)
                                .offset(x: -geometry.size.width * 0.02, y: -collageHeight * 0.04)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                                .zIndex(0)
                            }
                        }
                    }
                } else if imageCount >= 4 {
                    // Four photos - grid with subtle overlaps
                    VStack(spacing: 0) {
                        // Top row - two photos
                        HStack(spacing: 0) {
                            if let url = URL(string: images[0]) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                            .clipped()
                                    } else {
                                        Color.sioreeCharcoal
                                    }
                                }
                                .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                                .zIndex(2)
                            }
                            
                            if let url = URL(string: images[1]) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                            .clipped()
                } else {
                                        Color.sioreeCharcoal
                                    }
                                }
                                .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                .offset(x: -geometry.size.width * 0.04)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                                .zIndex(1)
                            }
                        }
                        
                        // Bottom row - two photos
                        HStack(spacing: 0) {
                            if let url = URL(string: images[2]) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                            .clipped()
                                    } else {
                                        Color.sioreeCharcoal
                                    }
                                }
                                .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                .offset(y: -collageHeight * 0.04)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                                .zIndex(1)
                            }
                            
                            if let url = URL(string: images[3]) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                            .clipped()
                                    } else {
                                        Color.sioreeCharcoal
                                    }
                                }
                                .frame(width: geometry.size.width * 0.52, height: collageHeight * 0.52)
                                .offset(x: -geometry.size.width * 0.04, y: -collageHeight * 0.04)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                                .zIndex(0)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: collageHeight)
    }
}

// Safe array subscript extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// EventHighlightCircle - Instagram-style circular highlights for Partier profile
struct EventHighlightCircle: View {
    let event: Event
    private let circleSize: CGFloat = 100
    
    private var coverImageUrl: String? {
        // Check for stored cover image first (from first photo upload)
        let coverKey = "event_cover_\(event.id)"
        if let storedCover = UserDefaults.standard.string(forKey: coverKey), !storedCover.isEmpty {
            return storedCover
        }
        // Fallback to event's first image
        return event.images.first
    }
    
    var body: some View {
        ZStack {
            // Glowing icy blue border (outer glow)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.sioreeIcyBlue.opacity(0.4),
                            Color.sioreeIcyBlue.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: circleSize + 8, height: circleSize + 8)
                .blur(radius: 4)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.sioreeIcyBlue.opacity(0.8),
                                    Color.sioreeIcyBlue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: circleSize + 6, height: circleSize + 6)
                )
            
            // Inner circle with image
            if let imageUrl = coverImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.sioreeCharcoal)
                            .frame(width: circleSize, height: circleSize)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: circleSize, height: circleSize)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.sioreeBlack, lineWidth: 2)
                                    .frame(width: circleSize, height: circleSize)
                            )
                    case .failure:
                        Circle()
                            .fill(Color.sioreeCharcoal)
                            .frame(width: circleSize, height: circleSize)
                    @unknown default:
                        Circle()
                            .fill(Color.sioreeCharcoal)
                            .frame(width: circleSize, height: circleSize)
                    }
                }
            } else {
                // No image - subtle gradient placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.sioreeCharcoal.opacity(0.6),
                                Color.sioreeCharcoal.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
            }
        }
        .shadow(color: Color.sioreeIcyBlue.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// EventCardGridItem - for grid layouts (used in UserProfileView)
struct EventCardGridItem: View {
    let event: Event
    
    private var coverImageUrl: String? {
        // Check for stored cover image first (from first photo upload)
        let coverKey = "event_cover_\(event.id)"
        if let storedCover = UserDefaults.standard.string(forKey: coverKey), !storedCover.isEmpty {
            return storedCover
        }
        // Fallback to event's first image
        return event.images.first
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Event image/thumbnail
                if let imageUrl = coverImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.sioreeCharcoal)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.sioreeCharcoal)
                        @unknown default:
                            Rectangle()
                                .fill(Color.sioreeCharcoal)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.sioreeCharcoal)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

struct BadgeRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            Text(text)
                .font(.sioreeBody)
                .foregroundColor(Color.sioreeWhite)
            
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    PartierProfileView()
        .environmentObject(AuthViewModel())
}

