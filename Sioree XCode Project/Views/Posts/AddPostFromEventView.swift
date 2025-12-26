//
//  AddPostFromEventView.swift
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
    @State private var caption: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    private let photoService = PhotoService()
    private let networkService = NetworkService()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Event context
                        if let event {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Event")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                                Text(event.title)
                                    .font(.sioreeH4)
                                    .foregroundColor(.sioreeWhite)
                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.sioreeBodySmall)
                                    .foregroundColor(.sioreeLightGrey)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                        
                        // Images Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Add Photos")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.sioreeIcyBlue)
                                    Text("Select Photos")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    Spacer()
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                            
                            // Display selected images
                            if !selectedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Spacing.s) {
                                        ForEach(selectedImages.indices, id: \.self) { index in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: selectedImages[index])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                Button(action: {
                                                    selectedImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.5))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Caption Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Caption")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            TextEditor(text: $caption)
                                .frame(height: 120)
                                .padding(Theme.Spacing.s)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .foregroundColor(.sioreeWhite)
                            
                            // Mention tip removed per request
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Create Post Button
                        Button(action: {
                            createPost()
                        }) {
                            Text("Create Post")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .disabled(isCreating)
                        .opacity(isCreating ? 0.6 : 1.0)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle(event != nil ? "Event Photos" : "Add Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                MultiplePhotoPicker(selectedImages: $selectedImages, limit: 10)
            }
            .overlay {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createPost() {
        isCreating = true
        errorMessage = ""
        
        func finishCreate(with mediaUrls: [String]) {
            networkService.createPost(
                caption: caption.isEmpty ? nil : caption,
                mediaUrls: mediaUrls,
                location: nil,
                eventId: event?.id
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isCreating = false
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to create post: \(error.localizedDescription)"
                        showError = true
                    }
                },
                receiveValue: { [self] _ in
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PostCreated"),
                        object: nil,
                        userInfo: ["userId": authViewModel.currentUser?.id ?? ""]
                    )
                    dismiss()
                }
            )
            .store(in: &cancellables)
        }
        
        // Upload images if any, then create post
        if selectedImages.isEmpty {
            finishCreate(with: [])
        } else {
            photoService.uploadImages(selectedImages)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [self] completion in
                        if case .failure(let error) = completion {
                            isCreating = false
                            errorMessage = "Failed to upload photos: \(error.localizedDescription)"
                            showError = true
                        }
                    },
                    receiveValue: { urls in
                        finishCreate(with: urls)
                    }
                )
                .store(in: &cancellables)
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
        isFeatured: false
    ))
        .environmentObject(AuthViewModel())
}

