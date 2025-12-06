# 🚨 START BACKEND SERVER NOW

## The Problem
Your iOS app is trying to connect to `http://192.168.1.200:4000` but **the backend server is not running**, causing timeout errors.

## Quick Fix - Start the Backend

### Step 1: Open Terminal
Open a **new terminal window** (keep it open - don't close it!)

### Step 2: Navigate to Backend Folder
```bash
cd "/Users/evolvovsky26/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend"
```

### Step 3: Load Node 18
```bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 18
```

### Step 4: Check Port 4000
```bash
lsof -i :4000
```

**If you see any process**, kill it:
```bash
kill -9 <PID>
```
(Replace `<PID>` with the number from the lsof output)

### Step 5: Start the Server
```bash
npm run dev
```

**OR** if that doesn't work:
```bash
node src/index.js
```

### Step 6: Verify It's Running
You should see output like:
```
Connected to Supabase Postgres
Server running on port 4000
```

### Step 7: Test the Server (in a NEW terminal)
```bash
curl http://192.168.1.200:4000/health
```

You should get:
```json
{"status":"Backend running","database":"Supabase Postgres"}
```

## ⚠️ IMPORTANT
**Keep the terminal with `npm run dev` OPEN** while using the app. If you close it, the server stops and you'll get timeout errors again.

## Troubleshooting

### "Cannot find module" error
```bash
npm install
```

### "Port 4000 already in use"
```bash
lsof -i :4000
kill -9 <PID>
```

### "Database connection error"
- Check your `.env` file has `DATABASE_URL` set
- Make sure your Supabase database is accessible

### Still getting timeouts?
1. Check your Mac's IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
2. Make sure `192.168.1.200` matches your Mac's IP
3. Update `Constants.swift` if your IP changed

## Once Server is Running
✅ Try creating an event again in the iOS app
✅ The timeout error should be gone
✅ Check the backend terminal for logs


