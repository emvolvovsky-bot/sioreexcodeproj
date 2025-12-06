//
//  ProfileEditView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    let user: User?
    @State private var name: String
    @State private var email: String
    @State private var bio: String
    @State private var location: String
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(user: User?) {
        self.user = user
        _name = State(initialValue: user?.name ?? "")
        _email = State(initialValue: user?.email ?? "")
        _bio = State(initialValue: user?.bio ?? "")
        _location = State(initialValue: user?.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // White to grey gradient for light mode
                LinearGradient(
                    colors: [Color(white: 0.98), Color(white: 0.95), Color(white: 0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section("Account Information") {
                        CustomTextField(placeholder: "Name", text: $name)
                        CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
                            .disabled(true) // Email is read-only, can't be changed
                            .foregroundColor(.sioreeLightGrey)
                    }
                    
                    Section("Profile Details") {
                        CustomTextField(placeholder: "Bio", text: $bio)
                        CustomTextField(placeholder: "Location", text: $location)
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
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
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
    
    private func saveProfile() {
        isSaving = true
        errorMessage = ""
        
        viewModel.updateProfile(
            name: name.isEmpty ? nil : name,
            bio: bio.isEmpty ? nil : bio,
            location: location.isEmpty ? nil : location
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

