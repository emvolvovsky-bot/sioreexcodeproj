//
//  TalentViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class TalentViewModel: ObservableObject {
    @Published var talent: [Talent] = []
    @Published var selectedTalent: Talent?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: TalentCategory?
    @Published var searchQuery: String = ""
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTalent()
    }
    
    func loadTalent(availableOnly: Bool = true) {
        isLoading = true
        errorMessage = nil

        networkService.fetchTalent(category: selectedCategory, searchQuery: searchQuery.isEmpty ? nil : searchQuery, availableOnly: availableOnly)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] talent in
                    self?.talent = talent
                }
            )
            .store(in: &cancellables)
    }
    
    func loadTalentProfile(talentId: String) {
        isLoading = true
        
        networkService.fetchTalentProfile(talentId: talentId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] talent in
                    self?.selectedTalent = talent
                }
            )
            .store(in: &cancellables)
    }
    
    func filterByCategory(_ category: TalentCategory?) {
        selectedCategory = category
        loadTalent()
    }
    
    func search(_ query: String) {
        searchQuery = query
        loadTalent()
    }

    func updateAvailability(talentId: String, isAvailable: Bool) {
        // Update local talent data
        if let index = talent.firstIndex(where: { $0.id == talentId }) {
            talent[index].isAvailable = isAvailable
        }

        // Call API to update availability status
        networkService.updateTalentAvailability(talentId: talentId, isAvailable: isAvailable)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to update availability: \(error)")
                        // Revert local change on failure
                        if let index = self.talent.firstIndex(where: { $0.id == talentId }) {
                            self.talent[index].isAvailable = !isAvailable
                        }
                    }
                },
                receiveValue: { _ in
                    print("Successfully updated availability for talent \(talentId)")
                }
            )
            .store(in: &cancellables)
    }
}

