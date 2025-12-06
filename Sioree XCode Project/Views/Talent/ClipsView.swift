//
//  ClipsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct ClipsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var clips: [TalentClip]
    @State private var showAddClip = false
    
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
                
                if clips.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                        
                        Text("No clips yet")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)
                        
                        Text("Add your first clip to showcase your work")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                        
                        Button(action: {
                            showAddClip = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Clip")
                                    .font(.sioreeBody)
                            }
                            .foregroundColor(Color.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeIcyBlue)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.top, Theme.Spacing.m)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: Theme.Spacing.m),
                            GridItem(.flexible(), spacing: Theme.Spacing.m)
                        ], spacing: Theme.Spacing.m) {
                            ForEach(clips) { clip in
                                ClipCard(clip: clip)
                            }
                        }
                        .padding(Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Clips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddClip = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddClip) {
                AddClipView(clips: $clips)
            }
        }
    }
}

struct AddClipView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var clips: [TalentClip]
    @StateObject private var photoService = PhotoService.shared
    @State private var title = ""
    @State private var duration = ""
    @State private var selectedThumbnail = "video.fill"
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var showPermissionAlert = false
    @State private var isUploading = false
    
    let thumbnailOptions = ["video.fill", "music.note.list", "party.popper.fill", "sun.max.fill", "star.fill", "flame.fill"]
    
    private var isFormValid: Bool {
        !title.isEmpty && !duration.isEmpty
    }
    
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
                
                Form {
                    Section("Clip Details") {
                        CustomTextField(placeholder: "Title *", text: $title)
                        CustomTextField(placeholder: "Duration (e.g., 3:45) *", text: $duration)
                    }
                    
                    Section("Thumbnail") {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    Button(action: {
                                        selectedImage = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .padding(8),
                                    alignment: .topTrailing
                                )
                        }
                        
                        Button(action: {
                            checkPermissionAndShowPicker()
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(selectedImage == nil ? "Select Photo" : "Change Photo")
                                    .font(.sioreeBody)
                            }
                            .foregroundColor(.sioreeIcyBlue)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeWhite)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addClip()
                    }
                    .foregroundColor(isFormValid ? Color.sioreeIcyBlue : Color.sioreeLightGrey)
                    .disabled(!isFormValid || isUploading)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .alert("Photo Library Access", isPresented: $showPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please allow access to your photo library to select clip thumbnails.")
            }
        }
    }
    
    private func checkPermissionAndShowPicker() {
        photoService.checkPermissionStatus()
        
        switch photoService.permissionStatus {
        case .authorized, .limited:
            showPhotoPicker = true
        case .notDetermined:
            photoService.requestPermission()
                .sink { status in
                    if status == .authorized || status == .limited {
                        showPhotoPicker = true
                    } else {
                        showPermissionAlert = true
                    }
                }
                .store(in: &cancellables)
        case .denied, .restricted:
            showPermissionAlert = true
        }
    }
    
    private func addClip() {
        isUploading = true
        
        if let image = selectedImage {
            photoService.uploadImage(image)
                .sink(
                    receiveCompletion: { completion in
                        isUploading = false
                        if case .failure(let error) = completion {
                            print("Upload error: \(error)")
                        }
                    },
                    receiveValue: { imageUrl in
                        let newClip = TalentClip(
                            id: UUID().uuidString,
                            title: title,
                            thumbnail: imageUrl, // Store URL instead of icon name
                            duration: duration
                        )
                        clips.append(newClip)
                        dismiss()
                    }
                )
                .store(in: &cancellables)
        } else {
            let newClip = TalentClip(
                id: UUID().uuidString,
                title: title,
                thumbnail: selectedThumbnail,
                duration: duration
            )
            clips.append(newClip)
            dismiss()
        }
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    ClipsView(clips: .constant([]))
}

