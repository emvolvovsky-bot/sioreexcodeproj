//
//  GigDetailView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct GigDetailView: View {
    let gig: Gig
    @Environment(\.dismiss) var dismiss
    @State private var showHostProfile = false
    @State private var showMessageView = false
    
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
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        // Event Name
                        Text(gig.eventName)
                            .font(.sioreeH1)
                            .foregroundColor(.sioreeWhite)
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        // Host Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Host")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            HStack(spacing: Theme.Spacing.m) {
                                // Host Avatar
                                Circle()
                                    .fill(Color.sioreeLightGrey.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.sioreeIcyBlue)
                                    )
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text(gig.hostName)
                                        .font(.sioreeH4)
                                        .foregroundColor(.sioreeWhite)
                                    
                                    Text("Event Host")
                                        .font(.sioreeBodySmall)
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                
                                Spacer()
                            }
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeLightGrey.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.medium)
                            
                            // Host Actions
                            HStack(spacing: Theme.Spacing.m) {
                                Button(action: {
                                    showHostProfile = true
                                }) {
                                    HStack {
                                        Image(systemName: "person.circle")
                                        Text("View Profile")
                                    }
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue.opacity(0.2))
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                    )
                                }
                                
                                Button(action: {
                                    showMessageView = true
                                }) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                        Text("Message")
                                    }
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.m)
                                    .background(Color.sioreeIcyBlue)
                                    .cornerRadius(Theme.CornerRadius.medium)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        Divider()
                            .background(Color.sioreeLightGrey.opacity(0.3))
                            .padding(.horizontal, Theme.Spacing.m)
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Event Details")
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            
                            // Date & Time
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Date & Time")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                    Text(gig.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                }
                            }
                            
                            // Rate
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Rate")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                    Text(gig.rate)
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                }
                            }
                            
                            // Status
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Status")
                                        .font(.sioreeCaption)
                                        .foregroundColor(.sioreeLightGrey)
                                    StatusChip(status: gig.status)
                                }
                            }
                        }
                        .padding(Theme.Spacing.m)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Gig Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .sheet(isPresented: $showHostProfile) {
                NavigationStack {
                    // TODO: Fetch host user ID from gig and show UserProfileView
                    Text("Host Profile: \(gig.hostName)")
                        .navigationTitle("Host Profile")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showHostProfile = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showMessageView) {
                NavigationStack {
                    // TODO: Create conversation with host and show RealMessageView
                    Text("Message Host: \(gig.hostName)")
                        .navigationTitle("Message Host")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showMessageView = false
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    GigDetailView(gig: Gig(
        eventName: "Halloween Mansion Party",
        hostName: "LindaFlora",
        date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        rate: "$500",
        status: .confirmed
    ))
}

