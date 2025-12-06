//
//  SettingsPlaceholders.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

// Placeholder views for settings sections
struct EditProfileSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    
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
                    VStack(spacing: Theme.Spacing.xl) {
                        // Profile Picture Section
                        VStack(spacing: Theme.Spacing.m) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.sioreeIcyBlue, lineWidth: 3))
                            } else if let user = authViewModel.currentUser, let avatarURL = user.avatar {
                                AsyncImage(url: URL(string: avatarURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(Color.sioreeLightGrey.opacity(0.3))
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.sioreeIcyBlue, lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(Color.sioreeLightGrey.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.sioreeLightGrey)
                                    )
                                    .overlay(Circle().stroke(Color.sioreeIcyBlue, lineWidth: 3))
                            }
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Text("Change Photo")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeIcyBlue)
                            }
                            
                            if selectedImage != nil {
                                Button(action: {
                                    saveProfilePicture()
                                }) {
                                    Text("Save Photo")
                                        .font(.sioreeBody)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.sioreeWhite)
                                        .frame(maxWidth: .infinity)
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeIcyBlue)
                                        .cornerRadius(Theme.CornerRadius.medium)
                                }
                                .disabled(isSaving)
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        .padding(.top, Theme.Spacing.l)
                        
                        // Profile Information
                        VStack(spacing: Theme.Spacing.m) {
                            if let user = authViewModel.currentUser {
                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                    Text("Name")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                    
                                    Text(user.name)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                    Text("Username")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                    
                                    Text("@\(user.username)")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                    Text("Email")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                    
                                    Text(user.email)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                
                                if let bio = user.bio {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                        Text("Bio")
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeLightGrey)
                                        
                                        Text(bio)
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeWhite)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                }
                                
                                if let location = user.location {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                        Text("Location")
                                            .font(.sioreeCaption)
                                            .foregroundColor(.sioreeLightGrey)
                                        
                                        Text(location)
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeWhite)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        Text("To edit your profile information, use 'Edit Profile' from the profile menu")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.top, Theme.Spacing.s)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                            .scaleEffect(1.5)
                    }
                }
            }
        }
    }
    
    private func saveProfilePicture() {
        guard let image = selectedImage else { return }
        
        isSaving = true
        let networkService = NetworkService()
        
        networkService.uploadProfilePicture(image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isSaving = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to upload profile picture: \(error)")
                    }
                },
                receiveValue: { avatarURL in
                    isSaving = false
                    print("✅ Profile picture uploaded: \(avatarURL)")
                    // Update current user's avatar immediately
                    if var currentUser = authViewModel.currentUser {
                        currentUser.avatar = avatarURL
                        authViewModel.currentUser = currentUser
                    }
                    // Refresh user data from backend
                    authViewModel.fetchCurrentUser()
                    // Clear selected image
                    selectedImage = nil
                    // Dismiss after a short delay to show success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .foregroundColor(.sioreeWhite)
            .navigationTitle("Privacy")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        Text("Security Settings")
            .foregroundColor(.sioreeWhite)
            .navigationTitle("Security")
    }
}

struct BlockedUsersView: View {
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var blockedUsers: [User] = []
    @State private var isSearching = false
    private let networkService = NetworkService()
    
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
                
