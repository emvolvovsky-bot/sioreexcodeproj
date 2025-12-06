//
//  LoginView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.xl) {
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
                        CustomButton(
                            title: "Login",
                            variant: .primary,
                            size: .large
                        ) {
                            login()
                        }
                        .padding(.top, Theme.Spacing.s)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoading)
                
                // Sign Up Link
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
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

