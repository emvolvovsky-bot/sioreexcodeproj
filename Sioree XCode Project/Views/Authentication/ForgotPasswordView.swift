//
//  ForgotPasswordView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    private let authService = AuthService()
    
    init(email: String = "") {
        _email = State(initialValue: email)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(Color.sioreeIcyBlue)
                        .padding(.bottom, Theme.Spacing.m)
                    
                    // Title
                    Text("Forgot Password?")
                        .font(.sioreeH1)
                        .foregroundColor(Color.sioreeWhite)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeLightGrey)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.l)
                    
                    // Email Field
                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.xl)
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.sioreeBodySmall)
                            .foregroundColor(.red)
                            .padding(.horizontal, Theme.Spacing.l)
                    }
                    
                    // Success Message
                    if let success = successMessage {
                        Text(success)
                            .font(.sioreeBodySmall)
                            .foregroundColor(.green)
                            .padding(.horizontal, Theme.Spacing.l)
                    }
                    
                    // Submit Button
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                            .frame(height: 52)
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.top, Theme.Spacing.m)
                    } else {
                        CustomButton(
                            title: "Send Reset Link",
                            variant: .primary,
                            size: .large
                        ) {
                            sendResetLink()
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func sendResetLink() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        authService.forgotPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to send reset link: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [self] _ in
                    isLoading = false
                    successMessage = "Password reset link sent to \(email)"
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    ForgotPasswordView()
}


