# 🔥 LOGIN TIMEOUT FIX

## ❌ Problem

You're getting "Connection timeout" when trying to login because **your backend server is NOT running**.

The app is trying to connect to: `http://192.168.1.200:4000` but nothing is listening there.

---

## ✅ SOLUTION: Start Your Backend Server

### Option 1: Quick Start (Terminal)
```bash
cd "Skeleton Backend/sioree-backend"
npm run dev
```

You should see:
```
Connected to Supabase Postgres
Server running on port 4000
```

**Keep this terminal window open!** The server needs to stay running.

---

### Option 2: Use PM2 (Keeps Running Automatically)
```bash
cd "Skeleton Backend/sioree-backend"

# Install PM2 globally (one time only)
npm install -g pm2

# Start backend with PM2
pm2 start src/index.js --name sioree-backend

# Save PM2 config (so it restarts on reboot)
pm2 save
pm2 startup  # Follow the instructions it prints
```

PM2 will:
- ✅ Keep backend running even if you close Terminal
- ✅ Restart automatically if it crashes
- ✅ Start on system boot

---

### Option 3: Double-Click Script (macOS)
1. Double-click `start-backend.command` in Finder
2. Backend starts automatically
3. Keep Terminal window open

---

## 🧪 Test Backend is Running

After starting, test it:
```bash
curl http://192.168.1.200:4000/health
```

Should return:
```json
{"status":"Backend running","database":"Supabase Postgres"}
```

---

## ⚠️ TEMPORARY FIX: Use Mock Auth (While Setting Up Backend)

If you want to use the app **right now** while setting up the backend:

1. Open `Sioree XCode Project/Services/AuthService.swift`
2. Change line 18 from:
   ```swift
   private let useMockAuth = false // ✅ Using real backend
   ```
   to:
   ```swift
   private let useMockAuth = true // ⚠️ TEMPORARY: Backend not running
   ```
3. Rebuild the app
4. Login will work with mock data (no backend needed)

**Remember:** Change it back to `false` when your backend is running!

---

## 🔍 Why It Times Out

- ❌ Backend server is not running
- ❌ No server listening on port 4000
- ❌ iOS app can't connect → timeout after 12 seconds

**Solution:** Start the backend server!

---

## 📝 Quick Checklist

- [ ] Backend server is running (`npm run dev` or PM2)
- [ ] Can access `http://192.168.1.200:4000/health`
- [ ] iOS app can connect (no timeout errors)
- [ ] Login works!

---

**START YOUR BACKEND AND LOGIN WILL WORK!** 🚀


