//
//  EventsAttendedView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct EventPhoto {
    let url: String
    let post: Post
    let imageIndex: Int
}

struct EventPhotosViewer: View {
    let event: Event
    let viewUserId: String? // If provided, show photos by this user only; if nil, show current user's photos
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentPhotoIndex = 0
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var error: String? = nil
    @State private var showAddPhotos = false
    @State private var showFullScreenViewer = false
    @State private var showDeleteConfirmation = false
    @State private var postToDelete: String? = nil

    init(event: Event, viewUserId: String? = nil) {
        print("🎬 EventPhotosViewer initialized for event: \(event.title) (ID: \(event.id)), viewUserId: \(viewUserId ?? "nil")")
        self.event = event
        self.viewUserId = viewUserId
    }

    private let postCreatedNotification = NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))

    private var isOwnProfile: Bool {
        authViewModel.currentUser?.id == StorageService.shared.getUserId()
    }

    private var isHost: Bool {
        authViewModel.currentUser?.userType == .host
    }

    private var emptyStateTitle: String {
        if viewUserId != nil {
            return "No photos from this event yet"
        } else if isHost {
            return "No photos from this event yet"
        } else {
            return "You haven't added photos to this event yet"
        }
    }

    private var emptyStateSubtitle: String {
        if viewUserId != nil {
            return "Photos will appear here when available"
        } else if isHost {
            return "Photos from attendees will appear here"
        } else {
            return "Add your photos to share memories from this event"
        }
    }

    private var filteredPosts: [Post] {
        let currentUserId = authViewModel.currentUser?.id
        let isHost = authViewModel.currentUser?.userType == .host

        if let viewUserId = viewUserId {
            // When viewing another user's profile, show only their posts
            return posts.filter { post in
                post.userId == viewUserId
            }
        } else if isHost {
            // Hosts see all posts for events they hosted
            return posts
        } else {
            // Partiers only see their own posts
            return posts.filter { post in
                post.userId == currentUserId
            }
        }
    }

    private var allImages: [EventPhoto] {
        filteredPosts.flatMap { post in
            post.images.enumerated().map { (index, imageUrl) in
                EventPhoto(
                    url: imageUrl,
                    post: post,
                    imageIndex: index
                )
            }
        }
    }

    var body: some View {
        ZStack {
            Color.sioreeBlack.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header with event info and add photos button
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(event.title)
                        .font(.sioreeH3)
                        .foregroundColor(Color.sioreeWhite)
                            .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.8))
                    }

                    Spacer()

                    // Add Photos button - only show when viewing own profile
                    if isOwnProfile && viewUserId == nil {
                        Button(action: {
                            showAddPhotos = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                Text(isHost ? "Add Photos" : "Add Photos")
                                    .font(.sioreeBodySmall)
                            }
                            .foregroundColor(Color.sioreeIcyBlue)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.s)
                            .background(Color.sioreeIcyBlue.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                    }

                }
                .padding(.vertical, Theme.Spacing.s)
                .padding(.horizontal, Theme.Spacing.m)

                // Photo count
                if !allImages.isEmpty {
                    Text("\(allImages.count) photo\(allImages.count == 1 ? "" : "s")")
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                        .padding(.vertical, Theme.Spacing.xs)
                }

                // Photo carousel
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(Color.sioreeIcyBlue)
                            .scaleEffect(1.5)
                    } else if allImages.isEmpty {
                        VStack(spacing: Theme.Spacing.l) {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.6))
                            VStack(spacing: Theme.Spacing.s) {
                                Text(emptyStateTitle)
                                    .font(.sioreeH2)
                                    .foregroundColor(Color.sioreeWhite)
                                Text(emptyStateSubtitle)
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, Theme.Spacing.l)
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: Theme.Spacing.s),
                                    GridItem(.flexible(), spacing: Theme.Spacing.s),
                                    GridItem(.flexible(), spacing: Theme.Spacing.s)
                                ],
                                spacing: Theme.Spacing.s
                            ) {
                                ForEach(allImages.indices, id: \.self) { index in
                                    let photo = allImages[index]
                                    ZStack(alignment: .topTrailing) {
                                        Button(action: {
                                            currentPhotoIndex = index
                                            showFullScreenViewer = true
                                        }) {
                                            ZStack(alignment: .bottomLeading) {
                                                if let url = URL(string: photo.url) {
                                                    AsyncImage(url: url) { phase in
                                                        switch phase {
                                                        case .empty:
                                                            Rectangle()
                                                                .fill(Color.sioreeCharcoal)
                                                                .overlay(
                                                                    ProgressView()
                                                                        .tint(Color.sioreeIcyBlue)
                                                                        .scaleEffect(1.5)
                                                                )
                                                        case .success(let image):
                                                            image
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(height: 120)
                                                                .clipped()
                                                        case .failure:
                                                            Rectangle()
                                                                .fill(Color.sioreeCharcoal)
                                                                .overlay(
                                                                    VStack(spacing: Theme.Spacing.xs) {
                                                                        Image(systemName: "photo")
                                                                            .font(.system(size: 30))
                                                                            .foregroundColor(Color.sioreeLightGrey)
                                                                        Text("Failed to load")
                                                                            .font(.sioreeCaptionSmall)
                                                                            .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                                                    }
                                                                )
                                                        @unknown default:
                                                            Rectangle()
                                                                .fill(Color.sioreeCharcoal)
                                                        }
                                                    }
                                                }

                                                // Simple overlay with photo number
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Spacer()
                                                    HStack {
                                                        Spacer()
                                                        Text("\(index + 1)")
                                                            .font(.sioreeCaptionSmall)
                                                            .foregroundColor(Color.sioreeWhite)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.black.opacity(0.6))
                                                            .cornerRadius(Theme.CornerRadius.small)
                                                            .padding(Theme.Spacing.xs)
                                                    }
                                                }
                                            }
                                            .frame(height: 120)
                                            .cornerRadius(Theme.CornerRadius.medium)
                                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        }

                                        // Delete button for user's own photos
                                        if photo.post.userId == authViewModel.currentUser?.id {
                                            Button(action: {
                                                postToDelete = photo.post.id
                                                showDeleteConfirmation = true
                                            }) {
                                                Image(systemName: "trash.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(Color.red.opacity(0.9))
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                                    .padding(Theme.Spacing.xs)
                                            }
                                            .padding(Theme.Spacing.xs)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.s)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.sioreeWhite)
                }
            }
        }
        .onReceive(postCreatedNotification) { notification in
            print("📡 Received PostCreated notification: \(notification.userInfo ?? [:])")
            let notificationEventId = notification.userInfo?["eventId"]

            // Handle both String and Int event IDs
            var shouldRefresh = false
            if let stringEventId = notificationEventId as? String {
                shouldRefresh = stringEventId == event.id
                print("📡 String eventId comparison: \(stringEventId) == \(event.id) -> \(shouldRefresh)")
            } else if let intEventId = notificationEventId as? Int {
                shouldRefresh = String(intEventId) == event.id
                print("📡 Int eventId comparison: \(intEventId) == \(event.id) -> \(shouldRefresh)")
            }

            if shouldRefresh {
                print("📡 Refreshing photos for event \(event.id)")
                loadPosts()
            } else {
                print("📡 Not refreshing - event IDs don't match")
            }
        }
        .onAppear {
            print("🎬 EventPhotosViewer appeared, loading posts...")
            loadPosts()
        }
            .sheet(isPresented: $showAddPhotos) {
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showFullScreenViewer) {
                FullScreenPhotoViewer(
                    photos: allImages,
                    currentIndex: $currentPhotoIndex
                )
            }
            .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let postToDelete = postToDelete {
                        deletePost(postToDelete)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this photo? This action cannot be undone.")
            }
    }

    private func deletePhoto(_ photoUrl: String) {
        // Find the post that contains this photo and delete it from local storage
        if let photoIndex = allImages.firstIndex(where: { $0.url == photoUrl }) {
            let post = allImages[photoIndex].post

            // Remove from local storage
            var storedPhotos = UserDefaults.standard.array(forKey: "event_photos_\(event.id)") as? [[String: Any]] ?? []
            storedPhotos.removeAll { photoData in
                (photoData["id"] as? String) == post.id
            }
            UserDefaults.standard.set(storedPhotos, forKey: "event_photos_\(event.id)")

            // Refresh posts after deletion
            loadPosts()
        }
    }

    @State private var cancellables = Set<AnyCancellable>()

    private func loadPosts() {
        print("🔄 loadPosts called for event \(event.id)")
        isLoading = true
        error = nil

        // Try API first
        let networkService = NetworkService()
        networkService.fetchPostsForEvent(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    print("🔄 API call completed for event \(self.event.id)")
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("🔄 API failed: \(error.localizedDescription), loading from local storage")
                        // API failed, load from local storage instead
                        self.loadPostsFromLocalStorage()
                    } else {
                        print("🔄 API succeeded")
                    }
                },
                receiveValue: { posts in
                    print("🔄 API returned \(posts.count) posts")
                    self.posts = posts
                }
            )
            .store(in: &cancellables)
    }

    private func loadPostsFromLocalStorage() {
        // Load photos from local storage (works immediately while backend deploys)
        let storageKey = "event_photos_\(event.id)"
        print("📱 Loading photos from storage key: \(storageKey)")

        let storedPhotos = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []

        print("📱 Found \(storedPhotos.count) raw photo records in storage")

        let localPosts = storedPhotos.compactMap { photoData -> Post? in
            print("📱 Processing photo record: \(photoData)")

            guard let id = photoData["id"] as? String,
                  let userId = photoData["userId"] as? String,
                  let userName = photoData["userName"] as? String,
                  let images = photoData["images"] as? [String],
                  let uploadedAtTimestamp = photoData["uploadedAt"] as? TimeInterval else {
                print("📱 Failed to parse photo data: missing required fields")
                return nil
            }

            let post = Post(
                id: id,
                userId: userId,
                userName: userName,
                userAvatar: photoData["userAvatar"] as? String,
                images: images,
                caption: photoData["caption"] as? String,
                likes: 0,
                comments: 0,
                isLiked: false,
                isSaved: false,
                location: nil,
                eventId: photoData["eventId"] as? String,
                createdAt: Date(timeIntervalSince1970: uploadedAtTimestamp)
            )

            print("📱 Created post with \(images.count) images")
            return post
        }

        self.posts = localPosts
        print("📱 Final result: \(localPosts.count) posts loaded for event \(event.id)")
    }

    private func deletePost(_ postId: String) {
        print("🗑️ Deleting post: \(postId)")

        let networkService = NetworkService()
        networkService.deletePost(postId: postId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Post deleted successfully")
                        // Refresh posts after deletion
                        self.loadPosts()
                    case .failure(let error):
                        print("❌ Failed to delete post: \(error.localizedDescription)")
                        // Could show error alert here if needed
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

struct EventCardZStack: View {
    let event: Event
    let index: Int
    let total: Int

    var body: some View {
        ZStack {
            // Event card with offset based on index
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                ZStack(alignment: .topTrailing) {
                    if let firstImage = event.images.first {
                        AsyncImage(url: URL(string: firstImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                LinearGradient(
                                    colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: "party.popper.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.6))
                            }
                        }
                        .frame(height: 200)
                        .clipped()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.sioreeIcyBlue.opacity(0.6))
                        }
                        .frame(height: 200)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(event.title)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                        .lineLimit(2)

                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                            .font(.system(size: 16))
                        Text(event.hostName)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                    }

                    HStack(spacing: Theme.Spacing.m) {
                        Label(event.date.formattedEventDate(), systemImage: "calendar")
                        Label(event.time.formattedEventTime(), systemImage: "clock")
                    }
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))

                    if let price = event.ticketPrice {
                        Text(Helpers.formatCurrency(price))
                            .font(.sioreeBody)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
                .padding(Theme.Spacing.m)
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.sioreeCharcoal.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(
                        LinearGradient(
                            colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(Theme.CornerRadius.medium)
            .offset(x: CGFloat(index) * 8, y: CGFloat(index) * 8) // Stack offset
            .zIndex(Double(total - index)) // Ensure proper stacking order
        }
    }
}

struct EventsAttendedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(userId: nil, useAttendedEvents: false)
    @State private var selectedEvent: Event? = nil
    @State private var showPhotoViewer = false
    @State private var showQRScanner = false
    @State private var selectedEventId: String?
    @State private var eventToDelete: String?
    @State private var showDeleteConfirmation = false
    @State private var selectedEventForPhotos: Event? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            Text("My Events")
                                .font(.sioreeH2)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.top, Theme.Spacing.m)

                            // Tab Picker for Events (same as HostProfileView)
                            Picker("Event Type", selection: $viewModel.selectedHostTab) {
                                ForEach(ProfileViewModel.HostProfileTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.top, Theme.Spacing.m)

                            // Events Section (same as HostProfileView)
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text(viewModel.selectedHostTab.rawValue)
                                    .font(.sioreeH3)
                                    .foregroundColor(.sioreeWhite)
                                    .padding(.horizontal, Theme.Spacing.m)

                                if viewModel.filteredEvents.isEmpty {
                                    Text(viewModel.selectedHostTab == .hosted ?
                                         "No past events yet. Host your first event!" :
                                         "No upcoming events. Create your next event!")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeLightGrey)
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .padding(.bottom, Theme.Spacing.m)
                                } else {
                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible(), spacing: Theme.Spacing.m),
                                            GridItem(.flexible(), spacing: Theme.Spacing.m)
                                        ],
                                        spacing: Theme.Spacing.m
                                    ) {
                                        ForEach(viewModel.filteredEvents) { event in
                                            HostEventCardGrid(event: event) {
                                                selectedEventForPhotos = event
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                    .padding(.bottom, Theme.Spacing.m)
                                }
                            }
                            .padding(.top, Theme.Spacing.m)
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("My Events")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPhotoViewer) {
                if let event = selectedEvent {
                    EventPhotosViewer(event: event)
                }
            }
            .sheet(isPresented: $showQRScanner) {
                if let eventId = selectedEventId {
                    QRCodeScannerView(eventId: eventId)
                }
            }
            .alert("Delete Event", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let eventId = eventToDelete {
                        deleteEvent(eventId)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
            .sheet(item: $selectedEventForPhotos) { event in
                EventPhotosViewer(event: event)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadProfile()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadProfile()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EventCreated"))) { notification in
                // Refresh events when a new event is created
                viewModel.loadProfile()
            }
        }
    }

    private func deleteEvent(_ eventId: String) {
        print("🗑️ Deleting event: \(eventId)")

        let networkService = NetworkService()
        networkService.deleteEvent(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Event deleted successfully")
                        // Refresh events after deletion
                        viewModel.loadProfile()
                    case .failure(let error):
                        print("❌ Failed to delete event: \(error.localizedDescription)")
                        // Could show error alert here if needed
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}


struct FullScreenPhotoViewer: View {
    let photos: [EventPhoto]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.sioreeBlack.edgesIgnoringSafeArea(.all)

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    let photo = photos[index]
                    ZStack(alignment: .bottomLeading) {
                        if let url = URL(string: photo.url) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.sioreeCharcoal)
                                        .overlay(
                                            ProgressView()
                                                .tint(Color.sioreeIcyBlue)
                                                .scaleEffect(2)
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                case .failure:
                                    Rectangle()
                                        .fill(Color.sioreeCharcoal)
                                        .overlay(
                                            VStack(spacing: Theme.Spacing.m) {
                                                Image(systemName: "photo")
                                                    .font(.system(size: 60))
                                                    .foregroundColor(Color.sioreeLightGrey)
                                                Text("Failed to load")
                                                    .font(.sioreeH4)
                                                    .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                            }
                                        )
                                @unknown default:
                                    Rectangle()
                                        .fill(Color.sioreeCharcoal)
                                }
                            }
                        }

                        // Photo info overlay
                        VStack(alignment: .leading, spacing: 4) {
                            Spacer()
                            if let caption = photo.post.caption, !caption.isEmpty {
                                Text(caption)
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeWhite)
                                    .lineLimit(3)
                                    .shadow(color: Color.black.opacity(0.8), radius: 4)
                                    .padding(.horizontal, Theme.Spacing.m)
                                    .padding(.bottom, 8)
                            }

                            HStack(spacing: 8) {
                                Text("\(index + 1) of \(photos.count)")
                                    .font(.sioreeCaption)
                                    .foregroundColor(Color.sioreeWhite.opacity(0.8))
                                    .padding(.horizontal, Theme.Spacing.s)
                                    .padding(.vertical, Theme.Spacing.xs)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(Theme.CornerRadius.medium)

                                Spacer()

                                // User info
                                HStack(spacing: 6) {
                                    if let avatarUrl = photo.post.userAvatar, let url = URL(string: avatarUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 24, height: 24)
                                                    .clipShape(Circle())
                                            default:
                                                Circle()
                                                    .fill(Color.sioreeLightGrey.opacity(0.3))
                                                    .frame(width: 24, height: 24)
                                            }
                                        }
                                    } else {
                                        Circle()
                                            .fill(Color.sioreeLightGrey.opacity(0.3))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.sioreeLightGrey)
                                            )
                                    }

                                    Text(photo.post.userName)
                                        .font(.sioreeCaption)
                                        .foregroundColor(Color.sioreeWhite)
                                }
                                .shadow(color: Color.black.opacity(0.8), radius: 4)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.bottom, Theme.Spacing.m)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .overlay(
                // Tap areas for immediate navigation
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Left tap area (previous photo)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if currentIndex > 0 {
                                    var transaction = Transaction(animation: nil)
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        currentIndex -= 1
                                    }
                                }
                            }
                            .frame(width: geometry.size.width / 2)
                        
                        // Right tap area (next photo)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if currentIndex < photos.count - 1 {
                                    var transaction = Transaction(animation: nil)
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        currentIndex += 1
                                    }
                                }
                            }
                            .frame(width: geometry.size.width / 2)
                    }
                }
            )

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.sioreeWhite.opacity(0.8))
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(.top, Theme.Spacing.m)
                            .padding(.trailing, Theme.Spacing.m)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    EventsAttendedView()
        .environmentObject(AuthViewModel())
}

#Preview("Photo Viewer") {
    EventPhotosViewer(event: Event(
        id: "1",
        title: "Summer Music Festival",
        description: "An amazing music festival",
        hostId: "host1",
        hostName: "Test Host",
        date: Date(),
        time: Date(),
        location: "Central Park, NYC",
        images: ["https://picsum.photos/800/600"],
        ticketPrice: nil,
        capacity: 1000,
        attendeeCount: 500,
        talentIds: [],
        lookingForRoles: [],
        lookingForNotes: nil,
        status: .published,
        likes: 100,
        isLiked: false,
        isSaved: false,
        isFeatured: true,
        isRSVPed: true,
        qrCode: "test-qr",
        lookingForTalentType: nil
    ))
    .environmentObject(AuthViewModel())
}
