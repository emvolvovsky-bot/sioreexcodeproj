//
//  CustomTextField.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var onFocusChange: ((Bool) -> Void)? = nil
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .foregroundColor(.sioreeWhite)
                    .accentColor(Color.sioreeIcyBlue)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                    .focused($isFocused)
                    .foregroundColor(.sioreeWhite)
                    .accentColor(Color.sioreeIcyBlue)
            }
        }
        .font(.sioreeBody)
        .padding(.vertical, Theme.Spacing.m + 2)
        .padding(.horizontal, Theme.Spacing.m)
        .background(Color.sioreeCharcoal.opacity(0.7))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(isFocused ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.22), lineWidth: 1.2)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        )
        .foregroundColor(.sioreeLightGrey)
        .accentColor(.sioreeIcyBlue)
        .onChange(of: isFocused) { _, newValue in
            onFocusChange?(newValue)
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.m) {
        CustomTextField(placeholder: "Email", text: .constant(""))
        CustomTextField(placeholder: "Password", text: .constant(""), isSecure: true)
    }
    .padding()
}

