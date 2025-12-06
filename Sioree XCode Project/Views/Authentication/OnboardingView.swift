//
//  OnboardingView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showLogin = false
    
    let pages = [
        OnboardingPage(
            title: "Welcome to Sioree",
            description: "Professionalize and scale nightlife from the inside out",
            imageName: "sparkles"
        ),
        OnboardingPage(
            title: "Connect & Discover",
            description: "Find real experiences from people you actually know",
            imageName: "person.2.fill"
        ),
        OnboardingPage(
            title: "Book Talent",
            description: "Find DJs, bartenders, and staff all in one place",
            imageName: "music.note"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], isFirstPage: index == 0)
                            .tag(index)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut(duration: 0.4), value: currentPage)
                
                // Bottom Actions
                VStack(spacing: Theme.Spacing.m) {
                    if currentPage == pages.count - 1 {
                        CustomButton(title: "Get Started", variant: .primary, size: .large) {
                            showLogin = true
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                    } else {
                        HStack {
                            Spacer()
                            Button("Skip") {
                                showLogin = true
                            }
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                    }
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
                .environmentObject(AuthViewModel())
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isFirstPage: Bool
    
    init(page: OnboardingPage, isFirstPage: Bool = false) {
        self.page = page
        self.isFirstPage = isFirstPage
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            if isFirstPage {
                LogoView(size: .large, isSpinning: false)
            } else {
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(Color.sioreeIcyBlue)
            }
            
            VStack(spacing: Theme.Spacing.m) {
                Text(page.title)
                    .font(.sioreeH1)
                    .foregroundColor(Color.sioreeWhite)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }
}

#Preview {
    OnboardingView()
}

