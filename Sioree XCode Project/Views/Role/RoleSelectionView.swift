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
    @Namespace private var roleNamespace
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack {
                Spacer()
                VStack(spacing: Theme.Spacing.l) {
                    Capsule()
                        .fill(Color.sioreeLightGrey.opacity(0.4))
                        .frame(width: 44, height: 5)
                        .padding(.top, Theme.Spacing.s)
                    
                    // Top bar
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Choose your mode")
                                .font(.sioreeH2)
                                .foregroundColor(.sioreeWhite)
                            Text(isChangingRole ? "Switch roles anytime." : "Pick how you want to party.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    
                    // Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Theme.Spacing.m),
                        GridItem(.flexible(), spacing: Theme.Spacing.m)
                    ], spacing: Theme.Spacing.m) {
                        ForEach(UserRole.allCases) { role in
                            RoleCard(
                                role: role,
                                isSelected: selectedRole == role,
                                namespace: roleNamespace
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedRole = role
                                }
                                if isChangingRole {
                                    dismiss()
                                }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                                    removal: .opacity))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.l)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: -6)
                )
                .transition(.move(edge: .bottom))
            }
            .animation(.easeInOut(duration: 0.28), value: selectedRole)
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
    }
}

struct RoleCard: View {
    let role: UserRole
    var isSelected: Bool = false
    var namespace: Namespace.ID?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.sioreeIcyBlue.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: role.iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                    Spacer()
                    if isSelected {
                        if let namespace {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.sioreeIcyBlue)
                                .matchedGeometryEffect(id: "check\(role.rawValue)", in: namespace, isSource: false)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.sioreeIcyBlue)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.sioreeH4)
                        .foregroundColor(.sioreeWhite)
                    Text(roleTagline(role))
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                        .lineLimit(2)
                }
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                LinearGradient(
                    colors: isSelected
                    ? [Color.sioreeIcyBlue.opacity(0.2), Color.sioreeBlack.opacity(0.6)]
                    : [Color.sioreeBlack.opacity(0.7), Color.sioreeCharcoal.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.sioreeIcyBlue.opacity(isSelected ? 0.7 : 0.25), lineWidth: isSelected ? 2.5 : 1.2)
            )
            .cornerRadius(Theme.CornerRadius.large)
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 10)
        }
    }
    
    private func roleTagline(_ role: UserRole) -> String {
        switch role {
        case .partier: return "Discover and share the best nights out."
        case .host: return "Manage events, guests, and promotions."
        case .talent: return "Book gigs, grow your portfolio."
        }
    }
}

#Preview {
    RoleSelectionView(selectedRole: .constant(nil))
}

