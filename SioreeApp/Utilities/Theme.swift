//
//  Theme.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors (from Asset Catalog)
        static let white = Color("sioreeWhite")
        static let lightGrey = Color("sioreeLightGrey")
        static let charcoal = Color("sioreeCharcoal")
        static let black = Color("sioreeBlack")
        
        // Accent Colors (from Asset Catalog)
        static let icyBlue = Color("sioreeIcyBlue")
        static let warmGlow = Color("sioreeWarmGlow")
        
        // Semantic colors
        static let success = Color.green.opacity(0.7)
        static let error = Color.red.opacity(0.7)
        static let warning = Color.orange.opacity(0.7)
        static let info = icyBlue
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Border Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let subtle = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.08)
        static let elevated = Color.black.opacity(0.12)
    }
}

// MARK: - Color Extension
extension Color {
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Semantic Colors
    // Note: Primary and accent colors (sioreeWhite, sioreeLightGrey, etc.) are auto-generated
    // by Xcode from the Asset Catalog, so we don't redeclare them here.
    static let sioreeSuccess = Theme.Colors.success
    static let sioreeError = Theme.Colors.error
    static let sioreeWarning = Theme.Colors.warning
    static let sioreeInfo = Theme.Colors.info
}
