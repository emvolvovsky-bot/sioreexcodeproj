//
//  SignUpView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var name = ""
    @State private var selectedUserType: UserType = .partier
    @State private var currentStep = 1
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    // Progress Indicator
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(1...3, id: \.self) { step in
                            Rectangle()
                                .fill(step <= currentStep ? Color.sioreeIcyBlue : Color.sioreeLightGrey)
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.m)
                    
                    // Form Content
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            Group {
                                if currentStep == 1 {
                                    userTypeSelection
                                } else if currentStep == 2 {
                                    accountDetails
                                } else {
                                    personalInfo
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        .padding(Theme.Spacing.l)
                    }
                    
                    // Navigation Buttons
                    HStack(spacing: Theme.Spacing.m) {
                        if currentStep > 1 {
                            CustomButton(
                                title: "Back",
                                variant: .secondary,
                                size: .medium
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }
                            .opacity(authViewModel.isLoading ? 0.5 : 1.0)
                            .disabled(authViewModel.isLoading)
                        }
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        } else {
                            CustomButton(
                                title: currentStep == 3 ? "Sign Up" : "Next",
                                variant: .primary,
                                size: .medium
                            ) {
                                handleNext()
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.m)
                    .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoading)
                }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color.sioreeWhite)
                .disabled(authViewModel.isLoading)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .alert("Sign Up Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let error = authViewModel.errorMessage {
                Text(error)
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            // Dismiss signup view when user is authenticated
            if newValue && !oldValue {
                print("✅ Signup successful - dismissing signup view")
                dismiss()
            }
        }
    }
    }
    
    private var userTypeSelection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("I am a...")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
            
            ForEach([UserType.host, .partier, .talent, .brand], id: \.self) { type in
                Button(action: {
                    selectedUserType = type
                }) {
                    HStack {
                        Text(type.rawValue.capitalized)
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeWhite)
                        Spacer()
                        if selectedUserType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.sioreeIcyBlue)
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .background(selectedUserType == type ? Color.sioreeIcyBlue.opacity(0.1) : Color.sioreeLightGrey)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
        }
    }
    
    private var accountDetails: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Account Details")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
            
            CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
            CustomTextField(placeholder: "Username", text: $username)
            CustomTextField(placeholder: "Password", text: $password, isSecure: true)
        }
    }
    
    private var personalInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Personal Information")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
            
            CustomTextField(placeholder: "Full Name", text: $name)
            
            // Add location field for talent users
            if selectedUserType == .talent {
                CustomTextField(placeholder: "Location (City, State)", text: Binding(
                    get: { location },
                    set: { location = $0 }
                ))
            }
        }
    }
    
    @State private var location = ""
    
    private func handleNext() {
        if currentStep < 3 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            signUp()
        }
    }
    
    private func signUp() {
        hideKeyboard()
        // Include location for talent users
        let locationToSend = (selectedUserType == .talent && !location.isEmpty) ? location : nil
        authViewModel.signUp(
            email: email,
            password: password,
            username: username,
            name: name,
            userType: selectedUserType,
            location: locationToSend
        )
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}

