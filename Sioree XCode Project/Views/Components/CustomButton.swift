//
//  CustomButton.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

enum ButtonVariant {
    case primary
    case secondary
    case tertiary
}

enum ButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }
    
    var fontSize: Font {
        switch self {
        case .small: return .sioreeBodySmall
        case .medium: return .sioreeBody
        case .large: return .sioreeBodyLarge
        }
    }
}

struct CustomButton: View {
    let title: String
    let variant: ButtonVariant
    let size: ButtonSize
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.fontSize)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: size.height)
                .background(backgroundColor)
                .cornerRadius(Theme.CornerRadius.medium)
                .opacity(isDisabled ? 0.5 : (isPressed ? 0.8 : 1.0))
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return Color.sioreeIcyBlue
        case .secondary:
            return Color.clear
        case .tertiary:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch variant {
        case .primary:
            return Color.sioreeWhite
        case .secondary:
            return Color.sioreeIcyBlue
        case .tertiary:
            return Color.sioreeCharcoal
        }
    }
    
    private var isDisabled: Bool {
        // Add disabled state logic if needed
        return false
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.m) {
        CustomButton(title: "Primary Button", variant: .primary, size: .large) {}
        CustomButton(title: "Secondary Button", variant: .secondary, size: .medium) {}
        CustomButton(title: "Tertiary Button", variant: .tertiary, size: .small) {}
    }
    .padding()
}

