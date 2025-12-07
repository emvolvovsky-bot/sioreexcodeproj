//
//  RoleSelectionView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct RoleSelectionView: View {
    @Binding var selectedRole: UserRole?
    var isChangingRole: Bool = false
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
            
            VStack(spacing: Theme.Spacing.s) {
                // Logo - much bigger at the top
                VStack(spacing: Theme.Spacing.m) {
                    LogoView(size: .large)
                        .frame(width: 360, height: 360)
                }
                .padding(.top, Theme.Spacing.l)
                
                // Title - moved up closer to logo
                VStack(spacing: Theme.Spacing.xs) {
                    Text(isChangingRole ? "Feeling different?" : "Choose how you use Sioree")
                        .font(.sioreeH2)
                        .foregroundColor(Color.sioreeWhite)
                        .multilineTextAlignment(.center)
                    
                    if isChangingRole {
                        Text("Switch to a different role")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                }
                .padding(.top, Theme.Spacing.xs)
                
                // Role cards grid - moved up even more
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.m) {
                    ForEach(UserRole.allCases) { role in
                        RoleCard(role: role) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedRole = role
                            }
                            if isChangingRole {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)
                
                Spacer()
            }
        }
    }
}

struct RoleCard: View {
    let role: UserRole
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: role.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(Color.sioreeIcyBlue)
                
                Text(role.displayName)
                    .font(.sioreeH4)
                    .foregroundColor(Color.sioreeWhite)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.sioreeLightGrey.opacity(0.2))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

#Preview {
    RoleSelectionView(selectedRole: .constant(nil))
}

