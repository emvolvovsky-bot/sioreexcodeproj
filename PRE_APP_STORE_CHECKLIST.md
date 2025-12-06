# Pre-App Store Checklist: Remove Placeholders & Enable Real Features

## 🚨 Critical: What MUST Be Fixed Before App Store Submission

### 1. ✅ Messaging - Currently Using Mock Data
**Status:** ❌ Currently returns empty arrays (mock data)
**Fix Required:** ✅ YES - Enable real API calls

**Current Issue:**
- `MessagingService` returns empty arrays instead of real messages
- Users won't be able to message each other

**Fix:** Update `MessagingService.swift` to use real API endpoints (see below)

---

### 2. ✅ Authentication - Currently Using Mock Auth
**Status:** ⚠️ Has `useMockAuth = true` flag
**Fix Required:** ✅ YES - Set to `false` when backend is ready

**Current Issue:**
- `AuthService` uses mock authentication
- Sign-up/login won't work with real backend

**Fix:** Change `useMockAuth = false` in `AuthService.swift`

---

### 3. ✅ Placeholder Views - Mostly OK
**Status:** ✅ These are functional, just named "Placeholder"
**Fix Required:** ⚠️ Optional - Rename for clarity

**Files:**
- `EventDetailPlaceholderView.swift` - Actually functional, just needs rename
- `MapViewPlaceholder.swift` - Actually functional map view
- `SettingsPlaceholders.swift` - Contains real settings views

**Action:** Optional rename for clarity, but not required for App Store

---

### 4. ✅ Image Placeholders - Already Fixed
**Status:** ✅ Already using placeholders (intentional)
**Fix Required:** ❌ NO - This is fine

**Current:** Event images show icon placeholders (you requested this)
**App Store:** ✅ This is acceptable - many apps use placeholders

---

## 🔧 How to Fix Messaging

### Step 1: Update MessagingService.swift

Change from mock responses to real API calls:

```swift
// BEFORE (mock):
func getConversations() -> AnyPublisher<[Conversation], Error> {
    return Future { promise in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            promise(.success([]))  // ❌ Empty array
        }
    }
    .eraseToAnyPublisher()
}

// AFTER (real):
func getConversations() -> AnyPublisher<[Conversation], Error> {
    struct Response: Codable {
        let conversations: [Conversation]
    }
    return networkService.request<Response>("/api/messages/conversations")
        .map { $0.conversations }
        .eraseToAnyPublisher()
}
```

### Step 2: Backend Must Support These Endpoints

Your backend needs:
- `GET /api/messages/conversations` - List all conversations
- `GET /api/messages/:conversationId` - Get messages in conversation
- `POST /api/messages` - Send a message
- `POST /api/messages/conversation` - Create/get conversation
- `POST /api/messages/:conversationId/read` - Mark as read

**See:** `BACKEND_SETUP.md` for full API documentation

---

## 🔧 How to Fix Authentication

### Step 1: Update AuthService.swift

```swift
// Change this line:
private let useMockAuth = true  // ❌ Mock mode

// To this:
private let useMockAuth = false  // ✅ Real backend mode
```

### Step 2: Ensure Backend Has These Endpoints

- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user

---

## ✅ What's Already Working (No Changes Needed)

1. **Payments** ✅
   - Stripe integration is real
   - Just needs production keys

2. **Event Cards** ✅
   - Using placeholders (intentional)
   - App Store acceptable

3. **UI Components** ✅
   - All functional
   - No mock data

4. **Navigation** ✅
   - All views are real
   - Role-based navigation works

---

## 📋 Complete Pre-Launch Checklist

### Backend Setup
- [ ] Backend deployed to production server
- [ ] Messaging endpoints implemented (`/api/messages/*`)
- [ ] Authentication endpoints working (`/api/auth/*`)
- [ ] Database migrations run
- [ ] WebSocket server running (for real-time messaging)
- [ ] Stripe production keys configured
- [ ] Environment variables set

### iOS App Updates
- [ ] `MessagingService.swift` - Enable real API calls
- [ ] `AuthService.swift` - Set `useMockAuth = false`
- [ ] `Constants.swift` - Set environment to `.production`
- [ ] Test all API calls work
- [ ] Test messaging between two users
- [ ] Test sign-up/login flow

### Testing
- [ ] Test messaging with 2+ users
- [ ] Test authentication (sign-up, login, logout)
- [ ] Test payments (Stripe test mode)
- [ ] Test payments (Stripe production mode - small amount)
- [ ] Test on physical device (not just simulator)

### App Store Requirements
- [ ] Privacy Policy URL (required!)
- [ ] Terms of Service URL
- [ ] Support URL
- [ ] App screenshots (all sizes)
- [ ] App description
- [ ] Keywords
- [ ] Banking/tax info in App Store Connect

---

## 🚀 Quick Fix Script

Run these changes before submitting:

1. **Enable Real Messaging:**
   ```swift
   // In MessagingService.swift - uncomment all "In production:" lines
   ```

2. **Enable Real Auth:**
   ```swift
   // In AuthService.swift
   private let useMockAuth = false
   ```

3. **Set Production Mode:**
   ```swift
   // In Constants.swift
   static let environment: Environment = .production
   ```

---

## ⚠️ Important Notes

### Messaging Will Work IF:
- ✅ Backend has messaging endpoints implemented
- ✅ WebSocket server is running (for real-time)
- ✅ Database has `messages` and `conversations` tables
- ✅ iOS app calls real API (not mock)

### Messaging Will NOT Work IF:
- ❌ Backend endpoints don't exist
- ❌ Using mock data (`MessagingService` returns empty arrays)
- ❌ WebSocket server not running
- ❌ Database not set up

---

## 📞 Need Help?

- **Backend Setup:** See `BACKEND_SETUP.md`
- **API Documentation:** See `BACKEND_SETUP.md` → Messaging Endpoints
- **Payment Setup:** See `APP_STORE_PAYMENT_SETUP.md`

---

**Bottom Line:** 
- ✅ **Placeholders are mostly OK** (image placeholders are fine)
- ❌ **Messaging MUST be fixed** (currently mock)
- ❌ **Auth MUST be fixed** (currently mock)
- ✅ **Payments are ready** (just need production keys)


