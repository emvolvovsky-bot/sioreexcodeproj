# Test Payment Flow Guide

## ✅ Integration Complete!

Your iOS app is now integrated with your Stripe backend. Here's how to test it.

---

## 🎯 Quick Test Steps

### 1. Start Backend Server

```bash
cd "Skeleton Backend/sioree-backend"
npm run dev
```

You should see:
```
Connected to Supabase Postgres
Server running on port 4000
```

### 2. Open iOS App in Xcode

- Build and run the app
- Make sure it's pointing to your backend URL

### 3. Navigate to Payment Flow

**Option A: Event Payment**
- Go to an event with a ticket price
- Tap "Buy Ticket" or "RSVP"
- Payment checkout will appear

**Option B: Talent Booking**
- Go to Host → Marketplace
- Select a talent
- Tap "Book Now"
- Payment checkout will appear

### 4. Enter Test Card Details

Use Stripe's test card:
- **Card Number:** `4242 4242 4242 4242`
- **Expiry Date:** `12/25` (any future date)
- **CVV:** `123` (any 3 digits)
- **Cardholder Name:** `Test User`
- **ZIP Code:** `12345` (any 5 digits)

### 5. Complete Payment

- Tap "Pay $X.XX"
- Wait for processing
- Should see success message

### 6. Verify in Stripe Dashboard

1. Go to [dashboard.stripe.com/test](https://dashboard.stripe.com/test)
2. Login with your Stripe account
3. Click **"Payments"** in left sidebar
4. You should see your test payment!

**What to check:**
- ✅ Payment amount is correct
- ✅ Status is "Succeeded"
- ✅ Payment method shows card details
- ✅ If marketplace: Transfer shows 90% to host account

---

## 🔍 Troubleshooting

### "Cannot connect to server"

**Check:**
1. Backend is running: `curl http://localhost:4000/health`
2. iOS app `baseURL` matches backend URL
3. Firewall isn't blocking port 4000

**Fix:**
- Update `Constants.swift` with correct backend URL
- Make sure backend is running

### "Failed to create payment intent"

**Check:**
1. Stripe test key is correct in `src/services/payments.js`
2. Backend can reach Stripe API
3. Amount is valid (greater than 0)

**Fix:**
- Verify Stripe key in backend
- Check backend logs for errors

### "Payment failed"

**Check:**
1. Card details are correct
2. Using test card (not real card in test mode)
3. Backend payment confirmation endpoint works

**Fix:**
- Use test card: `4242 4242 4242 4242`
- Check backend logs
- Verify payment method creation succeeded

### Payment doesn't appear in Stripe Dashboard

**Check:**
1. Using correct Stripe account (test vs live)
2. Payment actually completed (check app logs)
3. Backend successfully called Stripe API

**Fix:**
- Make sure you're in **Test Mode** in Stripe Dashboard
- Check backend console for Stripe API responses
- Verify payment intent was created

---

## 📊 Expected Flow

1. **User taps "Pay"**
   - iOS app calls: `POST /api/payments/create-intent`
   - Backend creates Stripe Payment Intent
   - Backend returns: `{ clientSecret: "pi_xxx_secret_yyy" }`

2. **User enters card details**
   - Card number, expiry, CVV entered
   - iOS app validates form

3. **User taps "Pay"**
   - iOS app calls: `POST /api/payments/create-method` (with card details)
   - Backend creates Stripe Payment Method
   - iOS app calls: `POST /api/payments/confirm` (with payment intent ID + method ID)
   - Backend confirms payment with Stripe
   - Payment succeeds!

4. **Payment appears in Stripe Dashboard**
   - Check "Payments" tab
   - Should show test payment
   - Status: "Succeeded"

---

## ✅ Success Indicators

**In App:**
- ✅ Payment sheet appears
- ✅ Card form accepts input
- ✅ "Processing payment..." shows
- ✅ Success message appears
- ✅ User is redirected/notified

**In Stripe Dashboard:**
- ✅ Payment appears in "Payments"
- ✅ Amount is correct
- ✅ Status is "Succeeded"
- ✅ Payment method shows card (last 4 digits)
- ✅ If marketplace: Transfer created (90% to host)

**In Backend Logs:**
- ✅ "Creating payment intent..."
- ✅ "Payment intent created: pi_xxx"
- ✅ "Payment method created: pm_xxx"
- ✅ "Payment confirmed: succeeded"

---

## 🎉 You're Ready!

1. ✅ Backend is set up
2. ✅ iOS app is integrated
3. ✅ Stripe test key configured
4. ✅ Payment flow implemented

**Just test it!** Use test card `4242 4242 4242 4242` and verify in Stripe Dashboard.

---

## 📝 Next Steps (Optional)

**For Production:**
1. Add Stripe iOS SDK (see `STRIPE_IOS_INTEGRATION.md`)
2. Use Stripe Payment Sheet for secure card collection
3. Replace test key with production key
4. Test with real cards (small amounts!)

**For Now:**
- ✅ Test with test cards
- ✅ Verify payments work
- ✅ Check Stripe Dashboard
- ✅ Test marketplace fee (90/10 split)

---

**Happy Testing!** 🚀


