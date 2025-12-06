//
//  SplashScreenView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct SplashScreenView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var gradientOffset: CGFloat = -1.0
    @State private var particleOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: [
                            Color.sioreeBlack,
                            Color.sioreeCharcoal.opacity(0.8),
                            Color.sioreeBlack
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Animated wave gradient
                    LinearGradient(
                        colors: [
                            Color.sioreeIcyBlue.opacity(0.15),
                            Color.sioreeWarmGlow.opacity(0.1),
                            Color.sioreeIcyBlue.opacity(0.15)
                        ],
                        startPoint: UnitPoint(x: 0.5 + gradientOffset, y: 0),
                        endPoint: UnitPoint(x: 0.5 - gradientOffset, y: 1)
                    )
                    .animation(
                        Animation.linear(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: gradientOffset
                    )
                }
                .ignoresSafeArea()
                
                // Particle effects
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.sioreeIcyBlue.opacity(0.3))
                        .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                        .offset(
                            x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                            y: CGFloat.random(in: -geometry.size.height/2...geometry.size.height/2) + particleOffset
                        )
                        .blur(radius: 2)
                }
                
                // Main content
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    
                    // Logo with glow effect
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.sioreeIcyBlue.opacity(glowIntensity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 80,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 360, height: 360)
                            .blur(radius: 30)
                        
                        // Logo - bigger size
                        LogoView(size: .large, isSpinning: false)
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(scale)
                            .opacity(logoOpacity)
                            .frame(width: 200, height: 200)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Phase 1: Logo spins in and scales up bigger (0.0 - 0.6s)
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.5  // Bigger scale - 1.5x instead of 1.0x
                logoOpacity = 1.0
            }
            
            // Continuous rotation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Glow pulse
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.6
            }
            
            // Particle animation
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                particleOffset = 1000
            }
            
            // Gradient wave animation
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                gradientOffset = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}


