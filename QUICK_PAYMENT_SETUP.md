# Quick Payment Setup - TL;DR Version

## 🚀 5 Steps to Enable Real Payments

### 1. Create Stripe Account (15 min)
- Go to [stripe.com](https://stripe.com) → Sign up
- Complete business verification
- Get production keys: `pk_live_...` and `sk_live_...`

### 2. Deploy Backend (30 min)
```bash
# Update backend/.env
STRIPE_SECRET_KEY=sk_live_YOUR_KEY
STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_KEY

# Deploy (example with Heroku)
heroku create sioree-backend
heroku config:set STRIPE_SECRET_KEY=sk_live_...
git push heroku main
```

### 3. Update iOS App (5 min)
```swift
// Constants.swift
static let baseURL = "https://api.sioree.com"  // Your production URL
```

### 4. Configure Apple Pay (10 min)
- Apple Developer → Create Merchant ID
- Xcode → Add Apple Pay capability
- Stripe Dashboard → Enable Apple Pay

### 5. Test & Submit (1 hour)
- Test with real card ($1.00)
- Verify payment in Stripe Dashboard
- Submit to App Store

---

## ✅ Checklist

- [ ] Stripe production account verified
- [ ] Production keys in backend `.env`
- [ ] Backend deployed and accessible
- [ ] iOS app points to production backend
- [ ] Apple Pay configured
- [ ] Test payment successful
- [ ] Privacy Policy published
- [ ] App Store Connect banking/tax complete
- [ ] App submitted for review

---

## 💰 Fees

- **Stripe**: 2.9% + $0.30 per transaction
- **Apple**: $0 (you're using Stripe, not In-App Purchase)
- **You keep**: ~97% of revenue

---

## 📞 Need Help?

- Full guide: `APP_STORE_PAYMENT_SETUP.md`
- Stripe docs: https://stripe.com/docs
- Backend code: `backend/routes/payments.js`


