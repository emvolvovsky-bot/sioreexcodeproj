# 💳 How to Test Payments in Your App

## Quick Steps

### 1. **Make Sure Backend is Running**

```bash
cd "Skeleton Backend/sioree-backend"
npm run dev
```

You should see: `Server running on port 4000`

### 2. **Open an Event with a Ticket Price**

**Option A: Create a Paid Event**
1. Open the app
2. Go to **Host** → **My Events** → **Create Event**
3. Fill in event details
4. Set a **Ticket Price** (e.g., `25.00`)
5. Create the event

**Option B: Use an Existing Paid Event**
- If you already have events with ticket prices, just open one

### 3. **Tap "Buy Ticket"**

1. Open any event detail page
2. If the event has a ticket price, you'll see **"Buy Ticket - $X.XX"** button
3. Tap it
4. Payment checkout screen will appear

### 4. **Enter Test Card Details**

Use Stripe's test card (works in test mode only):

```
Card Number:  4242 4242 4242 4242
Expiry Date:  12/25 (any future date)
CVV:          123 (any 3 digits)
Cardholder:   Test User (any name)
ZIP Code:     12345 (any 5 digits)
```

### 5. **Complete Payment**

1. Tap **"Pay $X.XX"** button
2. Wait for processing (you'll see "Processing payment...")
3. Should see success message ✅

### 6. **Verify in Stripe Dashboard**

1. Go to [dashboard.stripe.com/test](https://dashboard.stripe.com/test)
2. Make sure you're in **Test Mode** (toggle in top right)
3. Click **"Payments"** in left sidebar
4. You should see your test payment!

**What to check:**
- ✅ Amount matches what you paid
- ✅ Status is **"Succeeded"**
- ✅ Payment method shows card ending in **4242**
- ✅ Created timestamp is recent

---

## 🎯 Where Payments Appear

### In the App:
- **Event Detail** → Tap "Buy Ticket" → Payment checkout
- **Talent Booking** → Host → Marketplace → Select talent → "Book Now"

### In Stripe Dashboard:
- **Payments** tab → All successful payments
- **Payment Intents** tab → All payment attempts

---

## 🔍 Troubleshooting

### "Cannot connect to server"
- **Check:** Backend is running (`curl http://localhost:4000/health`)
- **Fix:** Start backend: `cd "Skeleton Backend/sioree-backend" && npm run dev`

### "Failed to create payment intent"
- **Check:** Stripe test key is correct in backend
- **Fix:** Verify key in `Skeleton Backend/sioree-backend/src/services/payments.js`

### Payment doesn't appear in Stripe Dashboard
- **Check:** You're in **Test Mode** (not Live Mode)
- **Check:** Backend logs show successful Stripe API call
- **Fix:** Look for errors in backend console

### "Payment failed" error
- **Check:** Using test card `4242 4242 4242 4242`
- **Check:** Card details are correct (expiry date is future)
- **Fix:** Use the exact test card number above

---

## ✅ Success Checklist

**In App:**
- [ ] Payment checkout screen appears
- [ ] Can enter card details
- [ ] "Pay" button works
- [ ] Shows "Processing payment..."
- [ ] Shows success message

**In Stripe Dashboard:**
- [ ] Payment appears in "Payments" tab
- [ ] Amount is correct
- [ ] Status is "Succeeded"
- [ ] Payment method shows card details

**In Backend Console:**
- [ ] "Creating payment intent..."
- [ ] "Payment intent created: pi_xxx"
- [ ] "Payment confirmed: succeeded"

---

## 🧪 Other Test Cards

Stripe provides different test cards for different scenarios:

| Card Number | Scenario |
|------------|----------|
| `4242 4242 4242 4242` | Success (default) |
| `4000 0000 0000 0002` | Card declined |
| `4000 0000 0000 9995` | Insufficient funds |
| `4000 0025 0000 3155` | Requires authentication |

**Use the first one (`4242 4242 4242 4242`) for normal testing.**

---

## 📱 Quick Test Flow

1. **Start backend** → `npm run dev`
2. **Open app** → Find/create event with ticket price
3. **Tap "Buy Ticket"** → Payment screen opens
4. **Enter:** `4242 4242 4242 4242` / `12/25` / `123`
5. **Tap "Pay"** → Wait for success
6. **Check Stripe Dashboard** → Verify payment appears

**That's it!** 🎉


