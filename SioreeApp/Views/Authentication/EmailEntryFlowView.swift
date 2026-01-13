//
//  EmailEntryFlowView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct EmailEntryFlowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var isChecking = false
    @State private var errorMessage: String?
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var resolvedEmail = ""
    @State private var showFallbackChoice = false
    
    private let authService = AuthService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.9), Color.sioreeCharcoal.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    VStack(spacing: Theme.Spacing.s) {
                        Text("Continue with email")
                            .font(.sioreeH1)
                            .foregroundColor(.sioreeWhite)
                            .multilineTextAlignment(.center)
                        
                        Text("We’ll guide you to login if you already have an account, or set you up if you’re new.")
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeLightGrey.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.l)
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    
                    VStack(spacing: Theme.Spacing.m) {
                        CustomTextField(
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        
                        if let message = errorMessage {
                            Text(message)
                                .font(.sioreeCaption)
                                .foregroundColor(.red.opacity(0.85))
                        }
                        
                        CustomButton(
                            title: isChecking ? "Checking..." : "Continue",
                            variant: .primary,
                            size: .large
                        ) {
                            continueFlow()
                        }
                        .disabled(isChecking || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .overlay {
                            if isChecking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .sioreeWhite))
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    
                    VStack(spacing: Theme.Spacing.s) {
                        Text("Need help?")
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeLightGrey)
                        
                        HStack(spacing: Theme.Spacing.m) {
                            Button("Log In") {
                                resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                showLogin = true
                            }
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeIcyBlue)
                            
                            Button("Create Account") {
                                resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                showSignup = true
                            }
                            .font(.sioreeBodySmall)
                            .foregroundColor(.sioreeIcyBlue)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    
                    Spacer()
                }
                .padding(.top, Theme.Spacing.xl)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(initialEmail: resolvedEmail, showsSignUpLink: false) {
                showLogin = false
            }
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showSignup) {
            SignUpView(prefilledEmail: resolvedEmail, startsFromEmailFlow: true)
                .environmentObject(authViewModel)
        }
        .alert("Connection issue", isPresented: $showFallbackChoice) {
            Button("Try Login") {
                resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                showLogin = true
            }
            Button("Create Account") {
                resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                showSignup = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("We couldn’t verify this email automatically. You can still choose to log in or create an account.")
        }
    }
    
    private func continueFlow() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Enter a valid email to continue."
            return
        }
        
        errorMessage = nil
        resolvedEmail = trimmedEmail
        isChecking = true
        
        authService.checkEmailExists(email: trimmedEmail)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isChecking = false
                    if case .failure = completion {
                        showFallbackChoice = true
                    }
                },
                receiveValue: { exists in
                    isChecking = false
                    if exists {
                        showLogin = true
                    } else {
                        showSignup = true
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}