                VStack(spacing: Theme.Spacing.m) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        
                        TextField("Search users to block", text: $searchText)
                            .foregroundStyle(Color.primary)
                            .onSubmit {
                                searchUsers()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.sioreeLightGrey)
                            }
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.m)
                    
                    // Search Results or Blocked Users List
                    if !searchText.isEmpty && !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(searchResults) { user in
                                    UserBlockRow(user: user, isBlocked: blockedUsers.contains(where: { $0.id == user.id })) {
                                        blockUser(user)
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    } else if blockedUsers.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .font(.system(size: 50))
                                .foregroundColor(.sioreeLightGrey.opacity(0.5))
                            
                            Text("No blocked users")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            Text("Search for users above to block them")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xl)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(blockedUsers) { user in
                                    UserBlockRow(user: user, isBlocked: true) {
                                        unblockUser(user)
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if isSearching {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                    }
                }
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        networkService.searchUsers(query: searchText)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isSearching = false
                    if case .failure(let error) = completion {
                        print("Search error: \(error)")
                    }
                },
                receiveValue: { users in
                    isSearching = false
                    searchResults = users
                }
            )
            .store(in: &cancellables)
    }
    
    private func blockUser(_ user: User) {
        // TODO: Implement block user API call
        if !blockedUsers.contains(where: { $0.id == user.id }) {
            blockedUsers.append(user)
        }
        searchResults.removeAll(where: { $0.id == user.id })
    }
    
    private func unblockUser(_ user: User) {
        // TODO: Implement unblock user API call
        blockedUsers.removeAll(where: { $0.id == user.id })
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct UserBlockRow: View {
    let user: User
    let isBlocked: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            AvatarView(imageURL: user.avatar, size: .small)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(user.name)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                Text("@\(user.username)")
                    .font(.sioreeCaption)
                    .foregroundColor(.sioreeLightGrey)
            }
            
            Spacer()
            
            Button(action: action) {
                Text(isBlocked ? "Unblock" : "Block")
                    .font(.sioreeBodySmall)
                    .foregroundColor(isBlocked ? .sioreeIcyBlue : .red)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(isBlocked ? Color.sioreeIcyBlue.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(Theme.CornerRadius.small)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "dark"
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Subtle gradient on black background
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                Section("Theme") {
                    Button(action: {
                        colorScheme = "light"
                    }) {
                        HStack {
                            Text("Light Mode")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                            
                            Spacer()
                            
                            if colorScheme == "light" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                            } else {
                                Circle()
                                    .stroke(Color.sioreeWhite, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .listRowBackground(Color.sioreeLightGrey.opacity(0.1))
                    
                    Button(action: {
                        colorScheme = "dark"
                    }) {
                        HStack {
                            Text("Dark Mode")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                            
                            Spacer()
                            
                            if colorScheme == "dark" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                            } else {
                                Circle()
                                    .stroke(Color.sioreeWhite, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .listRowBackground(Color.sioreeLightGrey.opacity(0.1))
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LanguageSettingsView: View {
    var body: some View {
        Text("Language Settings")
            .foregroundColor(.sioreeWhite)
            .navigationTitle("Language")
    }
}

struct DataUsageView: View {
    var body: some View {
        Text("Data Usage")
            .foregroundColor(.sioreeWhite)
            .navigationTitle("Data Usage")
    }
}

struct HelpCenterView: View {
    var body: some View {
        Text("Help Center")
            .foregroundColor(.sioreeWhite)
            .navigationTitle("Help Center")
    }
}

struct ContactSupportView: View {
    var body: some View {
        Text("Contact Support")
            .foregroundColor(.sioreeWhite)
            .navigationTitle("Contact Support")
    }
}

struct TermsView: View {
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Terms of Service")
                                .font(.sioreeH1)
                                .foregroundColor(.sioreeWhite)
                            
                            Text("Last Updated: December 2024")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.bottom, Theme.Spacing.m)
                        
                        // Section 1
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("1. Acceptance of Terms")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("By accessing and using Sioree, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 2
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("2. Use License")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Permission is granted to temporarily download one copy of Sioree for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("• Modify or copy the materials")
                                Text("• Use the materials for any commercial purpose")
                                Text("• Attempt to reverse engineer any software contained in Sioree")
                                Text("• Remove any copyright or other proprietary notations")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                        }
                        
                        // Section 3
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("3. User Accounts")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 4
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("4. User Content")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("You retain ownership of any content you post on Sioree. By posting content, you grant Sioree a worldwide, non-exclusive, royalty-free license to use, reproduce, and distribute your content for the purpose of operating and promoting the service.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("You agree not to post content that is illegal, harmful, threatening, abusive, or violates any third-party rights.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 5
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("5. Events and Bookings")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Hosts are responsible for the accuracy of event information. Sioree is not liable for any issues arising from events, including cancellations, changes, or disputes between hosts and attendees.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("All bookings and transactions are between users. Sioree facilitates connections but is not a party to any agreements.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 6
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("6. Payments and Refunds")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Payment processing is handled through secure third-party providers. Refund policies are determined by individual hosts and event organizers. Sioree may charge service fees for certain transactions.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 7
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("7. Prohibited Activities")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("You agree not to:")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeLightGrey)
                                
                                Text("• Violate any applicable laws or regulations")
                                Text("• Infringe on intellectual property rights")
                                Text("• Harass, abuse, or harm other users")
                                Text("• Spam or send unsolicited communications")
                                Text("• Interfere with the service's operation")
                                Text("• Use automated systems to access the service")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                        }
                        
                        // Section 8
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("8. Termination")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We may terminate or suspend your account immediately, without prior notice, for conduct that we believe violates these Terms of Service or is harmful to other users, us, or third parties.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 9
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("9. Limitation of Liability")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Sioree shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 10
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("10. Changes to Terms")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We reserve the right to modify these terms at any time. We will notify users of any material changes. Continued use of the service after changes constitutes acceptance of the new terms.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 11
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("11. Contact Information")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("If you have any questions about these Terms of Service, please contact us at:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("support@sioree.com")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeIcyBlue)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Footer
                        Text("By using Sioree, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                            .italic()
                            .padding(.top, Theme.Spacing.l)
                    }
                    .padding(Theme.Spacing.l)
                }
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Privacy Policy")
                                .font(.sioreeH1)
                                .foregroundColor(.sioreeWhite)
                            
                            Text("Last Updated: December 2024")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.bottom, Theme.Spacing.m)
                        
                        // Introduction
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Introduction")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Sioree (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 1
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("1. Information We Collect")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We collect information that you provide directly to us, including:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("• Account information (name, email, password)")
                                Text("• Profile information (bio, photos, location)")
                                Text("• Payment information (processed securely through third-party providers)")
                                Text("• Bank account information (for payouts, via Plaid)")
                                Text("• Social media connections (Instagram, TikTok, YouTube, Spotify)")
                                Text("• Event and booking information")
                                Text("• Messages and communications")
                                Text("• Device information and usage data")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                        }
                        
                        // Section 2
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("2. How We Use Your Information")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We use the information we collect to:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("• Provide, maintain, and improve our services")
                                Text("• Process transactions and send related information")
                                Text("• Send you technical notices and support messages")
                                Text("• Respond to your comments and questions")
                                Text("• Communicate with you about events, bookings, and services")
                                Text("• Monitor and analyze trends and usage")
                                Text("• Detect, prevent, and address technical issues")
                                Text("• Personalize your experience")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                        }
                        
                        // Section 3
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("3. Information Sharing and Disclosure")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We do not sell your personal information. We may share your information only in the following circumstances:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("• With your consent")
                                Text("• With service providers who assist us in operating our platform")
                                Text("• To comply with legal obligations")
                                Text("• To protect our rights and safety")
                                Text("• In connection with a business transfer")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                            
                            Text("Public profile information (name, photos, bio) may be visible to other users as part of the service.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 4
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("4. Third-Party Services")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We use third-party services that may collect information used to identify you:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("• Payment processors (Stripe, PayPal)")
                                Text("• Bank account verification (Plaid)")
                                Text("• Social media platforms (Instagram, TikTok, YouTube, Spotify)")
                                Text("• Analytics services")
                                Text("• Cloud storage providers")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                            
                            Text("These services have their own privacy policies. We encourage you to review them.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 5
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("5. Data Security")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We implement appropriate technical and organizational measures to protect your personal information. However, no method of transmission over the Internet is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("Sensitive information such as passwords and payment data are encrypted. Bank account tokens are encrypted at rest.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 6
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("6. Your Rights and Choices")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("You have the right to:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("• Access and update your account information")
                                Text("• Delete your account and personal data")
                                Text("• Opt out of marketing communications")
                                Text("• Request a copy of your data")
                                Text("• Disconnect social media accounts")
                                Text("• Remove bank account connections")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey)
                            .padding(.leading, Theme.Spacing.m)
                            
                            Text("You can exercise these rights through the app settings or by contacting us.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 7
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("7. Data Retention")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We retain your information for as long as your account is active or as needed to provide services. We may retain certain information for legitimate business purposes or as required by law.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("When you delete your account, we will delete or anonymize your personal information, except where we are required to retain it for legal purposes.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Section 8
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("8. Children's Privacy")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Sioree is not intended for users under the age of 18. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 9
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("9. International Users")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("If you are using Sioree from outside the United States, please note that your information may be transferred to, stored, and processed in the United States where our servers are located.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 10
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("10. Changes to This Policy")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the \"Last Updated\" date.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        
                        // Section 11
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("11. Contact Us")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("If you have questions about this Privacy Policy, please contact us at:")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Email: privacy@sioree.com")
                                Text("Support: support@sioree.com")
                            }
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeIcyBlue)
                            .padding(.top, Theme.Spacing.xs)
                        }
                        
                        // Footer
                        Text("By using Sioree, you acknowledge that you have read and understood this Privacy Policy.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                            .italic()
                            .padding(.top, Theme.Spacing.l)
                    }
                    .padding(Theme.Spacing.l)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(spacing: Theme.Spacing.xl) {
                        // Logo/Header Section
                        VStack(spacing: Theme.Spacing.m) {
                            // App Icon Placeholder
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.sioreeIcyBlue.opacity(0.3), Color.sioreeWarmGlow.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 50))
                                        .foregroundColor(.sioreeIcyBlue)
                                )
                            
                            Text("Sioree")
                                .font(.sioreeH1)
                                .foregroundColor(.sioreeWhite)
                            
                            Text("Version 1.0.0")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.top, Theme.Spacing.l)
                        
                        // Mission Statement
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Our Mission")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Sioree is the ultimate platform connecting nightlife enthusiasts, event hosts, talented performers, and brands. We're building a community where high-design meets underground culture—exclusive but effortless, calm, sleek, and curated.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        // What We Do
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("What We Do")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                FeatureRow(
                                    icon: "calendar",
                                    title: "Event Discovery",
                                    description: "Find and attend the best nightlife events in your area"
                                )
                                
                                FeatureRow(
                                    icon: "person.2",
                                    title: "Host Management",
                                    description: "Create, manage, and promote your events with powerful tools"
                                )
                                
                                FeatureRow(
                                    icon: "music.note",
                                    title: "Talent Marketplace",
                                    description: "Connect with DJs, performers, and artists for your events"
                                )
                                
                                FeatureRow(
                                    icon: "megaphone",
                                    title: "Brand Partnerships",
                                    description: "Reach your target audience through strategic event sponsorships"
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        // Our Values
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Our Values")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                ValueRow(
                                    icon: "star.fill",
                                    title: "Excellence",
                                    description: "We strive for the highest quality in everything we do"
                                )
                                
                                ValueRow(
                                    icon: "heart.fill",
                                    title: "Community",
                                    description: "Building connections and fostering authentic relationships"
                                )
                                
                                ValueRow(
                                    icon: "sparkles",
                                    title: "Innovation",
                                    description: "Pushing boundaries in nightlife and event technology"
                                )
                                
                                ValueRow(
                                    icon: "lock.shield.fill",
                                    title: "Trust",
                                    description: "Your privacy and security are our top priorities"
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        // Technology
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Built With")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Sioree is built using modern technologies to provide a seamless, secure, and beautiful experience. We use industry-leading encryption, secure payment processing, and real-time messaging to keep you connected.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        // Contact & Links
                        VStack(spacing: Theme.Spacing.m) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                Text("Get in Touch")
                                    .font(.sioreeH3)
                                    .foregroundColor(.sioreeIcyBlue)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    LinkRow(icon: "envelope", text: "support@sioree.com", url: "mailto:support@sioree.com")
                                    LinkRow(icon: "globe", text: "www.sioree.com", url: "https://sioree.com")
                                    LinkRow(icon: "at", text: "@sioree", url: "https://instagram.com/sioree")
                                }
                            }
                            
                            Divider()
                                .background(Color.sioreeLightGrey.opacity(0.3))
                            
                            // Legal Links
                            VStack(spacing: Theme.Spacing.s) {
                                Text("Legal")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeLightGrey)
                                
                                HStack(spacing: Theme.Spacing.l) {
                                    Text("Terms of Service")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeIcyBlue)
                                    
                                    Text("•")
                                        .foregroundColor(.sioreeLightGrey)
                                    
                                    Text("Privacy Policy")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeIcyBlue)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        // Copyright
                        Text("© 2024 Sioree. All rights reserved.")
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey.opacity(0.6))
                            .padding(.bottom, Theme.Spacing.l)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
}

// Helper Views for About Page
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.sioreeIcyBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.sioreeBodyBold)
                    .foregroundColor(.sioreeWhite)
                
                Text(description)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeLightGrey)
            }
        }
    }
}

struct ValueRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.sioreeWarmGlow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.sioreeBodyBold)
                    .foregroundColor(.sioreeWhite)
                
                Text(description)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeLightGrey)
            }
        }
    }
}

struct LinkRow: View {
    let icon: String
    let text: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url) ?? URL(string: "https://sioree.com")!) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.sioreeIcyBlue)
                    .frame(width: 20)
                
                Text(text)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeIcyBlue)
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundColor(.sioreeLightGrey)
            }
        }
    }
}

