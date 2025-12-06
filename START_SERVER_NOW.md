# 🚀 START BACKEND SERVER NOW

## The Problem
Your login is timing out because **the backend server is not running**.

## Quick Fix

### Option 1: Use the startup script
```bash
cd "/Users/evolvovsky26/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend"
source ~/.nvm/nvm.sh
npm run dev
```

### Option 2: Manual start
```bash
cd "/Users/evolvovsky26/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend"
source ~/.nvm/nvm.sh
node src/index.js
```

## What to Look For
After starting, you should see:
```
✅ Database pool connected
✅ Server running on port 4000
🌐 Accessible at: http://localhost:4000 or http://192.168.1.200:4000
```

## Keep It Running
- **Keep the terminal window OPEN** while using the app
- If you close it, the server stops and you'll get timeout errors again
- To stop: Press `Ctrl+C` in the terminal

## If Database Connection Fails
If you see "Database connection error", check:
1. Your `.env` file has the correct `DATABASE_URL`
2. Your internet connection is working
3. Supabase database is accessible

## Test It
Once running, test with:
```bash
curl http://192.168.1.200:4000/health
```

Should return: `{"status":"Backend running","database":"Supabase Postgres"}`

