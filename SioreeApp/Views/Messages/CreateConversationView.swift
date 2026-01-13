//
//  CreateConversationView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct CreateConversationView: View {
    let userId: String
    let userName: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversation: Conversation?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let conversation = conversation {
                    RealMessageView(conversation: conversation)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                } else {
                    VStack(spacing: Theme.Spacing.m) {
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle(userName)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                createOrGetConversation()
            }
        }
    }
    
    private func createOrGetConversation() {
        isLoading = true
        errorMessage = nil
        
        messagingService.getOrCreateConversation(with: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        print("❌ Failed to create conversation: \(error)")
                    }
                },
                receiveValue: { conv in
                    isLoading = false
                    conversation = conv
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    CreateConversationView(userId: "test-id", userName: "Test User")
}

