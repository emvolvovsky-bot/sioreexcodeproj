//
//  BookingViewModel.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import SwiftUI
import Combine

class BookingViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadBookings() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchBookings()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] bookings in
                    self?.bookings = bookings
                }
            )
            .store(in: &cancellables)
    }
    
    func createBooking(talentId: String, eventId: String?, date: Date, time: Date, duration: Int, price: Double, notes: String?) {
        isLoading = true
        errorMessage = nil
        
        networkService.createBooking(talentId: talentId, eventId: eventId, date: date, time: time, duration: duration, price: price, notes: notes)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] booking in
                    self?.bookings.append(booking)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateBookingStatus(bookingId: String, status: BookingStatus) {
        if let index = bookings.firstIndex(where: { $0.id == bookingId }) {
            bookings[index].status = status
        }
        
        networkService.updateBookingStatus(bookingId: bookingId, status: status)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Revert change
                        if let index = self?.bookings.firstIndex(where: { $0.id == bookingId }) {
                            // Revert to previous status - would need to track previous state
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

