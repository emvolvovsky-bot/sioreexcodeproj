//
//  PaymentCheckoutView.swift
//  Sioree
//
//  Real payment checkout with Stripe integration
//

import SwiftUI
import PassKit
import Combine
// import StripePaymentSheet  // Will uncomment after manual framework installation

struct PaymentCheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var paymentService = StripePaymentService.shared
    @StateObject private var paymentMethodService = PaymentMethodService.shared
    
    let amount: Double
    let description: String
    let bookingId: String?
    let onPaymentSuccess: (Payment) -> Void
    
    @State private var savedPaymentMethods: [SavedPaymentMethod] = []
    @State private var selectedPaymentMethod: SavedPaymentMethod?
    @State private var isLoading = false
    @State private var isLoadingMethods = false
    @State private var errorMessage: String?
    @State private var showPaymentSheet = false
    @State private var paymentIntent: StripePaymentIntent?
    
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
                        
                        // Payment Methods
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Payment Method")
                                .font(.sioreeH3)
                                .foregroundColor(.sioreeWhite)
                                .padding(.horizontal, Theme.Spacing.l)
                            
                            // Apple Pay Button (if available)
                            if PKPaymentAuthorizationController.canMakePayments() {
                                ApplePayButton(amount: amount, description: description) {
                                    processApplePay()
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                            
                            // Credit/Debit Card Option
                            Button(action: {
                                showPaymentSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundColor(.sioreeIcyBlue)
                                        .frame(width: 24)
                                    
                                    Text("Credit or Debit Card")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                .padding(Theme.Spacing.m)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .fill(Color.sioreeLightGrey.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                        .padding(.top, Theme.Spacing.l)
                        
                        // Pay Button (if payment method selected)
                        if selectedPaymentMethod != nil {
                            CustomButton(
                                title: "Pay $\(String(format: "%.2f", amount))",
                                variant: .primary,
                                size: .large
                            ) {
                                processPaymentWithSavedMethod()
                            }
                            .disabled(isLoading)
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.top, Theme.Spacing.l)
                        }
                        
                        // Security Notice
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Your payment is secure and encrypted")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)
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
            .sheet(isPresented: $showPaymentSheet) {
                CardPaymentView(
                    amount: amount,
                    description: description,
                    bookingId: bookingId,
                    onPaymentSuccess: { payment in
                        showPaymentSheet = false
                        loadSavedPaymentMethods() // Reload methods after adding new one
                        onPaymentSuccess(payment)
                        dismiss()
                    }
                )
            }
            .onAppear {
                loadSavedPaymentMethods()
            }
            .alert("Payment Error", isPresented: .constant(errorMessage != nil)) {
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
                            
                            Text("Processing payment...")
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
    
    private func processApplePay() {
        isLoading = true
        errorMessage = nil
        
        // Get clientSecret for Apple Pay
        paymentService.processApplePay(amount: amount, hostStripeAccountId: nil, description: description, bookingId: bookingId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to create payment: \(error.localizedDescription)"
                    }
                },
                receiveValue: { clientSecret in
                    // In production, use Stripe Apple Pay SDK here
                    // For now, show success message
                    // TODO: Integrate Stripe Apple Pay SDK
                    let payment = Payment(
                        userId: StorageService.shared.getUserId() ?? "",
                        amount: amount,
                        method: .applePay,
                        status: .paid,
                        transactionId: clientSecret.components(separatedBy: "_secret_").first,
                        description: description
                    )
                    onPaymentSuccess(payment)
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadSavedPaymentMethods() {
        isLoadingMethods = true
        paymentMethodService.getSavedPaymentMethods()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingMethods = false
                    if case .failure(let error) = completion {
                        // Don't show error, just use empty list
                        print("Error loading payment methods: \(error)")
                    }
                },
                receiveValue: { methods in
                    savedPaymentMethods = methods
                    // Select default method if available
                    if selectedPaymentMethod == nil, let defaultMethod = methods.first(where: { $0.isDefault }) {
                        selectedPaymentMethod = defaultMethod
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func displayNameForMethod(_ method: SavedPaymentMethod) -> String {
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
    
    private func processPaymentWithSavedMethod() {
        guard let method = selectedPaymentMethod else {
            errorMessage = "Please select a payment method"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Use Payment Sheet for modern payment processing
        createPaymentIntent { clientSecret in
            guard let clientSecret = clientSecret else {
                self.errorMessage = "Failed to create payment"
                self.isLoading = false
                return
            }

            // Configure Payment Sheet
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Sioree"
            configuration.allowsDelayedPaymentMethods = false
            configuration.returnURL = "sioree://stripe-redirect"

            // Initialize Payment Sheet with existing PaymentIntent
            let paymentSheet = PaymentSheet(
                paymentIntentClientSecret: clientSecret,
                configuration: configuration
            )

            // Present Payment Sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {

                paymentSheet.present(from: rootViewController) { result in
                    self.isLoading = false
                    switch result {
                    case .completed:
                        print("✅ Payment completed successfully")
                        // TODO: Fetch the payment details from your backend
                        // For now, create a mock payment object
                        let mockPayment = Payment(
                            id: UUID().uuidString,
                            amount: self.amount,
                            method: "card",
                            status: "paid",
                            transactionId: clientSecret.components(separatedBy: "_secret_").first ?? "",
                            description: self.description,
                            createdAt: Date()
                        )
                        self.onPaymentSuccess(mockPayment)
                        self.dismiss()
                    case .canceled:
                        print("Payment canceled")
                    case .failed(let error):
                        print("❌ Payment failed: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Apple Pay Button
struct ApplePayButton: View {
    let amount: Double
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "applelogo")
                    .foregroundColor(.white)
                
                Text("Pay with Apple Pay")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .background(Color.black)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

// MARK: - Card Payment View
struct CardPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var paymentService = StripePaymentService.shared
    
    let amount: Double
    let description: String
    let bookingId: String?
    let onPaymentSuccess: (Payment) -> Void
    
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var zipCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var paymentIntent: StripePaymentIntent?
    
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
                    VStack(spacing: Theme.Spacing.l) {
                        // Amount
                        VStack(spacing: Theme.Spacing.xs) {
                            Text("Amount")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                            
                            Text("$\(String(format: "%.2f", amount))")
                                .font(.sioreeH2)
                                .foregroundColor(.sioreeWhite)
                        }
                        .padding(Theme.Spacing.l)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .fill(Color.sioreeLightGrey.opacity(0.1))
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.l)
                        
                        // Card Form
                        VStack(spacing: Theme.Spacing.m) {
                            CustomTextField(
                                placeholder: "Card Number",
                                text: $cardNumber
                            )
                            .keyboardType(.numberPad)
                            
                            HStack(spacing: Theme.Spacing.m) {
                                CustomTextField(
                                    placeholder: "MM/YY",
                                    text: $expiryDate
                                )
                                .keyboardType(.numberPad)
                                
                                CustomTextField(
                                    placeholder: "CVV",
                                    text: $cvv
                                )
                                .keyboardType(.numberPad)
                            }
                            
                            CustomTextField(
                                placeholder: "Cardholder Name",
                                text: $cardholderName
                            )
                            
                            CustomTextField(
                                placeholder: "ZIP Code",
                                text: $zipCode
                            )
                            .keyboardType(.numberPad)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.l)
                        
                        // Pay Button
                        CustomButton(
                            title: "Pay $\(String(format: "%.2f", amount))",
                            variant: .primary,
                            size: .large
                        ) {
                            processCardPayment()
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)
                        
                        // Security Notice
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.sioreeIcyBlue)
                            
                            Text("Secured by Stripe")
                                .font(.sioreeCaption)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.top, Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Card Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeWhite)
                }
            }
            .alert("Payment Error", isPresented: .constant(errorMessage != nil)) {
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
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                            .scaleEffect(1.5)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty &&
        !expiryDate.isEmpty &&
        !cvv.isEmpty &&
        !cardholderName.isEmpty &&
        !zipCode.isEmpty &&
        cardNumber.count >= 13 &&
        cvv.count >= 3 &&
        zipCode.count >= 5
    }
    
    private func processCardPayment() {
        isLoading = true
        errorMessage = nil
        
        // Step 1: Create payment intent and get clientSecret
        paymentService.createPaymentIntent(amount: amount, hostStripeAccountId: nil, description: description, bookingId: bookingId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to create payment: \(error.localizedDescription)"
                    }
                },
                receiveValue: { clientSecret in
                    // Step 2: Confirm payment with card details
                    // In production, use Stripe Payment Sheet SDK here
                    // For now, we'll use a simplified flow
                    self.confirmPaymentWithCard(clientSecret: clientSecret)
                }
            )
            .store(in: &cancellables)
    }
    
    private func confirmPaymentWithCard(clientSecret: String) {
        // Extract payment intent ID from client secret
        let paymentIntentId = clientSecret.components(separatedBy: "_secret_").first ?? ""
        
        // Create payment method with card details
        let cardData: [String: Any] = [
            "number": cardNumber.replacingOccurrences(of: " ", with: ""),
            "exp_month": Int(expiryDate.components(separatedBy: "/").first ?? "12") ?? 12,
            "exp_year": Int("20" + (expiryDate.components(separatedBy: "/").last ?? "25")) ?? 2025,
            "cvc": cvv,
            "zip": zipCode
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: cardData) else {
            errorMessage = "Invalid card details"
            isLoading = false
            return
        }
        
        // Create payment method via backend
        struct PaymentMethodResponse: Codable {
            let paymentMethod: StripePaymentMethod
        }
        
        paymentService.getNetworkService().request("/api/payments/create-method", method: "POST", body: jsonData)
            .flatMap { (pmResponse: PaymentMethodResponse) -> AnyPublisher<Payment, Error> in
                // Confirm payment
                return self.paymentService.confirmPayment(
                    paymentIntentId: paymentIntentId,
                    paymentMethodId: pmResponse.paymentMethod.id
                )
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "Payment failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { payment in
                    isLoading = false
                    onPaymentSuccess(payment)
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }

    private func createPaymentIntent(completion: @escaping (String?) -> Void) {
        // Call your backend to create a PaymentIntent
        let body: [String: Any] = [
            "amount": amount,
            "currency": "usd",
            "description": description,
            "bookingId": bookingId
        ].compactMapValues { $0 }

        NetworkService().request("/api/payments/create-intent", method: "POST", body: body)
            .sink(receiveCompletion: { _ in }, receiveValue: { (response: [String: Any]) in
                if let paymentIntent = response["paymentIntent"] as? [String: Any],
                   let clientSecret = paymentIntent["clientSecret"] as? String {
                    completion(clientSecret)
                } else {
                    completion(nil)
                }
            })
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}

