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
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .foregroundStyle(Color.primary)
                    .accentColor(Color.sioreeIcyBlue)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                    .focused($isFocused)
                    .foregroundStyle(Color.primary)
                    .accentColor(Color.sioreeIcyBlue)
            }
        }
        .font(.sioreeBody)
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.3))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(isFocused ? Color.sioreeIcyBlue : Color.clear, lineWidth: 2)
        )
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

