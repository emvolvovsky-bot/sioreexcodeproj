//
//  OnboardingView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import WebKit

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignupFlow = false
    @State private var showLoginFlow = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    
    private let backgroundImageName = "bluepartyphoto"
    private let termsURL = URL(string: "https://sioree.com/terms")!
    private let privacyURL = URL(string: "https://sioree.com/privacy")!
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Image(backgroundImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height * 0.66, alignment: .top)
                        .clipped()
                        .offset(y: geo.size.height * -0.005)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.26)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea(edges: .top)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: Theme.Spacing.l) {
                        VStack(spacing: Theme.Spacing.s) {
                            Text("Let’s get started")
                                .font(.sioreeH1)
                                .foregroundColor(.sioreeWhite)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 4)

                            Text("Sign up or log in\n to see what’s happening in Sioree.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey.opacity(0.92))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, Theme.Spacing.l)
                                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 3)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        VStack(spacing: Theme.Spacing.s) {
                            Button(action: { showSignupFlow = true }) {
                                Text("Sign Up with Email")
                                    .font(.sioreeBody)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryPillButtonStyle(shadowStrength: 0))
                            
                            Button(action: { showLoginFlow = true }) {
                                Text("Log In")
                                    .font(.sioreeBody)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, Theme.Spacing.m)
                            .background(
                                Capsule()
                                    .fill(Color.sioreeLightGrey.opacity(0.18))
                            )
                            .foregroundColor(.sioreeWhite)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        Spacer(minLength: geo.size.height * 0.04)
                        
                        VStack(spacing: 6) {
    Text("By continuing, you agree to")
        .font(.sioreeCaption)
        .foregroundColor(.sioreeLightGrey.opacity(0.9))
        .multilineTextAlignment(.center)

    HStack(spacing: 4) {
        Link("Terms of Service", destination: URL(string: "https://emvolvovsky-bot.github.io/sioreexcodeproj/terms.html")!)
            .font(.sioreeCaption)
            .foregroundColor(.sioreeIcyBlue)

        Text("and")
            .font(.sioreeCaption)
            .foregroundColor(.sioreeLightGrey.opacity(0.9))

        Link("Privacy Policy", destination: URL(string: "https://emvolvovsky-bot.github.io/sioreexcodeproj/privacy_policy.html")!)
            .font(.sioreeCaption)
            .foregroundColor(.sioreeIcyBlue)
    }
    .multilineTextAlignment(.center)
}

                        .padding(.bottom, max(Theme.Spacing.l * 3.0, geo.safeAreaInsets.bottom + Theme.Spacing.xl * 1.6))
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, -Theme.Spacing.xl)
                }
                
                ZStack(alignment: .bottom) {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.sioreeIcyBlue.opacity(0.32),
                            Color.black.opacity(0.26),
                            Color.clear
                        ]),
                        center: .bottom,
                        startRadius: 2,
                        endRadius: geo.size.height * 0.50
                    )
                    .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.46)
                    .offset(y: geo.size.height * 0.02)
                    
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.sioreeIcyBlue.opacity(0.28),
                            Color.black.opacity(0.18),
                            Color.clear
                        ]),
                        center: .bottom,
                        startRadius: 0,
                        endRadius: geo.size.height * 0.30
                    )
                    .frame(width: geo.size.width * 0.75, height: geo.size.height * 0.30)
                    .offset(y: geo.size.height * 0.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
            }
        }
        .fullScreenCover(isPresented: $showSignupFlow) {
            SignUpView(startsFromEmailFlow: true)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showLoginFlow) {
            LoginView(showsSignUpLink: false) {
                showLoginFlow = false
            }
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showTermsSheet) {
            WebViewModal(url: termsURL, title: "Terms of Service")
        }
        .sheet(isPresented: $showPrivacySheet) {
            WebViewModal(url: privacyURL, title: "Privacy Policy")
        }
    }
}

private struct PrimaryPillButtonStyle: ButtonStyle {
    var shadowStrength: Double = 0.45
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, Theme.Spacing.m)
            .background(
                Capsule()
                    .fill(Color.sioreeIcyBlue)
            )
            .foregroundColor(.sioreeWhite)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct WebViewModal: UIViewControllerRepresentable {
    let url: URL
    let title: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let webView = WKWebView(frame: .zero)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        let nav = UINavigationController(rootViewController: vc)
        vc.view = webView
        vc.navigationItem.title = title
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: context.coordinator, action: #selector(context.coordinator.dismiss))
        let request = URLRequest(url: url)
        webView.load(request)
        return nav
    }
    
    func updateUIViewController(_ controller: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator: NSObject {
        @objc func dismiss(_ sender: UIBarButtonItem) {
            sender.target?.perform(#selector(UIViewController.dismiss(animated:completion:)), with: true, with: nil)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}

