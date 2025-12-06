//
//  TalentDetailView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentDetailView: View {
    let talent: TalentListing
    @Environment(\.dismiss) var dismiss
    @State private var showMessageView = false
    @State private var showBookingView = false
    @State private var showPaymentCheckout = false
    @State private var showProfile = false
    @State private var selectedConversation: Conversation?
    @State private var bookingPrice: Double?
    
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
                        // Header
                        VStack(spacing: Theme.Spacing.m) {
                            ZStack {
                                Circle()
                                    .fill(Color.sioreeLightGrey.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: talent.imageName)
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.sioreeIcyBlue)
                            }
                            
                            Text(talent.name)
                                .font(.sioreeH1)
                                .foregroundColor(Color.sioreeWhite)
                            
                            Text(talent.roleText)
                                .font(.sioreeH4)
                                .foregroundColor(Color.sioreeLightGrey)
                            
                            HStack(spacing: Theme.Spacing.s) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.sioreeWarmGlow)
                                
                                Text(String(format: "%.1f", talent.rating))
                                    .font(.sioreeH4)
                                    .foregroundColor(Color.sioreeWhite)
                                
                                Text("(24 reviews)")
                                    .font(.sioreeBodySmall)
                                    .foregroundColor(Color.sioreeLightGrey)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.l)
                        
                        // Info Cards
                        VStack(spacing: Theme.Spacing.m) {
                            InfoCard(icon: "dollarsign.circle.fill", title: "Rate", value: talent.rateText)
                            InfoCard(icon: "location.fill", title: "Location", value: talent.location)
                            InfoCard(icon: "clock.fill", title: "Response Time", value: "Usually responds within 2 hours")
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("About")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            
                            Text("Experienced \(talent.roleText.lowercased()) with a passion for creating unforgettable experiences. Specializes in \(talent.roleText == "DJ" ? "electronic music and seamless transitions" : "craft cocktails and exceptional service"). Available for events of all sizes.")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Reviews Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Recent Reviews")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            
                            TalentReviewRow(reviewer: "LindaFlora", rating: 5, comment: "Amazing performance! Everyone loved it.")
                            TalentReviewRow(reviewer: "Skyline Events", rating: 5, comment: "Professional and reliable. Highly recommend!")
                            TalentReviewRow(reviewer: "Midnight Collective", rating: 4, comment: "Great energy and perfect music selection.")
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Action Buttons
                        VStack(spacing: Theme.Spacing.m) {
                            // View Profile Button
                            NavigationLink(destination: UserProfileView(userId: talent.id)) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                    Text("View Profile")
                                        .font(.sioreeBody)
                                }
                                .foregroundColor(Color.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeLightGrey.opacity(0.2))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                                )
                            }
                            
                            Button(action: {
                                startConversation()
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Message")
                                        .font(.sioreeBody)
                                }
                                .foregroundColor(Color.sioreeWhite)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue)
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                            
                            Button(action: {
                                showBookingView = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Book Now")
                                        .font(.sioreeBody)
                                }
                                .foregroundColor(Color.sioreeIcyBlue)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.m)
                                .background(Color.sioreeIcyBlue.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue, lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Talent Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .sheet(item: $selectedConversation) { conversation in
                RealMessageView(conversation: conversation)
            }
            .sheet(isPresented: $showBookingView) {
                BookTalentView(talent: talent) { bookingPrice in
                    self.bookingPrice = bookingPrice
                    showBookingView = false
                    showPaymentCheckout = true
                }
            }
            .sheet(isPresented: $showPaymentCheckout) {
                if let price = bookingPrice ?? extractPrice(from: talent.rateText) {
                    PaymentCheckoutView(
                        amount: price,
                        description: "Booking \(talent.name) - \(talent.roleText)",
                        bookingId: nil,
                        onPaymentSuccess: { payment in
                            showPaymentCheckout = false
                            // Create booking after payment
                            createBooking(price: price)
                        }
                    )
                }
            }
        }
    }
    
    private func extractPrice(from rateText: String) -> Double? {
        // Extract price from rate text like "$500/night" or "$100/hour"
        let numbers = rateText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers)
    }
    
    private func startConversation() {
        MessagingService.shared.getOrCreateConversation(with: talent.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to create conversation: \(error)")
                    }
                },
                receiveValue: { conversation in
                    selectedConversation = conversation
                }
            )
            .store(in: &cancellables)
    }
    
    private func createBooking(price: Double) {
        // Create booking after successful payment
        // This would typically be called from the booking view with date/time
        print("✅ Payment successful, booking created for \(talent.name) at $\(price)")
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.sioreeIcyBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.sioreeBodySmall)
                    .foregroundColor(Color.sioreeLightGrey)
                
                Text(value)
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeWhite)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

struct TalentReviewRow: View {
    let reviewer: String
    let rating: Int
    let comment: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(reviewer)
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeWhite)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(index < rating ? Color.sioreeWarmGlow : Color.sioreeLightGrey.opacity(0.3))
                    }
                }
            }
            
            Text(comment)
                .font(.sioreeBodySmall)
                .foregroundColor(Color.sioreeLightGrey)
                .lineSpacing(2)
        }
        .padding(Theme.Spacing.m)
        .background(Color.sioreeLightGrey.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Book Talent View
struct BookTalentView: View {
    let talent: TalentListing
    let onConfirm: (Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var duration = 4
    @State private var notes = ""
    
    private var totalPrice: Double {
        // Extract hourly rate from talent.rateText
        let hourlyRate = extractHourlyRate(from: talent.rateText) ?? 100.0
        return hourlyRate * Double(duration)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Talent Info
                        VStack(spacing: Theme.Spacing.s) {
                            Text(talent.name)
                                .font(.sioreeH2)
                                .foregroundColor(.sioreeWhite)
                            
                            Text(talent.roleText)
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.top, Theme.Spacing.l)
                        
                        // Booking Details
                        VStack(spacing: Theme.Spacing.m) {
                            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                                .foregroundColor(.sioreeWhite)
                            
                            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .foregroundColor(.sioreeWhite)
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Duration (hours)")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                                
                                Stepper("\(duration) hours", value: $duration, in: 1...12)
                                    .foregroundColor(.sioreeWhite)
                            }
                            
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Notes (optional)")
                                    .font(.sioreeBody)
                                    .foregroundColor(.sioreeWhite)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                    .cornerRadius(Theme.CornerRadius.medium)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        
                        // Price Summary
                        VStack(spacing: Theme.Spacing.s) {
                            HStack {
                                Text("Total")
                                    .font(.sioreeH3)
                                    .foregroundColor(.sioreeWhite)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", totalPrice))")
                                    .font(.sioreeH2)
                                    .foregroundColor(.sioreeIcyBlue)
                            }
                            .padding(Theme.Spacing.l)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .fill(Color.sioreeLightGrey.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, Theme.Spacing.l)
                            
                            CustomButton(
                                title: "Continue to Payment",
                                variant: .primary,
                                size: .large
                            ) {
                                onConfirm(totalPrice)
                            }
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                        .padding(.top, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Book Talent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeWhite)
                }
            }
        }
    }
    
    private func extractHourlyRate(from rateText: String) -> Double? {
        // Extract hourly rate from text like "$100/hour" or "$500/night"
        if rateText.contains("/hour") {
            let numbers = rateText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Double(numbers)
        } else if rateText.contains("/night") {
            let numbers = rateText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Double(numbers) ?? 500.0 // Default to $500/night
        }
        return 100.0 // Default hourly rate
    }
}

#Preview {
    TalentDetailView(talent: MockData.sampleTalent[0])
}

