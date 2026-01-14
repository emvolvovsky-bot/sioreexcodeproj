//
//  PaymentMethodsView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine
// import StripePaymentSheet  // Will uncomment after manual framework installation
// import StripePaymentsUI     // Will uncomment after manual framework installation

struct PaymentMethodsView: View {
    @StateObject private var paymentMethodService = PaymentMethodService.shared
    @State private var paymentMethods: [SavedPaymentMethod] = []
    @State private var isLoading = false
    @State private var showAddPayment = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Subtle gradient on black background
            LinearGradient(
                colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                } else {
                    List {
                        Section {
                            ForEach(paymentMethods) { method in
                                SavedPaymentMethodRow(method: method) {
                                    setAsDefault(method.id)
                                } onDelete: {
                                    deleteMethod(method.id)
                                }
                            }
                            
                            Button(action: {
                                showAddPayment = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Payment Method")
                                        .font(.sioreeBody)
                                }
                                .foregroundColor(.sioreeIcyBlue)
                            }
                        } header: {
                            Text("Payment Methods")
                                .foregroundColor(.sioreeLightGrey)
                        } footer: {
                            Text("Payment methods are securely stored by Stripe. Your card details are never stored on our servers.")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showStripeAddCard()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
        .sheet(isPresented: $showAddPayment) {
            AddPaymentMethodView(onPaymentMethodAdded: {
                loadPaymentMethods()
            })
        }
        .onAppear {
            loadPaymentMethods()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadPaymentMethods() {
        isLoading = true
        paymentMethodService.getSavedPaymentMethods()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { methods in
                    self.paymentMethods = methods
                }
            )
            .store(in: &cancellables)
    }
    
    private func setAsDefault(_ methodId: String) {
        paymentMethodService.setDefaultPaymentMethod(methodId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    loadPaymentMethods()
                }
            )
            .store(in: &cancellables)
    }
    
    private func deleteMethod(_ methodId: String) {
        paymentMethodService.deletePaymentMethod(methodId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    loadPaymentMethods()
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Stripe Integration
    private func showStripeAddCard() {
        // Create a SetupIntent on your backend to save payment method
        createSetupIntent { clientSecret in
            guard let clientSecret = clientSecret else {
                print("Failed to create setup intent")
                return
            }

            // Configure Payment Sheet for setup mode
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Sioree"
            configuration.allowsDelayedPaymentMethods = false
            configuration.returnURL = "sioree://stripe-redirect"

            // Initialize Payment Sheet
            let paymentSheet = PaymentSheet(
                setupIntentClientSecret: clientSecret,
                configuration: configuration
            )

            // Present Payment Sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                paymentSheet.present(from: rootViewController) { result in
                    switch result {
                    case .completed:
                        print("✅ Payment method saved successfully")
                        self.loadPaymentMethods()
                    case .canceled:
                        print("Payment method setup canceled")
                    case .failed(let error):
                        print("❌ Payment method setup failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func createSetupIntent(completion: @escaping (String?) -> Void) {
        // Call your backend to create a SetupIntent
        // This should return a client_secret for the SetupIntent
        NetworkService().request("/api/payments/create-setup-intent", method: "POST", body: nil)
            .sink(receiveCompletion: { _ in }, receiveValue: { (response: [String: String]) in
                completion(response["clientSecret"])
            })
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}

// Payment Sheet handles everything automatically - no custom delegate needed

struct PaymentMethodItem: Identifiable {
    let id: String
    let type: PaymentType
    let last4: String?
    let name: String
    var isDefault: Bool
}

enum PaymentType {
    case card
    case applePay
    case bankAccount
    
    var icon: String {
        switch self {
        case .card: return "creditcard.fill"
        case .applePay: return "applelogo"
        case .bankAccount: return "building.columns.fill"
        }
    }
}

struct SavedPaymentMethodRow: View {
    let method: SavedPaymentMethod
    let onSetDefault: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: iconForType(method.type))
                .font(.system(size: 24))
                .foregroundColor(.sioreeIcyBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(displayName)
                    .font(.sioreeBody)
                    .foregroundColor(.sioreeWhite)
                
                if method.isDefault {
                    Text("Default")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeIcyBlue)
                } else if let expMonth = method.expMonth, let expYear = method.expYear {
                    Text("Expires \(expMonth)/\(expYear % 100)")
                        .font(.sioreeCaption)
                        .foregroundColor(.sioreeLightGrey)
                }
            }
            
            Spacer()
            
            if !method.isDefault {
                Button("Set as Default") {
                    onSetDefault()
                }
                .font(.sioreeBodySmall)
                .foregroundColor(.sioreeIcyBlue)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .listRowBackground(Color.sioreeLightGrey.opacity(0.1))
    }
    
    private var displayName: String {
        switch method.type {
        case "card":
            let brand = method.brand?.capitalized ?? "Card"
            if let last4 = method.last4 {
                return "\(brand) •••• \(last4)"
            }
            return brand
        case "apple_pay":
            return "Apple Pay"
        case "bank_account":
            if let last4 = method.last4 {
                return "Bank Account •••• \(last4)"
            }
            return "Bank Account"
        default:
            return "Payment Method"
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "card": return "creditcard.fill"
        case "apple_pay": return "applelogo"
        case "bank_account": return "building.columns.fill"
        default: return "creditcard.fill"
        }
    }
}

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var stripeService = StripePaymentService.shared
    @StateObject private var paymentMethodService = PaymentMethodService.shared
    
    let onPaymentMethodAdded: () -> Void
    
    @State private var selectedType: PaymentType = .card
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var setAsDefault = false
    
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
                
                Form {
                    Section("Payment Type") {
                        Picker("Type", selection: $selectedType) {
                            Text("Credit/Debit Card").tag(PaymentType.card)
                            Text("Apple Pay").tag(PaymentType.applePay)
                            Text("Bank Account").tag(PaymentType.bankAccount)
                        }
                    }
                    
                    if selectedType == .card {
                        Section("Card Details") {
                            CustomTextField(placeholder: "Card Number", text: $cardNumber, keyboardType: .numberPad)
                                .onChange(of: cardNumber) { oldValue, newValue in
                                    // Format card number with spaces
                                    let formatted = formatCardNumber(newValue)
                                    if formatted != newValue {
                                        cardNumber = formatted
                                    }
                                }
                            
                            HStack {
                                CustomTextField(placeholder: "MM/YY", text: $expiryDate)
                                    .onChange(of: expiryDate) { oldValue, newValue in
                                        let formatted = formatExpiryDate(newValue)
                                        if formatted != newValue {
                                            expiryDate = formatted
                                        }
                                    }
                                
                                CustomTextField(placeholder: "CVV", text: $cvv, keyboardType: .numberPad)
                                    .onChange(of: cvv) { oldValue, newValue in
                                        if newValue.count > 4 {
                                            cvv = String(newValue.prefix(4))
                                        }
                                    }
                            }
                            
                            CustomTextField(placeholder: "Cardholder Name", text: $cardholderName)
                        }
                        
                        Section {
                            Toggle("Set as default payment method", isOn: $setAsDefault)
                                .foregroundColor(.sioreeWhite)
                        }
                    } else if selectedType == .applePay {
                        Section {
                            Text("Apple Pay will be added automatically when you use it for the first time.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    } else {
                        Section("Bank Account") {
                            Text("To add a bank account, go to Bank Accounts in Settings.")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if selectedType == .card {
                            addCard()
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.sioreeIcyBlue)
                    .disabled(selectedType == .card && !isCardFormValid || isLoading)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var isCardFormValid: Bool {
        let cleanedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        return cleanedCardNumber.count >= 13 && cleanedCardNumber.count <= 19 &&
               expiryDate.count == 5 && cvv.count >= 3 && cvv.count <= 4 &&
               !cardholderName.isEmpty
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return String(formatted.prefix(19)) // Max 16 digits + 3 spaces
    }
    
    private func formatExpiryDate(_ date: String) -> String {
        let cleaned = date.replacingOccurrences(of: "/", with: "")
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index == 2 {
                formatted += "/"
            }
            formatted.append(char)
        }
        return String(formatted.prefix(5)) // MM/YY
    }
    
    private func addCard() {
        isLoading = true
        errorMessage = nil
        
        // Create payment method from card details
        let cardData: [String: Any] = [
            "number": cardNumber.replacingOccurrences(of: " ", with: ""),
            "exp_month": Int(expiryDate.components(separatedBy: "/").first ?? "") ?? 0,
            "exp_year": 2000 + (Int(expiryDate.components(separatedBy: "/").last ?? "") ?? 0),
            "cvc": cvv,
            "name": cardholderName
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: cardData) else {
            errorMessage = "Invalid card data"
            isLoading = false
            return
        }
        
        // Create payment method via backend
        stripeService.getNetworkService().request("/api/payments/create-method", method: "POST", body: jsonData)
            .flatMap { (response: PaymentMethodResponse) -> AnyPublisher<SavedPaymentMethod, Error> in
                // Save the payment method
                return self.paymentMethodService.savePaymentMethod(
                    paymentMethodId: response.paymentMethod.id,
                    setAsDefault: self.setAsDefault
                )
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in
                    isLoading = false
                    onPaymentMethodAdded()
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct PaymentMethodResponse: Codable {
    let paymentMethod: StripePaymentMethod
}

#Preview {
    PaymentMethodsView()
}

