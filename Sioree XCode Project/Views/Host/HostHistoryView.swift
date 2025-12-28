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
    @State private var selectedVideo: VideoItem?
    @State private var showAddVideos = false

    // Store videos from camera roll
    @State private var videos: [VideoItem] = []
    
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
                        if videos.isEmpty {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))

                                Text("No videos yet")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)

                                Text("Add videos to create your compilation")
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
                                ForEach(videos) { video in
                                    VideoThumbnail(video: video) {
                                        selectedVideo = video
                                    }
                                }
                            }
                            .padding(Theme.Spacing.s)
                        }
                        
                        // Add Videos Button
                        Button(action: {
                            showAddVideos = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add Videos")
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
            .navigationTitle("\(hostName)'s Video Compilation")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(item: $selectedVideo) { video in
                VideoPlayerView(video: video, videos: videos, currentIndex: videos.firstIndex(where: { $0.id == video.id }) ?? 0)
            }
            .sheet(isPresented: $showAddVideos) {
                AddVideosView(hostId: hostId, onVideosAdded: { videoURLs in
                    // Add new videos to the videos array
                    let newVideos = videoURLs.enumerated().map { index, videoURL in
                        VideoItem(
                            id: UUID().uuidString,
                            videoURL: videoURL,
                            eventName: "Camera Roll",
                            date: Date(),
                            caption: "",
                            thumbnail: nil
                        )
                    }
                    videos.append(contentsOf: newVideos)
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

struct VideoItem: Identifiable {
    let id: String
    let videoURL: URL?
    let eventName: String
    let date: Date
    let caption: String
    let thumbnail: UIImage?

    init(id: String, videoURL: URL? = nil, eventName: String, date: Date, caption: String, thumbnail: UIImage? = nil) {
        self.id = id
        self.videoURL = videoURL
        self.eventName = eventName
        self.date = date
        self.caption = caption
        self.thumbnail = thumbnail
    }
}

struct VideoThumbnail: View {
    let video: VideoItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Video thumbnail or Placeholder
                if let thumbnail = video.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(Theme.CornerRadius.medium)
                } else {
                    ZStack {
                        Color.sioreeLightGrey.opacity(0.3)

                        VStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))

                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.sioreeIcyBlue)
                        }
                    }
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(Theme.CornerRadius.medium)
                }

                // Play button overlay
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 40, height: 40)

                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white)
                }
                .offset(x: 8, y: -8)

                // Event name overlay
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(video.eventName)
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeWhite)
                        .shadow(color: Color.black.opacity(0.8), radius: 2)

                    Text(video.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.8), radius: 2)
                }
                .padding(Theme.Spacing.s)
            }
        }
    }
}

struct AddVideosView: View {
    let hostId: String
    let onVideosAdded: ([URL]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedVideos: [URL] = []
    @State private var showVideoPicker = false

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
                    if selectedVideos.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))

                            Text("Select videos from camera roll")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)

                            Button(action: {
                                showVideoPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Select Videos")
                                        .font(.sioreeBody)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color.sioreeWhite)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(Theme.Spacing.xl)
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.Spacing.m) {
                                Text("Selected Videos (\(selectedVideos.count))")
                                    .font(.sioreeH4)
                                    .foregroundColor(Color.sioreeWhite)
                                    .padding(.horizontal, Theme.Spacing.m)

                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: Theme.Spacing.s),
                                    GridItem(.flexible(), spacing: Theme.Spacing.s)
                                ], spacing: Theme.Spacing.s) {
                                    ForEach(selectedVideos, id: \.self) { videoURL in
                                        ZStack {
                                            Color.sioreeLightGrey.opacity(0.3)
                                                .frame(height: 120)
                                                .cornerRadius(Theme.CornerRadius.small)

                                            VStack(spacing: Theme.Spacing.xs) {
                                                Image(systemName: "video.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.7))

                                                Text(videoURL.lastPathComponent)
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(Color.sioreeWhite)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                        }
                                    }
                                }
                                .padding(Theme.Spacing.m)

                                HStack(spacing: Theme.Spacing.m) {
                                    Button(action: {
                                        showVideoPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16))
                                            Text("Add More")
                                                .font(.sioreeBodySmall)
                                        }
                                        .foregroundColor(Color.sioreeIcyBlue)
                                        .padding(.vertical, Theme.Spacing.s)
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .background(Color.sioreeIcyBlue.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                    }

                                    Button(action: {
                                        onVideosAdded(selectedVideos)
                                        dismiss()
                                    }) {
                                        Text("Add Videos (\(selectedVideos.count))")
                                            .font(.sioreeBody)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.sioreeWhite)
                                            .padding(.vertical, Theme.Spacing.s)
                                            .padding(.horizontal, Theme.Spacing.m)
                                            .background(Color.sioreeIcyBlue)
                                            .cornerRadius(Theme.CornerRadius.medium)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                    .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                            )
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Videos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeIcyBlue)
                }
            }
            .sheet(isPresented: $showVideoPicker) {
                // For now, we'll simulate video selection
                // In a real app, you'd use PHPickerViewController or similar
                Color.sioreeBlack
                    .overlay(
                        VStack(spacing: Theme.Spacing.m) {
                            Text("Video Picker Placeholder")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)

                            Text("This would open the video picker")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey)

                            Button("Simulate Video Selection") {
                                // Add a dummy video URL for demonstration
                                selectedVideos.append(URL(string: "file://dummy-video-\(UUID().uuidString).mp4")!)
                                showVideoPicker = false
                            }
                            .foregroundColor(Color.sioreeIcyBlue)
                        }
                    )
            }
        }
    }
}

struct VideoPlayerView: View {
    let video: VideoItem
    let videos: [VideoItem]
    let currentIndex: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.sioreeBlack.edgesIgnoringSafeArea(.all)

            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(Color.sioreeWhite)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(video.eventName)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)

                        Text(video.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                    }

                    Spacer()

                    // Placeholder for additional actions
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(Color.sioreeWhite)
                        .opacity(0.5)
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.m)

                Spacer()

                // Video player placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Color.sioreeCharcoal)
                        .frame(height: 300)
                        .padding(.horizontal, Theme.Spacing.m)

                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))

                        Text("Video Player")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)

                        Text("Video: \(video.id)")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)

                        // Play button
                        Button(action: {
                            // In a real app, this would play the video
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.sioreeIcyBlue)
                                    .frame(width: 60, height: 60)

                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.sioreeWhite)
                                    .offset(x: 2)
                            }
                        }
                    }
                }

                Spacer()

                // Video navigation
                if videos.count > 1 {
                    HStack(spacing: Theme.Spacing.m) {
                        Button(action: {
                            // Previous video
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24))
                                .foregroundColor(currentIndex > 0 ? Color.sioreeWhite : Color.sioreeLightGrey.opacity(0.5))
                        }
                        .disabled(currentIndex == 0)

                        Text("\(currentIndex + 1) of \(videos.count)")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeWhite)

                        Button(action: {
                            // Next video
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24))
                                .foregroundColor(currentIndex < videos.count - 1 ? Color.sioreeWhite : Color.sioreeLightGrey.opacity(0.5))
                        }
                        .disabled(currentIndex == videos.count - 1)
                    }
                    .padding(.bottom, Theme.Spacing.m)
                }

                // Caption
                if !video.caption.isEmpty {
                    Text(video.caption)
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeWhite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.m)
                }
            }
        }
    }
}

#Preview {
    HostHistoryView(hostId: "h1", hostName: "LindaFlora")
}

