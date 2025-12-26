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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentPhotoIndex = 0
    @State private var showDeleteConfirmation = false
    @State private var postToDelete: String? = nil
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var error: String? = nil
    @State private var showAddPhotos = false

    init(event: Event) {
        print("🎬 EventPhotosViewer initialized for event: \(event.title) (ID: \(event.id))")
        self.event = event
    }

    private let postCreatedNotification = NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))

    private var isOwnProfile: Bool {
        authViewModel.currentUser?.id == StorageService.shared.getUserId()
    }

    private var isHost: Bool {
        authViewModel.currentUser?.userType == .host
    }

    private var emptyStateTitle: String {
        if isHost {
            return "No photos from this event yet"
        } else {
            return "You haven't added photos to this event yet"
        }
    }

    private var emptyStateSubtitle: String {
        if isHost {
            return "Photos from attendees will appear here"
        } else {
            return "Add photos to share your memories from this event!"
        }
    }

    private var filteredPosts: [Post] {
        let currentUserId = authViewModel.currentUser?.id
        let isHost = authViewModel.currentUser?.userType == .host

        if isHost {
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

                    // Add Photos button
                    if isOwnProfile {
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

                // Photo counter
                if allImages.count > 1 {
                    Text("\(currentPhotoIndex + 1) of \(allImages.count)")
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
                        VStack(spacing: Theme.Spacing.m) {
                            Spacer()
                            Image(systemName: "photo.stack")
                                .font(.system(size: 60))
                                .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                            Text(emptyStateTitle)
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            Text(emptyStateSubtitle)
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, Theme.Spacing.l)
                    } else {
                        TabView(selection: $currentPhotoIndex) {
                            ForEach(allImages.indices, id: \.self) { index in
                                let photo = allImages[index]
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
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                    .clipped()
                                            case .failure:
                                                Rectangle()
                                                    .fill(Color.sioreeCharcoal)
                                                    .overlay(
                                                        VStack(spacing: Theme.Spacing.s) {
                                                            Image(systemName: "photo")
                                                                .font(.system(size: 50))
                                                                .foregroundColor(Color.sioreeLightGrey)
                                                            Text("Failed to load")
                                                                .font(.sioreeCaption)
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
                                            // User info - show for hosts or when viewing others' photos
                                            if isHost || photo.post.userId != authViewModel.currentUser?.id {
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
                                        }
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .padding(.bottom, Theme.Spacing.m)
                                    }

                                    // Delete button for own posts only
                                    if photo.post.userId == authViewModel.currentUser?.id {
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    postToDelete = photo.post.id
                                                    showDeleteConfirmation = true
                                                }) {
                                                    Image(systemName: "trash")
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.white)
                                                        .padding(12)
                                                        .background(Color.red.opacity(0.8))
                                                        .clipShape(Circle())
                                                        .shadow(radius: 4)
                                                }
                                                .padding(.top, 120)
                                                .padding(.trailing, Theme.Spacing.m)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page)
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                        .gesture(
                            DragGesture()
                                .onEnded { gesture in
                                    // Smooth swipe detection
                                    let width = gesture.translation.width
                                    let height = abs(gesture.translation.height)

                                    if abs(width) > height && abs(width) > 50 {
                                        if width > 0 && currentPhotoIndex > 0 {
                                            currentPhotoIndex -= 1
                                        } else if width < 0 && currentPhotoIndex < allImages.count - 1 {
                                            currentPhotoIndex += 1
                                        }
                                    }
                                }
                        )
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
            .sheet(isPresented: $showAddPhotos) {
                AddPostFromEventView(event: event)
                    .environmentObject(authViewModel)
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

struct EventsAttendedView: View {
    @StateObject private var viewModel = ProfileViewModel(userId: nil, useAttendedEvents: true)
    @State private var selectedEvent: Event? = nil
    @State private var showPhotoViewer = false

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
                            Text("Event History")
                                .font(.sioreeH2)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.top, Theme.Spacing.m)

                            if viewModel.events.isEmpty {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                                    Text("No events attended yet")
                                        .font(.sioreeH3)
                                        .foregroundColor(Color.sioreeWhite)
                                    Text("Your attended events and photos will appear here")
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xxl)
                            } else {
                                // ZStack of events attended
                                ZStack {
                                    ForEach(Array(viewModel.events.enumerated()), id: \.element.id) { index, event in
                                        EventCardZStack(
                                            event: event,
                                            index: index,
                                            total: viewModel.events.count
                                        )
                                        .onTapGesture {
                                            selectedEvent = event
                                            showPhotoViewer = true
                                        }
                                    }
                                }
                                .frame(height: 450)
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Event History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPhotoViewer) {
                if let event = selectedEvent {
                    EventPhotosViewer(event: event)
                }
            }
            .onAppear {
                viewModel.loadProfile()
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
