//
//  TalentEarningsViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class TalentEarningsViewModel: ObservableObject {
    static let shared = TalentEarningsViewModel()
    
    @Published var earningsThisMonth: Int = 0
    @Published var totalEarnings: Int = 0
    @Published var earningsHistory: [Earning] = []
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadEarnings()
    }
    
    func loadEarnings() {
        // For now, use placeholder data
        // In production, fetch from backend: /api/talent/earnings
        earningsThisMonth = 0
        totalEarnings = 0
        earningsHistory = []
        
        // TODO: Implement backend endpoint to fetch earnings
        // networkService.fetchTalentEarnings()
        //     .receive(on: DispatchQueue.main)
        //     .sink(...)
    }
    
    func addEarning(amount: Double, eventId: String, eventTitle: String) {
        // Add earning when talent gets paid
        let earning = Earning(
            id: UUID().uuidString,
            amount: amount,
            eventId: eventId,
            eventTitle: eventTitle,
            date: Date()
        )
        
        earningsHistory.append(earning)
        
        // Update totals
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        earningsThisMonth = Int(earningsHistory
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount })
        
        totalEarnings = Int(earningsHistory.reduce(0) { $0 + $1.amount })
    }
}

struct Earning: Identifiable {
    let id: String
    let amount: Double
    let eventId: String
    let eventTitle: String
    let date: Date
}

