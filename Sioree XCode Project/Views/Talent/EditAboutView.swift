//
//  EditAboutView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct EditAboutView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var aboutText: String
    @State private var editedText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section("About") {
                        TextEditor(text: $editedText)
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .frame(minHeight: 200)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeWhite)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        aboutText = editedText
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeIcyBlue)
                }
            }
            .onAppear {
                editedText = aboutText
            }
        }
    }
}

#Preview {
    EditAboutView(aboutText: .constant("Sample about text"))
}



