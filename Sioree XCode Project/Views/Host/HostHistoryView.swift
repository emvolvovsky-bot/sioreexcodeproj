//
//  HostHistoryView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import PhotosUI

struct HostHistoryView: View {
    let hostId: String
    let hostName: String
    @State private var selectedPhoto: PhotoItem?
    @State private var showAddPhotos = false
    
    // Store photos from camera roll
    @State private var photos: [PhotoItem] = []
    
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
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        if photos.isEmpty {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                
                                Text("No photos yet")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                                
                                Text("Add photos from your camera roll")
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeLightGrey)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.xl)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: Theme.Spacing.s),
                                GridItem(.flexible(), spacing: Theme.Spacing.s)
                            ], spacing: Theme.Spacing.s) {
                                ForEach(photos) { photo in
                                    PhotoThumbnail(photo: photo) {
                                        selectedPhoto = photo
                                    }
                                }
                            }
                            .padding(Theme.Spacing.s)
                        }
                        
                        // Add Photos Button
                        Button(action: {
                            showAddPhotos = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add Photos")
                                    .font(.sioreeBody)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Color.sioreeWhite)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeIcyBlue)
                            .cornerRadius(Theme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("\(hostName)'s History")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo, photos: photos, currentIndex: photos.firstIndex(where: { $0.id == photo.id }) ?? 0)
            }
            .sheet(isPresented: $showAddPhotos) {
                AddPhotosView(hostId: hostId, onPhotosAdded: { images in
                    // Add new photos to the photos array
                    let newPhotos = images.enumerated().map { index, image in
                        PhotoItem(
                            id: UUID().uuidString,
                            imageName: "",
                            image: image,
                            eventName: "Camera Roll",
                            date: Date(),
                            caption: ""
                        )
                    }
                    photos.append(contentsOf: newPhotos)
                })
            }
        }
    }
}

struct AddPhotosView: View {
    let hostId: String
    let onPhotosAdded: ([UIImage]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedImages: [UIImage] = []
    @State private var showPhotoPicker = false
    
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
                
                VStack(spacing: Theme.Spacing.l) {
                    if selectedImages.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                            
                            Text("Select photos from camera roll")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            
                            Button(action: {
                                showPhotoPicker = true
                            }) {
                                Text("Choose Photos")
                                    .font(.sioreeBody)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.sioreeWhite)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue)
                                    .cornerRadius(Theme.CornerRadius.medium)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: Theme.Spacing.s),
                                GridItem(.flexible(), spacing: Theme.Spacing.s),
                                GridItem(.flexible(), spacing: Theme.Spacing.s)
                            ], spacing: Theme.Spacing.s) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .clipped()
                                        .cornerRadius(Theme.CornerRadius.small)
                                }
                            }
                            .padding(Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Add Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // Add photos to history
                        addPhotosToHistory()
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                    .disabled(selectedImages.isEmpty)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                MultiplePhotoPicker(selectedImages: $selectedImages, limit: 20)
            }
        }
    }
    
    private func addPhotosToHistory() {
        onPhotosAdded(selectedImages)
    }
}

struct PhotoItem: Identifiable {
    let id: String
    let imageName: String
    let image: UIImage?
    let eventName: String
    let date: Date
    let caption: String
    
    init(id: String, imageName: String = "", image: UIImage? = nil, eventName: String, date: Date, caption: String) {
        self.id = id
        self.imageName = imageName
        self.image = image
        self.eventName = eventName
        self.date = date
        self.caption = caption
    }
}

struct PhotoThumbnail: View {
    let photo: PhotoItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Photo or Placeholder
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(Theme.CornerRadius.medium)
                } else {
                    ZStack {
                        Color.sioreeLightGrey.opacity(0.3)
                        
                        Image(systemName: "photo.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                    }
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                // Event name overlay
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(photo.eventName)
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeWhite)
                        .lineLimit(1)
                    
                    Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey)
                }
                .padding(Theme.Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.sioreeBlack.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(Theme.CornerRadius.medium)
            }
        }
    }
}

struct PhotoDetailView: View {
    let photo: PhotoItem
    let photos: [PhotoItem]
    let currentIndex: Int
    @Environment(\.dismiss) var dismiss
    @State private var currentPhotoIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    init(photo: PhotoItem, photos: [PhotoItem], currentIndex: Int) {
        self.photo = photo
        self.photos = photos
        self.currentIndex = currentIndex
        _currentPhotoIndex = State(initialValue: currentIndex)
    }
    
    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()
            
            TabView(selection: $currentPhotoIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    VStack(spacing: Theme.Spacing.m) {
                        Spacer()
                        
                        // Photo or Placeholder
                        if let image = photo.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: 400)
                                .cornerRadius(Theme.CornerRadius.medium)
                        } else {
                            ZStack {
                                Color.sioreeLightGrey.opacity(0.3)
                                
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        
                        VStack(spacing: Theme.Spacing.s) {
                            Text(photo.eventName)
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            
                            Text(photo.date.formatted(date: .long, time: .shortened))
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeLightGrey)
                            
                            if !photo.caption.isEmpty {
                                Text(photo.caption)
                                    .font(.sioreeBody)
                                    .foregroundColor(Color.sioreeWhite)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.sioreeWhite.opacity(0.8))
                    }
                    .padding(Theme.Spacing.m)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    HostHistoryView(hostId: "h1", hostName: "LindaFlora")
}

