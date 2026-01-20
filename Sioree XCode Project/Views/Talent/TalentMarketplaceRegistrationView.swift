//
//  TalentMarketplaceRegistrationView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentMarketplaceRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedCategory: TalentCategory?
    @State private var bio: String = ""
    @State private var priceMin: String = ""
    @State private var priceMax: String = ""
    @State private var isRegistering = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        categorySection
                        bioSection
                        priceRangeSection
                        registerButton
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Join Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .overlay {
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You've been added to the marketplace! Hosts can now find and book you.")
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Select Your Talent Type")
                .font(.sioreeH4)
                .foregroundColor(.sioreeWhite)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.s) {
                ForEach(TalentCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack {
                            Text(category.rawValue)
                                .font(.sioreeBody)
                                .foregroundColor(selectedCategory == category ? .sioreeWhite : .sioreeLightGrey)

                            Spacer()

                            if selectedCategory == category {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                            }
                        }
                        .padding(Theme.Spacing.m)
                        .background(
                            selectedCategory == category ?
                            Color.sioreeIcyBlue.opacity(0.2) :
                            Color.sioreeLightGrey.opacity(0.1)
                        )
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(
                                    selectedCategory == category ?
                                    Color.sioreeIcyBlue :
                                    Color.sioreeLightGrey.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Bio (Optional)")
                .font(.sioreeH4)
                .foregroundColor(.sioreeWhite)

            TextEditor(text: $bio)
                .frame(height: 120)
                .padding(Theme.Spacing.s)
                .background(Color.sioreeLightGrey.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.medium)
                .foregroundColor(.sioreeWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal, Theme.Spacing.m)
    }

    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Price Range (Optional)")
                .font(.sioreeH4)
                .foregroundColor(.sioreeWhite)

            HStack(spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Min Price")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)

                    TextField("$0", text: $priceMin)
                        .keyboardType(.decimalPad)
                        .padding(Theme.Spacing.s)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .foregroundColor(.sioreeWhite)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Max Price")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)

                    TextField("$0", text: $priceMax)
                        .keyboardType(.decimalPad)
                        .padding(Theme.Spacing.s)
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .foregroundColor(.sioreeWhite)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
    }

    private var registerButton: some View {
        Button(action: {
            registerTalent()
        }) {
            Text("Join Marketplace")
                .font(.sioreeBody)
                .foregroundColor(.sioreeWhite)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.m)
                .background(registerButtonBackground)
                .cornerRadius(Theme.CornerRadius.medium)
        }
        .padding(.horizontal, Theme.Spacing.m)
        .disabled(selectedCategory == nil || isRegistering)
        .opacity(selectedCategory == nil ? 0.6 : 1.0)
    }

    private var registerButtonBackground: LinearGradient {
        if selectedCategory != nil {
            return LinearGradient(
                colors: [Color.sioreeIcyBlue.opacity(0.8), Color.sioreeIcyBlue],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [Color.sioreeLightGrey.opacity(0.3), Color.sioreeLightGrey.opacity(0.3)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func registerTalent() {
        guard let category = selectedCategory else { return }
        errorMessage = ""

        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let minPriceText = priceMin.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxPriceText = priceMax.trimmingCharacters(in: .whitespacesAndNewlines)

        var minPrice: Double?
        var maxPrice: Double?

        if !minPriceText.isEmpty {
            guard let value = Double(minPriceText), value >= 0 else {
                errorMessage = "Please enter a valid minimum price."
                showError = true
                return
            }
            minPrice = value
        }

        if !maxPriceText.isEmpty {
            guard let value = Double(maxPriceText), value >= 0 else {
                errorMessage = "Please enter a valid maximum price."
                showError = true
                return
            }
            maxPrice = value
        }

        if let minPrice = minPrice, let maxPrice = maxPrice, maxPrice < minPrice {
            errorMessage = "Maximum price must be greater than or equal to minimum price."
            showError = true
            return
        }

        isRegistering = true

        networkService.registerTalent(
            category: category,
            bio: trimmedBio.isEmpty ? nil : trimmedBio,
            priceMin: minPrice,
            priceMax: maxPrice
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [self] completion in
                isRegistering = false
                if case .failure(let error) = completion {
                    errorMessage = "Failed to join marketplace: \(error.localizedDescription)"
                    showError = true
                }
            },
            receiveValue: { [self] _ in
                showSuccess = true
            }
        )
        .store(in: &cancellables)
    }
}

#Preview {
    TalentMarketplaceRegistrationView()
        .environmentObject(AuthViewModel())
}


