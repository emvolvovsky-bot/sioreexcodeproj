//
//  BrandInsightsViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

struct BrandInsights: Codable {
    let totalImpressions: Int
    let citiesActivated: Int
    let avgCostPerAttendee: Double?
    let campaignROI: Double?
    let engagementRate: Double?
}

class BrandInsightsViewModel: ObservableObject {
    @Published var totalImpressions: String = "N/A"
    @Published var citiesActivated: String = "N/A"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadInsights() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchBrandInsights()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        // On error, keep values as "N/A"
                    }
                },
                receiveValue: { [weak self] insights in
                    self?.totalImpressions = insights.totalImpressions > 0 ? "\(insights.totalImpressions)" : "N/A"
                    self?.citiesActivated = insights.citiesActivated > 0 ? "\(insights.citiesActivated)" : "N/A"
                }
            )
            .store(in: &cancellables)
    }
}








