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
    @State private var selectedVideo: URL?
    @State private var showVideoPicker = false
    @State private var showPermissionAlert = false
    @State private var isUploading = false
    
    private var isFormValid: Bool {
        !title.isEmpty && selectedVideo != nil
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
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Title Input
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Title")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            TextField("Enter clip title", text: $title)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .foregroundColor(.sioreeWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal, Theme.Spacing.m)
                        }
                        .padding(.top, Theme.Spacing.m)
                        
                        // Video Selection
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Video")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            Button(action: {
                                showVideoPicker = true
                            }) {
                                HStack {
                                    Image(systemName: selectedVideo == nil ? "video.badge.plus" : "video.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.sioreeIcyBlue)
                                    
                                    Text(selectedVideo == nil ? "Select Video" : "Video Selected")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    
                                    Spacer()
                                    
                                    if selectedVideo != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                    }
                                }
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            
                            if let videoURL = selectedVideo {
                                Text(videoURL.lastPathComponent)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                                    .padding(.horizontal, Theme.Spacing.m)
                                    .padding(.top, Theme.Spacing.xs)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
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
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker(selectedVideo: $selectedVideo)
            }
            .alert("Video Library Access", isPresented: $showPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please allow access to your photo library to select videos.")
            }
        }
    }
    
    private func addClip() {
        guard let videoURL = selectedVideo else { return }
        isUploading = true
        
        // TODO: Upload video to backend and get video URL
        // For now, create clip with video URL
        let newClip = TalentClip(
            id: UUID().uuidString,
            title: title,
            thumbnail: "video.fill", // Will be replaced with actual thumbnail from video
            videoURL: videoURL.absoluteString,
            duration: "" // No duration needed
        )
        clips.append(newClip)
        isUploading = false
        dismiss()
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    ClipsView(clips: .constant([]))
}

