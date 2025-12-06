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
    
    func loadTalent() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchTalent(category: selectedCategory, searchQuery: searchQuery.isEmpty ? nil : searchQuery)
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
}

