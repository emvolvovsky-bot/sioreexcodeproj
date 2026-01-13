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
    
    @State private var email: String
    @State private var password = ""
    @State private var username = ""
    @State private var name = ""
    @State private var location = ""
    @State private var selectedRole: UserRole?
    @State private var currentStep = 1
    @State private var vibeSelection = "House parties & nightlife"
    @State private var goalSelection = "Discover events"
    @State private var validationMessage: String?
    @State private var showLoginSheet = false
    @State private var guideSelection = 0
    @State private var isEditing = false
    
    private let startsFromEmailFlow: Bool
    private let guideItems: [(title: String, subtitle: String)] = [
        ("Host", "Create & manage events with ease."),
        ("Partier", "Discover what’s happening near you."),
        ("Talent", "Offer services and book gigs.")
    ]
    
    init(prefilledEmail: String? = nil, startsFromEmailFlow: Bool = false) {
        _email = State(initialValue: prefilledEmail ?? "")
        self.startsFromEmailFlow = startsFromEmailFlow
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack {
                    Color.sioreeBlack.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        topBar(topInset: geo.safeAreaInsets.top)
                        
                        progressIndicator
                            .padding(.bottom, Theme.Spacing.l)
                        
                        // Form Content
                        ScrollView {
                            VStack(spacing: Theme.Spacing.l) {
                                Group {
                                    if currentStep == 1 {
                                        accountDetails
                                    } else {
                                        if currentStep == 2 {
                                            onboardingQuestions
                                        } else {
                                            roleSelection
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                                
                                if let validationMessage {
                                    Text(validationMessage)
                                        .font(.sioreeCaption)
                                        .foregroundColor(.red.opacity(0.9))
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.top, Theme.Spacing.m)
                            .padding(.bottom, Theme.Spacing.l)
                        }
                        .padding(.top, Theme.Spacing.s)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .safeAreaInset(edge: .bottom) {
                    if !isEditing {
                        HStack(spacing: Theme.Spacing.m) {
                            if currentStep < 3 {
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
                                    Button(action: handleNext) {
                                        Text("Next")
                                            .font(.sioreeBody)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                    }
                                    .buttonStyle(GlowingPillButtonStyle())
                                    .transition(.opacity)
                                }
                            } else {
                                VStack(spacing: Theme.Spacing.s) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color.sioreeIcyBlue))
                                            .frame(height: 44)
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Button(action: signUp) {
                                            Text("Sign Up")
                                                .font(.sioreeBody)
                                                .fontWeight(.semibold)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                        }
                                        .buttonStyle(GlowingPillButtonStyle())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.s)
                        .padding(.bottom, max(Theme.Spacing.m, geo.safeAreaInsets.bottom + Theme.Spacing.s))
                        .background(Color.sioreeBlack.opacity(0.92))
                        .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoading)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            hideKeyboard()
            isEditing = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isEditing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isEditing = false
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
        .sheet(isPresented: $showLoginSheet) {
            LoginView(initialEmail: email, showsSignUpLink: false) {
                showLoginSheet = false
            }
            .environmentObject(authViewModel)
        }
    }
    
    private func topBar(topInset: CGFloat) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.s) {
            Button {
                guard !authViewModel.isLoading else { return }
                if currentStep > 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.sioreeBody)
                .foregroundColor(.sioreeWhite)
                .padding(.vertical, 10)
            }
            
            Spacer()
        }
        .overlay {
            Text("Create Account")
                .font(.sioreeH1)
                .fontWeight(.bold)
                .foregroundColor(.sioreeWhite)
                .offset(y: -Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, topInset)
        .padding(.bottom, Theme.Spacing.s)
    }
    
    private var progressIndicator: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(1...3, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.sioreeIcyBlue : Color.sioreeCharcoal.opacity(0.55))
                    .frame(height: step <= currentStep ? 8 : 6)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
    
    private var accountDetails: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Account Details")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
                .padding(.bottom, Theme.Spacing.s)
            
            CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress) { focus in
                isEditing = focus
            }
            CustomTextField(placeholder: "Username", text: $username) { focus in
                isEditing = focus
            }
            CustomTextField(placeholder: "Password", text: $password, isSecure: true) { focus in
                isEditing = focus
            }
            CustomTextField(placeholder: "Full Name", text: $name) { focus in
                isEditing = focus
            }
        }
    }
    
    private var onboardingQuestions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("A few quick questions")
                .font(.sioreeH3)
                .foregroundColor(Color.sioreeWhite)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("What are you most interested in?")
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeLightGrey)
                
                questionOptions(
                    options: [
                        "Discover events",
                        "Host unforgettable nights",
                        "Offer talent or services"
                    ],
                    selection: $goalSelection
                )
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("Pick the vibe that fits you best")
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeLightGrey)
                
                questionOptions(
                    options: [
                        "House parties & nightlife",
                        "Ticketed events",
                        "Private bookings"
                    ],
                    selection: $vibeSelection
                )
            }
        }
    }
    
    private var roleSelection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Choose your permanent role")
                .font(.sioreeH3)
                .foregroundColor(.sioreeWhite)
            
            Text("This choice locks in your experience. To change later, you’ll need support to reset it.")
                .font(.sioreeBodySmall)
                .foregroundColor(.sioreeLightGrey)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.m),
                GridItem(.flexible(), spacing: Theme.Spacing.m)
            ], spacing: Theme.Spacing.m) {
                ForEach(UserRole.allCases) { role in
                    RoleCard(
                        role: role,
                        isSelected: selectedRole == role,
                        namespace: nil
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedRole = role
                            validationMessage = nil
                        }
                    }
                }
            }
            
            if selectedRole == .talent {
                CustomTextField(placeholder: "Location (City, State)", text: $location) { focus in
                    isEditing = focus
                }
            }
            
            TabView(selection: $guideSelection) {
                ForEach(Array(guideItems.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(item.title)
                            .font(.sioreeBody)
                            .fontWeight(.semibold)
                            .foregroundColor(.sioreeWhite)
                        Text(item.subtitle)
                            .font(.sioreeCaption)
                            .foregroundColor(.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                    .tag(index)
                }
            }
            .frame(height: 110)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }
    
    private func handleNext() {
        if currentStep == 1 && !validateAccountDetails() {
            return
        }
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
        guard let selectedRole else {
            validationMessage = "Please choose your role to continue."
            return
        }
        let roleType = UserType(rawValue: selectedRole.rawValue) ?? .partier
        let locationToSend = (roleType == .talent && !location.isEmpty) ? location : nil
        authViewModel.signUp(
            email: email,
            password: password,
            username: username,
            name: name,
            userType: roleType,
            location: locationToSend
        )
    }
    
    private func questionOptions(options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.sioreeBody)
                            .foregroundColor(selection.wrappedValue == option ? .sioreeWhite : .sioreeLightGrey)
                        Spacer()
                        if selection.wrappedValue == option {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.sioreeIcyBlue)
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(selection.wrappedValue == option ? Color.sioreeIcyBlue.opacity(0.12) : Color.sioreeLightGrey.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(selection.wrappedValue == option ? Color.sioreeIcyBlue.opacity(0.6) : Color.sioreeLightGrey.opacity(0.2), lineWidth: 1.2)
                    )
                }
            }
        }
    }
    
    private func validateAccountDetails() -> Bool {
        guard isValidEmail(email) else {
            validationMessage = "Enter a valid email to continue."
            return false
        }
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Please complete email, username, password, and name."
            return false
        }
        validationMessage = nil
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
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

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}

