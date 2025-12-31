//
//  TalentMessageHostView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentMessageHostView: View {
    let gig: Gig
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var messageText = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var conversationId: String?

    private let messagingService = MessagingService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sioreeBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: Theme.Spacing.s) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("Message Host")
                                    .font(.sioreeH2)
                                    .foregroundColor(.white)

                                Text(gig.eventName)
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            }

                            Spacer()

                            // Placeholder for symmetry
                            Color.clear.frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.top, Theme.Spacing.l)
                    .background(Color.sioreeBlack.opacity(0.8))

                    // Message composer
                    VStack(spacing: Theme.Spacing.m) {
                        // Host info
                        HStack(spacing: Theme.Spacing.m) {
                            ZStack {
                                Circle()
                                    .fill(Color.sioreeCharcoal.opacity(0.3))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "person.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.system(size: 20))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("To: \(gig.hostName)")
                                    .font(.sioreeH4)
                                    .foregroundColor(.white)

                                Text("About: \(gig.eventName)")
                                    .font(.sioreeCaption)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.sioreeCharcoal.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal, Theme.Spacing.m)

                        // Message input
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Message")
                                .font(.sioreeH4)
                                .foregroundColor(.white)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.sioreeCharcoal.opacity(0.3))
                                    .frame(height: 120)

                                TextEditor(text: $messageText)
                                    .font(.sioreeBody)
                                    .foregroundColor(.white)
                                    .padding(Theme.Spacing.m)
                                    .frame(height: 120)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)

                                if messageText.isEmpty {
                                    Text("Write your message to the host...")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeCharcoal.opacity(0.5))
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .padding(.vertical, Theme.Spacing.l)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)

                        if let error = errorMessage {
                            Text(error)
                                .font(.sioreeCaption)
                                .foregroundColor(.red)
                                .padding(.horizontal, Theme.Spacing.m)
                        }

                        Spacer()

                        // Send button
                        VStack(spacing: Theme.Spacing.m) {
                            CustomButton(
                                title: isSending ? "Sending..." : "Send Message",
                                variant: .primary,
                                size: .large
                            ) {
                                sendMessage()
                            }
                            .disabled(isSending || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button(action: { dismiss() }) {
                                Text("Cancel")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeCharcoal.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.l)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func sendMessage() {
        guard let currentUser = authViewModel.currentUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a message"
            return
        }

        isSending = true
        errorMessage = nil

        // For now, we'll simulate sending a message
        // In a real implementation, you'd get the host's user ID and send via messaging service

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSending = false
            dismiss()
            // In a real app, you'd show a success message or navigate to the conversation
        }
    }
}

struct TalentMessageHostView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleGig = Gig(
            eventName: "Summer Music Festival",
            hostName: "Festival Productions",
            date: Date(),
            rate: "$500",
            status: .confirmed
        )

        TalentMessageHostView(gig: sampleGig, authViewModel: AuthViewModel())
    }
}
