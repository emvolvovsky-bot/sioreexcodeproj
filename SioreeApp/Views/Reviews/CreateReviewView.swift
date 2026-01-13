//
//  CreateReviewView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct CreateReviewView: View {
    let reviewedUserId: String
    let reviewedUserName: String
    let existingReview: Review?
    let onReviewSubmitted: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedRating: Int? = nil
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    private let networkService = NetworkService()
    
    init(reviewedUserId: String, reviewedUserName: String, existingReview: Review? = nil, onReviewSubmitted: @escaping () -> Void) {
        self.reviewedUserId = reviewedUserId
        self.reviewedUserName = reviewedUserName
        self.existingReview = existingReview
        self.onReviewSubmitted = onReviewSubmitted
        
        // Initialize with existing review if editing
        if let review = existingReview {
            _selectedRating = State(initialValue: review.rating)
            _comment = State(initialValue: review.comment)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(white: 0.98), Color(white: 0.95), Color(white: 0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header
                        VStack(spacing: Theme.Spacing.s) {
                            Text(existingReview != nil ? "Edit Review" : "Write a Review")
                                .font(.sioreeH2)
                                .foregroundColor(Color.sioreeCharcoal)
                            
                            Text("for \(reviewedUserName)")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeCharcoal.opacity(0.7))
                        }
                        .padding(.top, Theme.Spacing.l)
                        
                        // Rating Selection
                        VStack(spacing: Theme.Spacing.m) {
                            Text("Rating")
                                .font(.sioreeH4)
                                .foregroundColor(Color.sioreeCharcoal)
                            
                            StarRatingView(
                                rating: selectedRating ?? 0,
                                starSize: 40,
                                isEditable: true,
                                selectedRating: $selectedRating
                            )
                        }
                        .padding(Theme.Spacing.l)
                        .background(Color.sioreeWhite.opacity(0.5))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Comment Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text("Your Review")
                                .font(.sioreeH4)
                                .foregroundColor(Color.sioreeCharcoal)
                            
                            TextEditor(text: $comment)
                                .frame(minHeight: 150)
                                .padding(Theme.Spacing.s)
                                .background(Color.sioreeWhite)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeLightGrey.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.sioreeBody)
                                .foregroundColor(.red)
                                .padding(.horizontal, Theme.Spacing.m)
                        }
                        
                        // Submit Button
                        CustomButton(
                            title: existingReview != nil ? "Update Review" : "Submit Review",
                            variant: .primary,
                            size: .large
                        ) {
                            submitReview()
                        }
                        .disabled(selectedRating == nil || isSubmitting)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.l)
                    }
                }
            }
            .navigationTitle(existingReview != nil ? "Edit Review" : "Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReview() {
        guard let rating = selectedRating else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        networkService.createReview(
            reviewedUserId: reviewedUserId,
            rating: rating,
            comment: comment.isEmpty ? nil : comment
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                isSubmitting = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            },
            receiveValue: { _ in
                onReviewSubmitted()
            }
        )
        .store(in: &cancellables)
    }
}

#Preview {
    CreateReviewView(
        reviewedUserId: "user123",
        reviewedUserName: "John Doe",
        onReviewSubmitted: {}
    )
}

