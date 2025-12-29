//
//  AddTalentClipsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct AddTalentClipsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let event: Event?

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

                    // Image grid or empty state
                    if selectedImages.isEmpty {
                        emptyStateView
                    } else {
                        imageGridView
                    }

                    Spacer()

                    // Upload button
                    if !selectedImages.isEmpty {
                        Button(action: uploadClips) {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeBlack))
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 20))
                                }
                                Text(isUploading ? "Uploading..." : "Upload Clips")
                                    .font(.sioreeBody)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.m)
                            .background(Color.sioreeIcyBlue)
                            .foregroundColor(.sioreeBlack)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .disabled(isUploading)
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                }
                .padding(.top, Theme.Spacing.xl)
            }
            .navigationTitle("Add Clips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                MultiplePhotoPicker(selectedImages: $selectedImages, limit: 10)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))

            VStack(spacing: Theme.Spacing.s) {
                Text("Add clips from this event")
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)

                Text("Share your performance highlights and behind-the-scenes moments")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button(action: { showImagePicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Clips")
                        .font(.sioreeBody)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
                .background(Color.sioreeIcyBlue)
                .foregroundColor(.sioreeBlack)
                .cornerRadius(Theme.CornerRadius.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var imageGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.s),
                GridItem(.flexible(), spacing: Theme.Spacing.s),
                GridItem(.flexible(), spacing: Theme.Spacing.s)
            ], spacing: Theme.Spacing.s) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .cornerRadius(Theme.CornerRadius.small)
                            .clipped()

                        // Remove button
                        Button(action: {
                            selectedImages.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.sioreeWhite)
                                .background(Color.sioreeBlack.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(4)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
        }
    }

    private func uploadClips() {
        guard let event = event, let userId = authViewModel.currentUser?.id else {
            showError(message: "Missing event or user information")
            return
        }

        isUploading = true

        // Upload images to talent clips for this event
        let uploadPublisher = networkService.uploadTalentClips(
            eventId: event.id,
            images: selectedImages
        )

        uploadPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isUploading = false
                    switch completion {
                    case .finished:
                        // Success - dismiss and notify
                        NotificationCenter.default.post(name: NSNotification.Name("TalentClipsAdded"), object: nil)
                        self.dismiss()
                    case .failure(let error):
                        self.showError(message: "Failed to upload clips: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    // Handle success if needed
                }
            )
            .store(in: &cancellables)
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
