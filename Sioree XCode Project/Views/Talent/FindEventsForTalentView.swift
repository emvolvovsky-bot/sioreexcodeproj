//
//  FindEventsForTalentView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct FindEventsForTalentView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTalentType: String
    // Use TalentCategory enum for consistency
    private var talentTypes: [String] {
        TalentCategory.allCases.map { $0.rawValue }
    }
    
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
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        Text("Find events that might need")
                            .font(.sioreeH3)
                            .foregroundColor(.sioreeWhite)
                            .padding(.top, Theme.Spacing.m)
                        
                        VStack(spacing: Theme.Spacing.m) {
                            ForEach(talentTypes, id: \.self) { type in
                                Button(action: {
                                    selectedTalentType = type
                                }) {
                                    HStack {
                                        Text(type)
                                            .font(.sioreeBody)
                                            .foregroundColor(.sioreeWhite)
                                        
                                        Spacer()
                                        
                                        if selectedTalentType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.sioreeIcyBlue)
                                        } else {
                                            Circle()
                                                .stroke(Color.sioreeWhite, lineWidth: 2)
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(selectedTalentType == type ? Color.sioreeIcyBlue : Color.sioreeLightGrey.opacity(0.3), lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        Button(action: {
                            print("Finding events for \(selectedTalentType)")
                            // Navigate to gigs view which will show results
                            dismiss()
                        }) {
                            Text("Find Events")
                                .font(.sioreeBody)
                                .fontWeight(.semibold)
                                .foregroundColor(.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Find Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
    }
}

#Preview {
    FindEventsForTalentView(selectedTalentType: .constant("DJ"))
}



