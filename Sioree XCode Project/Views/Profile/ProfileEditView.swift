//
//  ProfileEditView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    let user: User?
    @State private var name: String
    @State private var username: String
    @State private var bio: String
    @State private var gender: String = ""
    @State private var showGenderPicker = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showPhotoOptions = false
    @State private var shouldRemovePhoto = false
    @State private var isSaving = false
    @State private var isUploadingPhoto = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()
    
    init(user: User?) {
        self.user = user
        _name = State(initialValue: user?.name ?? "")
        _username = State(initialValue: user?.username ?? "")
        _bio = State(initialValue: user?.bio ?? "")
        _gender = State(initialValue: "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Photo Section
                        VStack(spacing: Theme.Spacing.m) {
                            // Profile Photo Circle
                            let outerSize: CGFloat = 120
                            let borderWidth: CGFloat = 2
                            let borderGap: CGFloat = 2
                            let ringDiameter = outerSize - borderWidth
                            let innerSize = ringDiameter - (borderGap * 2)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.sioreeLightGrey.opacity(0.3), lineWidth: borderWidth)
                                    .frame(width: outerSize, height: outerSize)
                                
                                Circle()
                                    .fill(Color.sioreeBlack)
                                    .frame(width: ringDiameter, height: ringDiameter)
                                
                                Group {
                                    if shouldRemovePhoto {
                                        placeholderAvatar
                                    } else if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else if let avatarURL = user?.avatar, !avatarURL.isEmpty {
                                        AsyncImage(url: URL(string: avatarURL)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            default:
                                                placeholderAvatar
                                            }
                                        }
                                    } else {
                                        placeholderAvatar
                                    }
                                }
                                .frame(width: innerSize, height: innerSize)
                                .clipShape(Circle())
                            }
                            .frame(width: outerSize, height: outerSize)
                            
                            // Edit Picture Button
                            Button(action: {
                                showPhotoOptions = true
                            }) {
                                Text("Edit Picture")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.sioreeIcyBlue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.l)
                        
                        // Instagram-style form fields
                        VStack(spacing: 0) {
                            // Name
                            InstagramStyleEditRow(
                                label: "Name",
                                value: $name,
                                placeholder: "Enter your name"
                            )
                            
                            Divider()
                                .background(Color.sioreeLightGrey.opacity(0.2))
                            
                            // Username
                            InstagramStyleEditRow(
                                label: "Username",
                                value: $username,
                                placeholder: "Enter username"
                            )
                            
                            Divider()
                                .background(Color.sioreeLightGrey.opacity(0.2))
                            
                            // Bio
                            InstagramStyleEditRow(
                                label: "Bio",
                                value: $bio,
                                placeholder: "Write a bio",
                                isMultiline: true,
                                maxCharacters: 150
                            )
                            
                            Divider()
                                .background(Color.sioreeLightGrey.opacity(0.2))
                            
                            // Gender
                            Button(action: {
                                showGenderPicker = true
                            }) {
                                HStack {
                                    Text("Gender")
                                        .font(.system(size: 16))
                                        .foregroundColor(.sioreeWhite)
                                    
                                    Spacer()
                                    
                                    Text(gender.isEmpty ? "Choose gender" : gender)
                                        .font(.system(size: 16))
                                        .foregroundColor(gender.isEmpty ? .sioreeLightGrey : .sioreeWhite)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.vertical, Theme.Spacing.m)
                            }
                            
                            Divider()
                                .background(Color.sioreeLightGrey.opacity(0.2))
                        }
                        .background(Color.sioreeBlack)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving || isUploadingPhoto)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(selectedImage: $selectedImage)
            }
            .confirmationDialog("Edit Profile Photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                Button("Choose from Library") {
                    showImagePicker = true
                }
                
                Button("Take Photo") {
                    showCameraPicker = true
                }
                
                if (user?.avatar != nil && !user!.avatar!.isEmpty) || selectedImage != nil {
                    Button("Remove Profile Photo", role: .destructive) {
                        selectedImage = nil
                        shouldRemovePhoto = true
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog("Choose Gender", isPresented: $showGenderPicker, titleVisibility: .visible) {
                Button("Male") {
                    gender = "Male"
                }
                Button("Female") {
                    gender = "Female"
                }
                Button("Prefer not to say") {
                    gender = "Prefer not to say"
                }
                Button("Cancel", role: .cancel) { }
            }
            .overlay {
                if isSaving || isUploadingPhoto {
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
    
    private var placeholderAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(Color.sioreeLightGrey)
    }
    
    private func saveProfile() {
        isSaving = true
        errorMessage = ""
        
        // Handle photo removal or upload
        if shouldRemovePhoto {
            // Remove profile photo by uploading nil or empty
            // First update profile to remove photo, then update other details
            removeProfilePhoto()
        } else if let image = selectedImage {
            // Upload new photo
            isUploadingPhoto = true
            networkService.uploadProfilePicture(image: image)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [self] completion in
                        isUploadingPhoto = false
                        if case .failure(let error) = completion {
                            errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                            showError = true
                            isSaving = false
                        } else {
                            // Photo uploaded successfully - refresh current user to get new avatar URL
                            authViewModel.fetchCurrentUser()
                            // Then update profile details
                            updateProfileDetails()
                        }
                    },
                    receiveValue: { [self] avatarURL in
                        // Photo uploaded successfully - update current user immediately
                        if var currentUser = authViewModel.currentUser {
                            currentUser.avatar = avatarURL
                            authViewModel.currentUser = currentUser
                        }
                        // Continue with profile update
                    }
                )
                .store(in: &cancellables)
        } else {
            // No photo change, just update profile
            updateProfileDetails()
        }
    }
    
    private func removeProfilePhoto() {
        // Call API to remove profile photo
        // For now, we'll update the profile without a photo
        // The backend should handle removing the avatar URL
        viewModel.updateProfile(
            name: name.isEmpty ? nil : name,
            username: username.isEmpty ? nil : username,
            bio: bio.isEmpty ? nil : bio,
            location: nil
        )
        
        // Also update avatar to nil via network service if there's a remove endpoint
        // For now, we'll just update other profile details
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            if let error = viewModel.errorMessage, !error.isEmpty {
                errorMessage = error
                showError = true
            } else if viewModel.user != nil {
                // Success - refresh current user and dismiss
                authViewModel.fetchCurrentUser()
                dismiss()
            } else {
                errorMessage = "Failed to update profile. Please try again."
                showError = true
            }
        }
    }
    
    private func updateProfileDetails() {
        viewModel.updateProfile(
            name: name.isEmpty ? nil : name,
            username: username.isEmpty ? nil : username,
            bio: bio.isEmpty ? nil : bio,
            location: nil // Location removed from edit profile
        )
        
        // Monitor viewModel for completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            if let error = viewModel.errorMessage, !error.isEmpty {
                errorMessage = error
                showError = true
            } else if viewModel.user != nil {
                // Success - refresh current user and dismiss
                authViewModel.fetchCurrentUser()
                dismiss()
            } else {
                // Still loading or failed silently
                errorMessage = "Failed to update profile. Please try again."
                showError = true
            }
        }
    }
}

#Preview {
    ProfileEditView(
        user: User(
            email: "test@example.com",
            username: "testuser",
            name: "Test User",
            bio: "Bio",
            userType: .partier
        )
    )
}

