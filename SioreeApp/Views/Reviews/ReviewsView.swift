//
//  ReviewsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct ReviewsView: View {
    let userId: String
    let userName: String
    @StateObject private var viewModel: ReviewsViewModel
    @State private var showCreateReview = false
    @State private var actualUserName: String?
    
    init(userId: String, userName: String = "User") {
        self.userId = userId
        self.userName = userName
        _viewModel = StateObject(wrappedValue: ReviewsViewModel(userId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                // Header with average rating
                if let averageRating = viewModel.averageRating, viewModel.reviewCount > 0 {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                            Text(String(format: "%.1f", averageRating))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color.sioreeCharcoal)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                StarRatingView(rating: Int(averageRating.rounded()), starSize: 20)
                                Text("\(viewModel.reviewCount) \(viewModel.reviewCount == 1 ? "review" : "reviews")")
                                    .font(.sioreeCaption)
                                    .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
                            }
                        }
                    }
                    .padding(Theme.Spacing.l)
                    .background(Color.sioreeWhite.opacity(0.05))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, Theme.Spacing.m)
                }
                
                // Reviews List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxl)
                } else if viewModel.reviews.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "star")
                            .font(.system(size: 60))
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                        Text("No reviews yet")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeCharcoal)
                        Text("Be the first to review \(actualUserName ?? userName)")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeCharcoal.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xxl)
                } else {
                    LazyVStack(spacing: Theme.Spacing.m) {
                        ForEach(viewModel.reviews) { review in
                            ReviewCard(review: review)
                                .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.m)
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCreateReview = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
        .sheet(isPresented: $showCreateReview) {
            CreateReviewView(
                reviewedUserId: userId,
                reviewedUserName: actualUserName ?? userName,
                existingReview: viewModel.userReview,
                onReviewSubmitted: {
                    viewModel.loadReviews()
                    showCreateReview = false
                }
            )
        }
        .onAppear {
            viewModel.loadReviews()
            // Fetch user name if not provided
            if userName == "User" || userName == "Talent" {
                fetchUserName()
            }
        }
    }
    
    private func fetchUserName() {
        let networkService = NetworkService()
        var cancellable: AnyCancellable?
        cancellable = networkService.fetchUserProfile(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    cancellable?.cancel()
                },
                receiveValue: { user in
                    actualUserName = user.name
                    cancellable?.cancel()
                }
            )
    }
}

class ReviewsViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var averageRating: Double?
    @Published var reviewCount: Int = 0
    @Published var userReview: Review?
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    private let userId: String
    
    deinit {
        cancellables.removeAll()
    }
    
    init(userId: String) {
        self.userId = userId
    }
    
    func loadReviews() {
        isLoading = true
        
        networkService.fetchReviews(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load reviews: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] reviews in
                    self?.reviews = reviews
                    self?.reviewCount = reviews.count
                    
                    // Calculate average rating
                    if !reviews.isEmpty {
                        let sum = reviews.reduce(0) { $0 + $1.rating }
                        self?.averageRating = Double(sum) / Double(reviews.count)
                    } else {
                        self?.averageRating = nil
                    }
                    
                    // Check if current user has a review
                    if let currentUserId = StorageService.shared.getUserId() {
                        self?.userReview = reviews.first { $0.reviewerId == currentUserId }
                    }
                }
            )
            .store(in: &cancellables)
    }
}

