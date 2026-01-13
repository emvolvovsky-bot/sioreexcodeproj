//
//  LoginView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?
    
    private let showsSignUpLink: Bool
    private let onClose: (() -> Void)?
    
    init(initialEmail: String? = nil, showsSignUpLink: Bool = true, onClose: (() -> Void)? = nil) {
        self._email = State(initialValue: initialEmail ?? "")
        self.showsSignUpLink = showsSignUpLink
        self.onClose = onClose
    }
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.xl) {
                if onClose != nil {
                    HStack {
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.sioreeWhite)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.m)
                }
                
                Spacer()
                
                // Logo/Branding
                VStack(spacing: Theme.Spacing.m) {
                    LogoView(size: .large, isSpinning: authViewModel.isLoading)
                    
                    Text("Nightlife Infrastructure")
                        .font(.sioreeBody)
                        .foregroundColor(Color.sioreeLightGrey)
                }
                .padding(.bottom, Theme.Spacing.xxl)
                
                // Form
                VStack(spacing: Theme.Spacing.m) {
                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            focusedField = .password
                        }
                    }
                    
                    CustomTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        login()
                    }
                    
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.sioreeBodySmall)
                        .foregroundColor(Color.sioreeIcyBlue)
                        .transition(.opacity)
                    }
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                            .frame(height: 52)
                            .transition(.opacity)
                    } else {
                        Button(action: login) {
                            Text("Log In")
                                .font(.sioreeBody)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(GlowingPillButtonStyle())
                        .padding(.top, Theme.Spacing.s)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoading)
                
                // Sign Up Link
                if showsSignUpLink {
                    HStack {
                        Text("Don't have an account?")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(.sioreeBody)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.sioreeIcyBlue)
                    }
                    .padding(.top, Theme.Spacing.l)
                }
                
                Spacer()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(email: email)
        }
        .alert("Login Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let error = authViewModel.errorMessage {
                Text(error)
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            // Login view will be automatically replaced by ContentView when authenticated
            // No need to dismiss manually - ContentView handles the transition
            if newValue && !oldValue {
                print("✅ Login successful - ContentView will show main app")
            }
        }
    }
    
    private func login() {
        hideKeyboard()
        authViewModel.login(email: email, password: password)
    }
    
    private func close() {
        onClose?()
        dismiss()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

private struct GlowingPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(Color.sioreeIcyBlue)
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.45), radius: 18, x: 0, y: 10)
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.28), radius: 28, x: 0, y: 0)
            )
            .foregroundColor(.sioreeWhite)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

