//
//  View+Extensions.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

extension View {
    // MARK: - Card Style
    func cardStyle() -> some View {
        self
            .background(Color.sioreeWhite)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: Theme.Shadows.subtle, radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Subtle Shadow
    func subtleShadow() -> some View {
        self.shadow(color: Theme.Shadows.subtle, radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Medium Shadow
    func mediumShadow() -> some View {
        self.shadow(color: Theme.Shadows.medium, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Elevated Shadow
    func elevatedShadow() -> some View {
        self.shadow(color: Theme.Shadows.elevated, radius: 16, x: 0, y: 4)
    }
    
    // MARK: - Hide Keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Dismiss Keyboard on Tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

