//
//  CreateView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct CreateView: View {
    @State private var showEventCreation = false
    @State private var showPostCreation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    
                    VStack(spacing: Theme.Spacing.l) {
                        Button(action: {
                            showEventCreation = true
                        }) {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.sioreeIcyBlue)
                                
                                Text("Create Event")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .background(Color.sioreeLightGrey.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        
                        Button(action: {
                            showPostCreation = true
                        }) {
                            VStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.sioreeIcyBlue)
                                
                                Text("Create Post")
                                    .font(.sioreeH3)
                                    .foregroundColor(Color.sioreeWhite)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .background(Color.sioreeLightGrey.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                    }
                    .padding(Theme.Spacing.l)
                    
                    Spacer()
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEventCreation) {
                EventCreateView()
            }
            .sheet(isPresented: $showPostCreation) {
                Text("Post Creation View")
                    .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    CreateView()
}

