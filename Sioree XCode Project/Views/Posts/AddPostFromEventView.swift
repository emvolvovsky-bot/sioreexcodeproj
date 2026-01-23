//
//  AddPhotosToEventView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct AddPostFromEventView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let event: Event?

    init(event: Event? = nil) {
        self.event = event
    }

    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var existingPhotoCount = 0
    private let photoService = PhotoService()
    private let networkService = NetworkService()
    
    private let maxEventHistoryPhotos = 7
    private var isHostEvent: Bool {
        event != nil && authViewModel.currentUser?.userType == .host
    }
    private var maxPhotosAllowed: Int {
        // For event history (partiers), limit to 7 total photos
        if event != nil && !isHostEvent {
            return max(1, maxEventHistoryPhotos - existingPhotoCount)
        }
        // For regular posts, use standard limit
        return Constants.Limits.maxPostImages
    }
    private var pickerSelectionLimit: Int {
        // 0 means unlimited in PHPickerConfiguration
        isHostEvent ? 0 : maxPhotosAllowed
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Clean gradient background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.l) {
                    // Header with event info
                    if let event = event {
                        VStack(alignment: .center, spacing: Theme.Spacing.xs) {
                            Text(event.title)
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                                .multilineTextAlignment(.center)
                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey.opacity(0.8))
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }

                    Spacer()

                    // Photo selection area
                    VStack(spacing: Theme.Spacing.l) {
                        if selectedImages.isEmpty {
                            // Empty state - show photo picker button
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.sioreeLightGrey.opacity(0.5))

                                Text("Add photos from this event")
                                    .font(.sioreeH3)
                                    .foregroundColor(.sioreeWhite)

                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    HStack(spacing: Theme.Spacing.s) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 20))
                                        Text("Select Photos")
                                            .font(.sioreeBody)
                                    }
                                    .foregroundColor(.sioreeIcyBlue)
                                    .padding(.horizontal, Theme.Spacing.l)
                                    .padding(.vertical, Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.large)
                                }
                            }
                        } else {
                            // Show selected photos
                            VStack(spacing: Theme.Spacing.m) {
                                Text("\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s") selected")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeLightGrey)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Spacing.s) {
                                        ForEach(selectedImages.indices, id: \.self) { index in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: selectedImages[index])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                                // Remove button
                                                Button(action: {
                                                    selectedImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.7))
                                                        .clipShape(Circle())
                                                        .font(.system(size: 20))
                                                }
                                                .padding(6)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }

                                // Upload button
                                Button(action: uploadPhotos) {
                                    HStack(spacing: Theme.Spacing.s) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 20))
                                        Text("Upload Photos")
                                            .font(.sioreeBody)
                                    }
                                    .foregroundColor(.sioreeWhite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue)
                                    .cornerRadius(Theme.CornerRadius.large)
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                                .disabled(isUploading)
                                .opacity(isUploading ? 0.6 : 1.0)

                                // Add more photos button
                                if isHostEvent || selectedImages.count < maxPhotosAllowed {
                                    Button(action: {
                                        showImagePicker = true
                                    }) {
                                        Text(isHostEvent ? "Add More Photos" : "Add More Photos (\(selectedImages.count)/\(maxPhotosAllowed))")
                                            .font(.sioreeBodySmall)
                                            .foregroundColor(.sioreeIcyBlue)
                                    }
                                    .padding(.top, Theme.Spacing.s)
                                } else {
                                    Text("Maximum \(maxPhotosAllowed) photos reached")
                                        .font(.sioreeBodySmall)
                                        .foregroundColor(.sioreeLightGrey)
                                        .padding(.top, Theme.Spacing.s)
                                }
                                
                                if isHostEvent && selectedImages.count > 0 {
                                    Text("\(selectedImages.count) photos selected")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey.opacity(0.7))
                                        .padding(.top, Theme.Spacing.xs)
                                }
                                
                                // Show warning if approaching event history limit
                                if let event = event, !isHostEvent, existingPhotoCount + selectedImages.count >= maxEventHistoryPhotos {
                                    Text("Note: Event history shows max \(maxEventHistoryPhotos) photos")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey.opacity(0.7))
                                        .padding(.top, Theme.Spacing.xs)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
            .navigationTitle("Add Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.sioreeIcyBlue)
                    }
                    .disabled(isUploading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                MultiplePhotoPicker(selectedImages: $selectedImages, limit: pickerSelectionLimit)
            }
            .onAppear {
                if let event = event {
                    loadExistingPhotoCount(for: event.id)
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        VStack(spacing: Theme.Spacing.m) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                                .scaleEffect(1.5)
                            Text("Uploading photos...")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func uploadPhotos() {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        errorMessage = ""

        // First upload the actual image files
        photoService.uploadImages(selectedImages)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    if case .failure(let error) = completion {
                        isUploading = false
                        errorMessage = "Failed to upload photos: \(error.localizedDescription)"
                        showError = true
                    }
                },
                receiveValue: { [self] uploadedUrls in
                    print("📤 Photos uploaded successfully: \(uploadedUrls)")

                    // Try to save to server first, fallback to local storage
                    savePhotosToServer(uploadedUrls)
                }
            )
            .store(in: &cancellables)
    }

    private func savePhotosToServer(_ uploadedUrls: [String]) {
        // If this is the first photo and event has no cover, set first photo as cover
        if let event = event, event.images.isEmpty, let firstPhotoUrl = uploadedUrls.first {
            setEventCoverImage(firstPhotoUrl, for: event.id)
        }
        
        networkService.createPost(
            caption: nil, // Simple photo upload - no caption
            mediaUrls: uploadedUrls,
            location: nil,
            eventId: event?.id
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [self] completion in
                switch completion {
                case .finished:
                    print("✅ Post created successfully on server")
                    // Server save succeeded
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PostCreated"),
                        object: nil,
                        userInfo: [
                            "userId": authViewModel.currentUser?.id ?? "",
                            "eventId": event?.id
                        ]
                    )
                    isUploading = false
                    dismiss()

                case .failure(let error):
                    print("❌ Server save failed: \(error.localizedDescription), saving locally")
                    // Server save failed, save locally instead
                    self.savePhotosLocally(uploadedUrls)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PostCreated"),
                        object: nil,
                        userInfo: [
                            "userId": authViewModel.currentUser?.id ?? "",
                            "eventId": event?.id,
                            "photoUrls": uploadedUrls
                        ]
                    )
                    isUploading = false
                    dismiss()
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }

    private func savePhotosLocally(_ photoUrls: [String]) {
        guard let eventId = event?.id, let userId = authViewModel.currentUser?.id else { return }
        
        // If this is the first photo and event has no cover, set first photo as cover
        if let event = event, event.images.isEmpty, let firstPhotoUrl = photoUrls.first {
            setEventCoverImage(firstPhotoUrl, for: eventId)
        }

        // Create a local photo record
        let photoRecord: [String: Any] = [
            "id": UUID().uuidString,
            "eventId": eventId,
            "userId": userId,
            "userName": authViewModel.currentUser?.name ?? "You",
            "userAvatar": authViewModel.currentUser?.avatar ?? "",
            "images": photoUrls,
            "caption": "",
            "uploadedAt": Date().timeIntervalSince1970
        ]

        // Save to local storage
        let storageKey = "event_photos_\(eventId)"
        var eventPhotos = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        eventPhotos.append(photoRecord)
        UserDefaults.standard.set(eventPhotos, forKey: storageKey)

        print("💾 Saved \(photoUrls.count) photos locally for event \(eventId)")
        print("💾 Storage key: \(storageKey)")
        print("💾 Total photos for event: \(eventPhotos.count)")
    }
    
    private func setEventCoverImage(_ imageUrl: String, for eventId: String) {
        // Store the cover image URL for this event
        let coverKey = "event_cover_\(eventId)"
        UserDefaults.standard.set(imageUrl, forKey: coverKey)
        print("📸 Set first photo as event cover: \(imageUrl)")
        
        // Also update the event in local cache if it exists
        // This will be picked up when events are loaded
        NotificationCenter.default.post(
            name: NSNotification.Name("EventCoverUpdated"),
            object: nil,
            userInfo: [
                "eventId": eventId,
                "coverImageUrl": imageUrl
            ]
        )
    }
    
    private func loadExistingPhotoCount(for eventId: String) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        // Try API first
        networkService.fetchPostsForEvent(eventId: eventId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // Fallback to local storage
                        self.loadExistingPhotoCountFromLocalStorage(for: eventId, userId: userId)
                    }
                },
                receiveValue: { posts in
                    // Count photos from user's posts for this event
                    let userPosts = posts.filter { $0.userId == userId }
                    self.existingPhotoCount = userPosts.reduce(0) { $0 + $1.images.count }
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadExistingPhotoCountFromLocalStorage(for eventId: String, userId: String) {
        let storageKey = "event_photos_\(eventId)"
        let storedPhotos = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        
        let userPhotos = storedPhotos.filter { photoData in
            (photoData["userId"] as? String) == userId
        }
        
        self.existingPhotoCount = userPhotos.reduce(0) { count, photoData in
            let images = photoData["images"] as? [String] ?? []
            return count + images.count
        }
    }
}

#Preview {
    AddPostFromEventView(event: Event(
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
        isFeatured: false,
        isRSVPed: false,
        qrCode: "test-qr",
        lookingForTalentType: nil
    ))
        .environmentObject(AuthViewModel())
}

