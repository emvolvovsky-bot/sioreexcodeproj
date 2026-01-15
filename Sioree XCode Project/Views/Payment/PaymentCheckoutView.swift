//
//  PaymentCheckoutView.swift
//  Sioree
//
//  Payment checkout placeholder - payments not implemented
//

import SwiftUI

struct PaymentCheckoutView: View {
    @Environment(\.dismiss) var dismiss
    
    let amount: Double
    let description: String
    let bookingId: String?
    let onPaymentSuccess: (Payment) -> Void
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                    VStack(spacing: Theme.Spacing.xl) {
                        // Amount Display
                        VStack(spacing: Theme.Spacing.s) {
                            Text("Total Amount")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("$\(String(format: "%.2f", amount))")
                                .font(.sioreeH1)
                                .foregroundColor(.sioreeWhite)
                            
                            if let description = description.isEmpty ? nil : description {
                                Text(description)
                                    .font(.sioreeBodySmall)
                                    .foregroundColor(.sioreeLightGrey)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, Theme.Spacing.xs)
                            }
                        }
                        .padding(Theme.Spacing.l)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .fill(Color.sioreeLightGrey.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.l)
                        
                        // Placeholder Payment Notice
                        VStack(alignment: .center, spacing: Theme.Spacing.m) {
                            Text("Payment Processing Not Available")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                                .multilineTextAlignment(.center)

                            Text("This feature is currently under development. Payment processing is not implemented.")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeLightGrey)
                                .multilineTextAlignment(.center)
                                }
                        .padding(Theme.Spacing.l)
                        .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .fill(Color.sioreeLightGrey.opacity(0.1))
                                )
                            .padding(.horizontal, Theme.Spacing.l)
                        
                        // Placeholder Pay Button
                            CustomButton(
                            title: "Payment Not Available",
                            variant: .secondary,
                                size: .large
                            ) {
                            showPaymentNotImplemented()
                        }
                        .disabled(true)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.l)
                    }
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeWhite)
                }
            }
            .alert("Payment Not Implemented", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        VStack(spacing: Theme.Spacing.m) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                                .scaleEffect(1.5)
                            
                            Text("Processing...")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeWhite)
                        }
                        .padding(Theme.Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                .fill(Color.sioreeCharcoal)
                        )
                    }
                }
            }
        }
    }
    
    private func showPaymentNotImplemented() {
        errorMessage = "Payment processing is not implemented. This feature is under development."
    }
}

