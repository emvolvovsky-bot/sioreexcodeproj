//
//  Font+Extensions.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

extension Font {
    // MARK: - Headers (Bold, Helvetica Neue style)
    // Using system font with Helvetica Neue characteristics (SF Pro on iOS, which is similar)
    static let sioreeH1 = Font.system(size: 34, weight: .bold, design: .default)
    static let sioreeH2 = Font.system(size: 28, weight: .bold, design: .default)
    static let sioreeH3 = Font.system(size: 22, weight: .bold, design: .default)
    static let sioreeH4 = Font.system(size: 17, weight: .semibold, design: .default)
    
    // MARK: - Body (Light weight for clean, minimal feel)
    static let sioreeBodyLarge = Font.system(size: 17, weight: .light, design: .default)
    static let sioreeBody = Font.system(size: 15, weight: .light, design: .default)
    static let sioreeBodyBold = Font.system(size: 15, weight: .semibold, design: .default)
    static let sioreeBodySmall = Font.system(size: 13, weight: .light, design: .default)
    static let sioreeCaption = Font.system(size: 11, weight: .light, design: .default)
}

