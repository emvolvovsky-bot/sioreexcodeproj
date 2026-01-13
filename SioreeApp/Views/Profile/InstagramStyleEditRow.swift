//
//  InstagramStyleEditRow.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct InstagramStyleEditRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var isMultiline: Bool = false
    var maxCharacters: Int? = nil
    
    private var characterCount: Int {
        value.count
    }
    
    private var isOverLimit: Bool {
        if let max = maxCharacters {
            return characterCount > max
        }
        return false
    }
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: Theme.Spacing.m) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.sioreeWhite)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
                .frame(width: 20) // Add spacing between label and value
            
            if isMultiline {
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        if value.isEmpty {
                            Text(placeholder)
                                .font(.system(size: 16))
                                .foregroundColor(.sioreeLightGrey)
                                .padding(.top, 8)
                                .padding(.leading, 0)
                        }
                        TextEditor(text: Binding(
                            get: { value },
                            set: { newValue in
                                if let max = maxCharacters {
                                    if newValue.count <= max {
                                        value = newValue
                                    }
                                } else {
                                    value = newValue
                                }
                            }
                        ))
                        .font(.system(size: 16))
                        .foregroundColor(.sioreeWhite)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                    
                    if let max = maxCharacters {
                        HStack {
                            Spacer()
                            Text("\(characterCount)/\(max) characters")
                                .font(.system(size: 12))
                                .foregroundColor(isOverLimit ? .red : .sioreeLightGrey)
                        }
                    }
                }
            } else {
                TextField(placeholder, text: $value)
                    .font(.system(size: 16))
                    .foregroundColor(.sioreeWhite)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.m)
    }
}

#Preview {
    VStack(spacing: 0) {
        InstagramStyleEditRow(
            label: "Name",
            value: .constant("John Doe"),
            placeholder: "Enter your name"
        )
        
        Divider()
            .background(Color.sioreeLightGrey.opacity(0.2))
        
        InstagramStyleEditRow(
            label: "Bio",
            value: .constant(""),
            placeholder: "Write a bio",
            isMultiline: true
        )
    }
    .background(Color.sioreeBlack)
}

