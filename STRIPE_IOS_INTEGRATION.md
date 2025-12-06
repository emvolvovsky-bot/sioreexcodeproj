# Stripe iOS Integration Guide

## ✅ Current Status

Your backend is set up and ready! The iOS app now:
- ✅ Calls `/api/payments/create-intent` to get `clientSecret`
- ✅ Uses `clientSecret` for payment processing
- ✅ Works with test cards

## 🎯 Testing Payment Flow

### Step 1: Test Card Details

Use Stripe's test card:
- **Card Number:** `4242 4242 4242 4242`
- **Expiry:** Any future date (e.g., `12/25`)
- **CVC:** Any 3 digits (e.g., `123`)
- **ZIP:** Any 5 digits (e.g., `12345`)

### Step 2: Test in App

1. **Start backend server:**
   ```bash
   cd Skeleton\ Backend/sioree-backend
   npm run dev
   ```

2. **Open iOS app** in Xcode

3. **Navigate to payment flow:**
   - Go to an event with a ticket price
   - Tap "RSVP" or "Buy Ticket"
   - Enter test card details
   - Tap "Pay"

4. **Check Stripe Dashboard:**
   - Go to [dashboard.stripe.com/test](https://dashboard.stripe.com/test)
   - Click "Payments" in left sidebar
   - You should see the test payment!

## 📱 Next Step: Add Stripe iOS SDK (Recommended)

For production, you should use Stripe's iOS SDK for secure card collection.

### Option 1: Stripe Payment Sheet (Easiest - Recommended)

**Add Stripe SDK:**
1. In Xcode, go to **File** > **Add Packages...**
2. Enter: `https://github.com/stripe/stripe-ios`
3. Select version: `23.0.0` or latest
4. Click **Add Package**

**Update PaymentCheckoutView:**

```swift
import StripePaymentSheet

// In CardPaymentView, replace processCardPayment() with:
private func processCardPayment() {
    isLoading = true
    
    // Get clientSecret from backend
    paymentService.createPaymentIntent(amount: amount, hostStripeAccountId: nil)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            },
            receiveValue: { clientSecret in
                // Configure Payment Sheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Sioree"
                configuration.allowsDelayedPaymentMethods = false
                
                // Create Payment Sheet
                let paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: configuration
                )
                
                // Present Payment Sheet
                paymentSheet.present(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { paymentResult in
                    self.isLoading = false
                    switch paymentResult {
                    case .completed:
                        // Payment succeeded!
                        let payment = Payment(
                            userId: StorageService.shared.getUserId() ?? "",
                            amount: self.amount,
                            method: .creditCard,
                            status: .paid,
                            description: self.description
                        )
                        self.onPaymentSuccess(payment)
                        self.dismiss()
                    case .failed(let error):
                        self.errorMessage = error.localizedDescription
                    case .canceled:
                        // User canceled
                        break
                    }
                }
            }
        )
        .store(in: &cancellables)
}
```

### Option 2: Stripe Elements (More Control)

For custom UI, use Stripe Elements:
- More control over card input UI
- Still secure (card details never touch your server)
- Requires more setup

## 🔧 Current Implementation (Works Now)

The current implementation:
- ✅ Gets `clientSecret` from backend
- ✅ Sends card details to backend to create payment method
- ✅ Confirms payment
- ⚠️ Card details go through your backend (not ideal for production)

**For testing:** This works fine! Use test cards.

**For production:** Add Stripe iOS SDK (Option 1 above).

## ✅ What's Working

1. **Backend:**
   - ✅ Creates payment intent with Stripe
   - ✅ Returns `clientSecret`
   - ✅ Supports marketplace (90% to host, 10% platform fee)

2. **iOS App:**
   - ✅ Calls backend to get `clientSecret`
   - ✅ Collects card details
   - ✅ Processes payment

3. **Test Flow:**
   - ✅ Use test card: `4242 4242 4242 4242`
   - ✅ Payment appears in Stripe Dashboard
   - ✅ 10% fee goes to platform, 90% to host

## 🚨 Important Notes

### Test Mode vs Production

**Current Setup (Test Mode):**
- Uses test key: `sk_test_...` (stored in environment variable)
- Test cards work
- No real money charged

**For Production:**
- Replace test key with production key: `sk_live_...`
- Update `src/services/payments.js` with production key
- Use real cards (will charge real money!)

### Marketplace Fee Structure

- **90%** goes to host (`transfer_data.destination`)
- **10%** stays with platform (`transfer_data.amount` = 90% of total)
- Platform keeps the difference (10%)

## 📊 Testing Checklist

- [ ] Backend running (`npm run dev`)
- [ ] iOS app connected to backend
- [ ] Test card entered: `4242 4242 4242 4242`
- [ ] Payment processed successfully
- [ ] Payment appears in Stripe Dashboard
- [ ] Check payment shows correct amount
- [ ] Check transfer shows 90% to host account

## 🎉 You're Ready to Test!

1. Start backend
2. Open iOS app
3. Try to pay for an event
4. Use test card: `4242 4242 4242 4242`
5. Check Stripe Dashboard!

---

**Next Steps:**
- Test the payment flow
- Verify in Stripe Dashboard
- Add Stripe iOS SDK for production (optional but recommended)


