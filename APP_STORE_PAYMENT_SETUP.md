# App Store Payment Setup Guide

This guide will help you enable **real payment processing** when your app goes live on the App Store.

---

## Table of Contents

1. [Overview](#overview)
2. [Stripe Production Setup](#stripe-production-setup)
3. [Backend Configuration](#backend-configuration)
4. [iOS App Configuration](#ios-app-configuration)
5. [App Store Connect Setup](#app-store-connect-setup)
6. [Testing Payments](#testing-payments)
7. [Legal & Compliance](#legal--compliance)
8. [Go-Live Checklist](#go-live-checklist)

---

## Overview

Your app currently uses **Stripe** for payment processing, which is perfect for App Store deployment. Here's what you need to do:

### Payment Flow
1. User selects event/talent → Enters payment details → Stripe processes payment → Backend confirms → User receives ticket/booking
2. **Apple Pay** is already integrated for seamless payments
3. **Credit/Debit cards** are processed through Stripe

### Important Notes
- ✅ **Stripe is App Store compliant** - You can use it for physical goods/services (events, talent bookings)
- ⚠️ **Digital goods** (in-app purchases) require Apple's In-App Purchase system
- ✅ Your app sells **real-world services** (event tickets, talent bookings), so Stripe is correct

---

## Stripe Production Setup

### Step 1: Create Stripe Account

1. Go to [https://stripe.com](https://stripe.com)
2. Sign up for a **production account**
3. Complete business verification:
   - Business name: "Sioree" (or your legal entity name)
   - Business type (LLC, Corporation, etc.)
   - Tax ID/EIN
   - Business address
   - Bank account for payouts

### Step 2: Get Production API Keys

1. In Stripe Dashboard → **Developers** → **API keys**
2. Copy your **Publishable key** (starts with `pk_live_...`)
3. Copy your **Secret key** (starts with `sk_live_...`) - **KEEP THIS SECRET!**

### Step 3: Enable Apple Pay

1. In Stripe Dashboard → **Settings** → **Payment methods**
2. Enable **Apple Pay**
3. Upload your **Apple Pay Merchant ID** (from Apple Developer)
4. Complete Apple Pay domain verification

---

## Backend Configuration

### Step 1: Update Environment Variables

Update your backend `.env` file with **production** Stripe keys:

```bash
# Production Stripe Keys
STRIPE_SECRET_KEY=sk_live_YOUR_PRODUCTION_SECRET_KEY
STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_PRODUCTION_PUBLISHABLE_KEY

# Backend URL (use your production server)
API_URL=https://api.sioree.com

# Database (production)
DATABASE_URL=postgresql://user:password@host:5432/sioree_production
```

### Step 2: Update Backend Server

Your backend is already set up at:
- `backend/routes/payments.js` - Handles Stripe payment intents
- `backend/server.js` - Main server file

**Verify these endpoints work:**
- `POST /api/payments/create-intent` - Creates payment intent
- `POST /api/payments/confirm` - Confirms payment
- `POST /api/payments/methods` - Saves payment methods

### Step 3: Deploy Backend

**Recommended hosting options:**

1. **Heroku** (easiest)
   ```bash
   heroku create sioree-backend
   heroku addons:create heroku-postgresql:hobby-dev
   heroku config:set STRIPE_SECRET_KEY=sk_live_...
   git push heroku main
   ```

2. **AWS EC2** (more control)
   - Launch EC2 instance
   - Install Node.js, PostgreSQL
   - Set up PM2 for process management
   - Configure security groups

3. **Railway** (modern alternative)
   - Connect GitHub repo
   - Auto-deploys on push
   - Built-in PostgreSQL

4. **DigitalOcean** (affordable)
   - Droplet with Node.js
   - Managed PostgreSQL
   - Simple setup

### Step 4: Update iOS App Constants

Update `Constants.swift` to use production backend:

```swift
struct Constants {
    struct API {
        // Production backend URL
        static let baseURL = "https://api.sioree.com"  // Your production URL
        static let timeout: TimeInterval = 30
    }
}
```

---

## iOS App Configuration

### Step 1: Add Stripe Publishable Key

**Option A: Hardcode (Quick but not recommended)**
```swift
// In StripePaymentService.swift
private let publishableKey = "pk_live_YOUR_PRODUCTION_KEY"
```

**Option B: Use Info.plist (Recommended)**
1. Add to `Info.plist`:
   ```xml
   <key>StripePublishableKey</key>
   <string>pk_live_YOUR_PRODUCTION_KEY</string>
   ```

2. Read in code:
   ```swift
   private let publishableKey: String = {
       guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
             let plist = NSDictionary(contentsOfFile: path),
             let key = plist["StripePublishableKey"] as? String else {
           fatalError("Stripe publishable key not found")
       }
       return key
   }()
   ```

**Option C: Backend Configuration (Best Practice)**
- Have backend return publishable key on app startup
- Store in `UserDefaults` or `Keychain`
- This allows key rotation without app updates

### Step 2: Configure Apple Pay

1. **Apple Developer Account:**
   - Go to [developer.apple.com](https://developer.apple.com)
   - **Certificates, Identifiers & Profiles**
   - **Identifiers** → Your App ID
   - Enable **Apple Pay** capability
   - Create **Merchant ID** (e.g., `merchant.com.sioree.app`)

2. **Xcode:**
   - Open project → **Signing & Capabilities**
   - Add **Apple Pay** capability
   - Select your Merchant ID

3. **Update Apple Pay Configuration:**
   ```swift
   // In PaymentCheckoutView.swift or StripePaymentService.swift
   let paymentRequest = PKPaymentRequest()
   paymentRequest.merchantIdentifier = "merchant.com.sioree.app"
   paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
   paymentRequest.merchantCapabilities = .capability3DS
   paymentRequest.countryCode = "US"
   paymentRequest.currencyCode = "USD"
   ```

### Step 3: Update App Transport Security

Your `Info.plist` should allow HTTPS only in production:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.sioree.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

---

## App Store Connect Setup

### Step 1: Create App Listing

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: Sioree
   - **Primary Language**: English
   - **Bundle ID**: Your app's bundle ID
   - **SKU**: Unique identifier (e.g., `sioree-001`)

### Step 2: Set Up Banking & Tax

**CRITICAL for receiving payments:**

1. **Agreements, Tax, and Banking**
2. Complete:
   - **Paid Applications Agreement** (if charging for app)
   - **Tax Forms** (W-9 for US, W-8BEN for international)
   - **Banking Information** (where Apple sends your revenue)

### Step 3: Configure In-App Purchases (If Needed)

**Note:** You're using Stripe for **real-world services** (events, bookings), so you likely **don't need** In-App Purchases. However, if you want to sell:
- Premium app features
- Virtual currency
- Subscription to premium features

Then you **must** use In-App Purchases.

**For your use case (event tickets, talent bookings):**
- ✅ Stripe is correct - these are physical services
- ❌ Don't need In-App Purchases

### Step 4: Submit for Review

1. **Prepare Build:**
   - Archive in Xcode
   - Upload to App Store Connect
   - Wait for processing (10-30 minutes)

2. **Fill Out App Information:**
   - Screenshots (required)
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL (required!)

3. **Submit for Review:**
   - Answer export compliance questions
   - Submit
   - Wait 1-3 days for review

---

## Testing Payments

### Step 1: Test Mode First

**Always test in Stripe Test Mode before going live:**

1. Use test cards from [Stripe Testing](https://stripe.com/docs/testing)
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`
   - 3D Secure: `4000 0025 0000 3155`

2. Test in your app:
   - Create test event
   - Try to purchase ticket
   - Verify payment goes through
   - Check Stripe Dashboard → **Payments** → Should see test payment

### Step 2: Test Production Mode

1. Switch backend to production keys
2. Use **real credit card** (your own)
3. Test small amount ($1.00)
4. Verify:
   - Payment appears in Stripe Dashboard
   - Money arrives in your bank account (2-7 days)
   - User receives confirmation

### Step 3: Test Apple Pay

1. On physical device (simulator doesn't support Apple Pay)
2. Add test card to Wallet app
3. Test Apple Pay flow in your app
4. Verify payment processes correctly

---

## Legal & Compliance

### Required Documents

1. **Privacy Policy** (Required by App Store)
   - Must be accessible URL
   - Must explain what data you collect
   - Must explain how payments are processed
   - Example: `https://sioree.com/privacy`

2. **Terms of Service**
   - User agreement
   - Refund policy
   - Event cancellation policy
   - Example: `https://sioree.com/terms`

3. **Refund Policy**
   - Define when refunds are allowed
   - How to request refunds
   - Processing time

### Payment Compliance

1. **PCI DSS Compliance**
   - ✅ Stripe handles this for you (they're PCI Level 1 certified)
   - ✅ Never store full card numbers
   - ✅ Use Stripe Elements or Apple Pay (secure by default)

2. **GDPR (If serving EU users)**
   - Privacy policy must comply
   - User data deletion rights
   - Cookie consent (if web presence)

3. **Tax Collection**
   - Stripe can handle tax calculation
   - Or use services like TaxJar
   - Consult tax professional for your jurisdiction

---

## Go-Live Checklist

### Pre-Launch

- [ ] Stripe production account created and verified
- [ ] Production API keys added to backend
- [ ] Backend deployed to production server
- [ ] iOS app updated with production backend URL
- [ ] Apple Pay Merchant ID configured
- [ ] Test payments successful in production mode
- [ ] Privacy Policy published and accessible
- [ ] Terms of Service published
- [ ] Refund policy defined
- [ ] Banking information added to App Store Connect
- [ ] Tax forms completed

### App Store Submission

- [ ] App screenshots prepared (all required sizes)
- [ ] App description written
- [ ] Keywords optimized
- [ ] Support URL provided
- [ ] Privacy Policy URL provided
- [ ] Build uploaded and processing complete
- [ ] App submitted for review

### Post-Launch Monitoring

- [ ] Monitor Stripe Dashboard for payments
- [ ] Set up Stripe webhooks for payment events
- [ ] Monitor error logs
- [ ] Set up alerts for failed payments
- [ ] Track refund requests
- [ ] Monitor App Store reviews for payment issues

---

## Common Issues & Solutions

### Issue: "Payment failed" in production

**Solutions:**
1. Check Stripe Dashboard → **Logs** for error details
2. Verify production keys are correct
3. Check card has sufficient funds
4. Verify 3D Secure is enabled (required in many regions)

### Issue: Apple Pay not working

**Solutions:**
1. Verify Merchant ID is correct
2. Test on physical device (not simulator)
3. Check Apple Pay capability is enabled in Xcode
4. Verify Stripe Apple Pay is enabled in dashboard

### Issue: Backend connection errors

**Solutions:**
1. Verify production backend URL is correct
2. Check server is running
3. Verify SSL certificate is valid
4. Check App Transport Security settings

---

## Revenue & Fees

### Stripe Fees
- **2.9% + $0.30** per successful card charge
- **3.4% + $0.30** for international cards
- **No monthly fee** (pay-as-you-go)

### App Store Fees
- **30%** of app purchase price (if you charge for the app)
- **0%** for in-app purchases of physical goods/services (your case!)
- Since you're using Stripe (not In-App Purchases), Apple takes **0%** of your payment revenue

### Example Calculation
- User buys $50 event ticket
- Stripe fee: $1.75 (2.9% + $0.30)
- You receive: $48.25
- Apple fee: $0 (using Stripe, not In-App Purchase)

---

## Support & Resources

### Stripe Resources
- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Testing](https://stripe.com/docs/testing)
- [Stripe Support](https://support.stripe.com)

### Apple Resources
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [Apple Pay Integration](https://developer.apple.com/apple-pay/)

### Your Backend Code
- `backend/routes/payments.js` - Payment endpoints
- `backend/server.js` - Main server
- `Sioree XCode Project/Services/StripePaymentService.swift` - iOS Stripe integration

---

## Next Steps

1. **Create Stripe production account** (30 minutes)
2. **Deploy backend** with production keys (1-2 hours)
3. **Update iOS app** with production backend URL (5 minutes)
4. **Test payments** in production mode (30 minutes)
5. **Submit to App Store** (1-2 days for review)

---

**Good luck with your launch! 🚀**


