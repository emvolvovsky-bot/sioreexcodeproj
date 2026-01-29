//
//  EventStoryViewer.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct EventStoryViewer: View {
    let event: Event
    let viewUserId: String? // If provided, show photos by this user only; if nil, show current user's photos
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var currentPhotoIndex = 0
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var showAddPhotos = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var dragOffset: CGFloat = 0
    @State private var verticalDragOffset: CGFloat = 0
    @State private var showDeleteConfirmation = false
    @State private var photoToDelete: EventPhoto? = nil
    
    private let postCreatedNotification = NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))
    
    private var isHost: Bool {
        authViewModel.currentUser?.userType == .host
    }

    private var isPartier: Bool {
        authViewModel.currentUser?.userType == .partier
    }

    private var hostLabelTopPadding: CGFloat {
        canDeleteCurrentPhoto ? 58 : Theme.Spacing.m
    }
    
    private var maxPhotos: Int {
        // Hosts have no limit, partiers have limit of 7
        return isHost ? Int.max : 7
    }
    
    init(event: Event, viewUserId: String? = nil) {
        self.event = event
        self.viewUserId = viewUserId
    }
    
    private var isOwnProfile: Bool {
        guard let currentUserId = authViewModel.currentUser?.id else { return false }
        // If viewUserId is provided and different from current user, it's not own profile
        if let viewUserId = viewUserId {
            return currentUserId == viewUserId
        }
        return currentUserId == StorageService.shared.getUserId()
    }
    
    private var allImages: [EventPhoto] {
        // Use viewUserId if provided (viewing another person's profile), otherwise use current user's ID
        let userId = viewUserId ?? authViewModel.currentUser?.id
        let filtered = posts.filter { post in
            post.userId == userId
        }
        
        var images = filtered.flatMap { post in
            post.images.enumerated().map { (index, imageUrl) in
                EventPhoto(
                    url: imageUrl,
                    post: post,
                    imageIndex: index
                )
            }
        }
        
        // Check for stored cover image first (from first photo upload)
        let coverKey = "event_cover_\(event.id)"
        var coverImageUrl: String? = UserDefaults.standard.string(forKey: coverKey)
        
        // If no stored cover, use event's first image
        if coverImageUrl == nil {
            coverImageUrl = event.images.first
        }
        
        // If we have a cover image, ensure it's the first photo.
        if let coverImageUrl = coverImageUrl, !coverImageUrl.isEmpty {
            // If the cover is already present in user's photos, move it to front.
            if let coverIndex = images.firstIndex(where: { $0.url == coverImageUrl }) {
                let coverPhoto = images.remove(at: coverIndex)
                images.insert(coverPhoto, at: 0)
            } else {
                // Otherwise, insert a synthetic cover photo at the front so viewers always see it.
                let coverPhoto = EventPhoto(
                    url: coverImageUrl,
                    post: Post(
                        id: "cover_\(event.id)",
                        userId: event.hostId,
                        userName: event.hostName,
                        userAvatar: event.hostAvatar,
                        images: [coverImageUrl],
                        caption: nil,
                        eventId: event.id,
                        createdAt: event.createdAt
                    ),
                    imageIndex: 0
                )
                images.insert(coverPhoto, at: 0)
            }
        }

        // Enforce max photos for non-host viewers, but always keep the cover as the first photo.
        if isHost {
            return images
        } else {
            guard !images.isEmpty else { return images }
            let cover = images[0]
            let rest = Array(images.dropFirst())
            let restLimited = Array(rest.prefix(maxPhotos - 1))
            return [cover] + restLimited
        }
    }

    // Extract cover image URL (stored cover or event first image)
    private var coverImageUrl: String? {
        let coverKey = "event_cover_\(event.id)"
        if let stored = UserDefaults.standard.string(forKey: coverKey), !stored.isEmpty {
            return stored
        }
        return event.images.first
    }
    
    private var canDeleteCurrentPhoto: Bool {
        // Can only delete if viewing own profile
        guard isOwnProfile, currentPhotoIndex < allImages.count else { return false }
        let photo = allImages[currentPhotoIndex]
        // Don't allow deleting the cover image if it's not from user's own post
        // Cover images from events have post.id starting with "cover_"
        if photo.post.id.hasPrefix("cover_") {
            return false
        }
        // Only allow deleting photos that belong to the current user
        let userId = viewUserId ?? authViewModel.currentUser?.id
        return photo.post.userId == userId
    }
    
    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(Color.sioreeIcyBlue)
                    .scaleEffect(1.5)
            } else if allImages.isEmpty {
                emptyStateView
            } else {
                storyContentView
            }
        }
        .onAppear {
            loadPosts()
        }
        .onReceive(postCreatedNotification) { notification in
            let notificationEventId = notification.userInfo?["eventId"]
            var shouldRefresh = false
            if let stringEventId = notificationEventId as? String {
                shouldRefresh = stringEventId == event.id
            } else if let intEventId = notificationEventId as? Int {
                shouldRefresh = String(intEventId) == event.id
            }
            
            if shouldRefresh {
                loadPosts()
            }
        }
        .sheet(isPresented: $showAddPhotos) {
            AddPostFromEventView(event: event)
                .environmentObject(authViewModel)
        }
        .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                photoToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.l) {
            // Close button at top (left)
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.sioreeWhite)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.leading, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.m)

                Spacer()
            }
            
            Spacer()
            
            if let cover = coverImageUrl, let url = URL(string: cover) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.sioreeCharcoal)
                            .frame(height: 240)
                            .overlay(ProgressView().tint(Color.sioreeIcyBlue))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .clipped()
                    case .failure:
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.6))
                    @unknown default:
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.6))
                    }
                }
                .cornerRadius(12)
                .padding(.horizontal, Theme.Spacing.m)
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.6))
            }
            
            VStack(spacing: Theme.Spacing.s) {
                Text("No photos yet")
                    .font(.sioreeH2)
                    .foregroundColor(Color.sioreeWhite)
                
                Text(isOwnProfile && viewUserId == nil ? 
                     "Add photos to share memories from this event" :
                     "This user hasn't added photos to this event yet")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            if isOwnProfile && viewUserId == nil {
                Button(action: {
                    showAddPhotos = true
                }) {
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Photos")
                            .font(.sioreeBody)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.sioreeWhite)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.m)
                    .background(
                        LinearGradient(
                            colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Theme.CornerRadius.large)
                }
            } else {
                // Show dismiss button when viewing another person's empty profile
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.sioreeWhite)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.large)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.l)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Allow swipe down to dismiss
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    private var storyContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background photo layer
                if currentPhotoIndex < allImages.count {
                    let photo = allImages[currentPhotoIndex]
                    
                    AsyncImage(url: URL(string: photo.url)) { phase in
                        switch phase {
                        case .empty:
                            Color.sioreeCharcoal
                                .overlay(
                                    ProgressView()
                                        .tint(Color.sioreeIcyBlue)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .offset(x: dragOffset, y: verticalDragOffset)
                                .scaleEffect(verticalDragOffset != 0 ? 1 - abs(verticalDragOffset) / 1000.0 : 1.0)
                                .opacity(verticalDragOffset != 0 ? 1.0 - abs(verticalDragOffset) / 500.0 : 1.0)
                        case .failure:
                            Color.sioreeCharcoal
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                                )
                        @unknown default:
                            Color.sioreeCharcoal
                        }
                    }
                }
                
                // Progress bars - on top of photo but below buttons
                VStack {
                    progressBarsView
                        .padding(.top, 8)
                        .padding(.horizontal, Theme.Spacing.s)
                    
                    Spacer()
                }
                
                // Tap areas for navigation - behind buttons, only active in center area
                GeometryReader { geo in
                    // Top safe area - no taps
                    Color.clear
                        .frame(height: 100)
                    
                    // Middle area with left/right tap zones
                    HStack(spacing: 0) {
                        // Left tap area - go to previous
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geo.size.width * 0.5)
                            .onTapGesture {
                                goToPrevious()
                            }
                        
                        // Right tap area - go to next
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geo.size.width * 0.5)
                            .onTapGesture {
                                goToNext()
                            }
                    }
                    .frame(height: geo.size.height - 200) // Exclude top 100px and bottom 100px
                    .offset(y: 100)
                    
                    // Bottom safe area - no taps
                    Color.clear
                        .frame(height: 100)
                        .offset(y: geo.size.height - 100)
                }
                
                // Buttons layer - on top, blocks touches in their areas
                VStack {
                    // Top buttons
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.sioreeWhite)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.m)
                        
                        Spacer()
                        
                        // Delete button (only on own photos, not cover image)
                        if canDeleteCurrentPhoto {
                            Button(action: {
                                photoToDelete = allImages[currentPhotoIndex]
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.sioreeWhite)
                                    .frame(width: 44, height: 44)
                                    .background(Color.red.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, Theme.Spacing.m)
                            .padding(.top, Theme.Spacing.m)
                        }
                    }

                    Spacer()
                    
                    // Bottom + button (only on own profile, and only if viewUserId is nil or matches current user)
                    // Hosts have no limit, partiers have limit
                    HStack {
                        Spacer()
                        
                        if isOwnProfile && viewUserId == nil && (isHost || allImages.count < maxPhotos) {
                            Button(action: {
                                showAddPhotos = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.sioreeWhite)
                                    .frame(width: 56, height: 56)
                                    .background(Color.sioreeIcyBlue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .padding(.trailing, Theme.Spacing.l)
                            .padding(.bottom, Theme.Spacing.xl)
                        }
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if !event.hostName.isEmpty {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Hosted by")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .blendMode(.difference)
                        NavigationLink(destination: InboxProfileView(userId: event.hostId)) {
                            Text(event.hostName)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .underline()
                                .blendMode(.difference)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, hostLabelTopPadding)
                    .padding(.trailing, Theme.Spacing.m)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Prioritize vertical drag for dismiss gesture
                        if abs(value.translation.height) > abs(value.translation.width) {
                            // Vertical swipe - for dismissing
                            verticalDragOffset = value.translation.height
                        } else {
                            // Horizontal swipe - for photo navigation
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        // Check if it's a downward swipe (dismiss gesture)
                        if abs(value.translation.height) > abs(value.translation.width) && value.translation.height > 0 {
                            // Downward swipe - dismiss if significant
                            let threshold: CGFloat = 100
                            if value.translation.height > threshold {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    dismiss()
                                }
                            } else {
                                // Spring back if not enough
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    verticalDragOffset = 0
                                }
                            }
                        } else {
                            // Horizontal swipe - navigate photos
                            let threshold: CGFloat = 100
                            if value.translation.width > threshold {
                                goToPrevious()
                            } else if value.translation.width < -threshold {
                                goToNext()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                                verticalDragOffset = 0
                            }
                        }
                    }
            )
        }
    }
    
    private var progressBarsView: some View {
        HStack(spacing: 4) {
            ForEach(0..<allImages.count, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 3)
                        
                        // Progress bar
                        if index < currentPhotoIndex {
                            // Fully filled - past photos
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: geo.size.width, height: 3)
                        } else if index == currentPhotoIndex {
                            // Currently viewing - fully filled
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: geo.size.width, height: 3)
                        }
                        // Future photos remain empty
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, Theme.Spacing.s)
    }
    
    private func goToNext() {
        guard currentPhotoIndex < allImages.count - 1 else {
            // Reached end, go back to profile
            dismiss()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhotoIndex += 1
            dragOffset = 0
        }
    }
    
    private func goToPrevious() {
        guard currentPhotoIndex > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhotoIndex -= 1
            dragOffset = 0
        }
    }
    
    private func loadPosts() {
        isLoading = true
        
        // Try API first
        let networkService = NetworkService()
        networkService.fetchPostsForEvent(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure = completion {
                        self.loadPostsFromLocalStorage()
                    }
                },
                receiveValue: { posts in
                    self.posts = posts
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadPostsFromLocalStorage() {
        let storageKey = "event_photos_\(event.id)"
        let storedPhotos = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        
        let localPosts = storedPhotos.compactMap { photoData -> Post? in
            guard let id = photoData["id"] as? String,
                  let userId = photoData["userId"] as? String,
                  let userName = photoData["userName"] as? String,
                  let images = photoData["images"] as? [String],
                  let uploadedAtTimestamp = photoData["uploadedAt"] as? TimeInterval else {
                return nil
            }
            
            return Post(
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
        }
        
        self.posts = localPosts
        self.isLoading = false
    }
    
    private func deletePhoto(_ photo: EventPhoto) {
        let postId = photo.post.id
        let eventId = event.id
        let deletedIndex = currentPhotoIndex
        let imageUrl = photo.url
        
        let networkService = NetworkService()
        let deletePublisher: AnyPublisher<Bool, Error>
        if photo.post.images.count > 1 {
            deletePublisher = networkService.deletePostImage(postId: postId, imageUrl: imageUrl)
        } else {
            deletePublisher = networkService.deletePost(postId: postId)
        }
        
        // Delete from API
        deletePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Photo deleted successfully")
                        // Also remove from local storage
                        self.deletePhotoFromLocalStorage(postId: postId, eventId: eventId, imageUrl: imageUrl)
                        // Refresh posts after deletion
                        self.loadPostsWithIndexAdjustment(deletedIndex: deletedIndex)
                    case .failure(let error):
                        print("❌ Failed to delete photo from API: \(error.localizedDescription)")
                        // Still try deleting from local storage as fallback
                        self.deletePhotoFromLocalStorage(postId: postId, eventId: eventId, imageUrl: imageUrl)
                        // Refresh posts
                        self.loadPostsWithIndexAdjustment(deletedIndex: deletedIndex)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    private func loadPostsWithIndexAdjustment(deletedIndex: Int) {
        isLoading = true
        
        // Try API first
        let networkService = NetworkService()
        networkService.fetchPostsForEvent(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        self.loadPostsFromLocalStorage()
                    }
                    self.isLoading = false
                    // Adjust current index after loading
                    DispatchQueue.main.async {
                        self.adjustIndexAfterDeletion(deletedIndex: deletedIndex)
                    }
                },
                receiveValue: { posts in
                    self.posts = posts
                    self.isLoading = false
                    // Adjust current index after loading
                    DispatchQueue.main.async {
                        self.adjustIndexAfterDeletion(deletedIndex: deletedIndex)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func adjustIndexAfterDeletion(deletedIndex: Int) {
        let newImageCount = allImages.count
        
        // If we deleted the last photo, go to the previous one
        if deletedIndex >= newImageCount {
            currentPhotoIndex = max(0, newImageCount - 1)
        }
        // If we deleted a photo before the current one, adjust index
        // (current index stays the same as the next photo shifts up)
        // If all photos deleted, dismiss
        if newImageCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.dismiss()
            }
        }
    }
    
    private func deletePhotoFromLocalStorage(postId: String, eventId: String, imageUrl: String) {
        // Remove from local storage
        let storageKey = "event_photos_\(eventId)"
        var eventPhotos = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        eventPhotos = eventPhotos.compactMap { photoData in
            guard let id = photoData["id"] as? String else {
                return photoData
            }
            guard id == postId else {
                return photoData
            }
            var updated = photoData
            let images = (photoData["images"] as? [String] ?? []).filter { $0 != imageUrl }
            if images.isEmpty {
                return nil
            }
            updated["images"] = images
            return updated
        }
        UserDefaults.standard.set(eventPhotos, forKey: storageKey)
        print("🗑️ Deleted photo \(postId) from local storage")
    }
    
}

#Preview {
    EventStoryViewer(event: Event(
        id: "1",
        title: "Sample Event",
        description: "Desc",
        hostId: "h1",
        hostName: "Host",
        date: Date(),
        time: Date(),
        location: "NYC",
        images: [],
        ticketPrice: nil,
        capacity: 100,
        attendeeCount: 50,
        talentIds: [],
        lookingForRoles: [],
        lookingForNotes: nil,
        status: .published,
        likes: 10,
        isLiked: false,
        isSaved: false,
        isRSVPed: false
    ))
    .environmentObject(AuthViewModel())
}

