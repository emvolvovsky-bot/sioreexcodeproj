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
    private let photoService = PhotoService()
    private let networkService = NetworkService()

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
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Text("Add More Photos")
                                        .font(.sioreeBodySmall)
                                        .foregroundColor(.sioreeIcyBlue)
                                }
                                .padding(.top, Theme.Spacing.s)
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isUploading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                MultiplePhotoPicker(selectedImages: $selectedImages, limit: 10)
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

                    // Store photos locally with event association since posts API isn't deployed
                    self.savePhotosLocally(uploadedUrls)

                    // Notify listeners that photos were added
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
            )
                    .store(in: &cancellables)
    }

    private func savePhotosLocally(_ photoUrls: [String]) {
        guard let eventId = event?.id, let userId = authViewModel.currentUser?.id else { return }

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
        var eventPhotos = UserDefaults.standard.array(forKey: "event_photos_\(eventId)") as? [[String: Any]] ?? []
        eventPhotos.append(photoRecord)
        UserDefaults.standard.set(eventPhotos, forKey: "event_photos_\(eventId)")

        print("💾 Saved \(photoUrls.count) photos locally for event \(eventId)")
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

