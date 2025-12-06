# Auto-Start Backend Server Guide

## ✅ Setup Complete!

I've created scripts to automatically start and keep your backend running. Choose the method that works best for you:

---

## 🚀 Method 1: Double-Click Script (Easiest)

### Setup:
1. **Make scripts executable:**
   ```bash
   cd "Skeleton Backend/sioree-backend"
   chmod +x start-backend.sh stop-backend.sh
   cd ../..
   chmod +x start-backend.command
   ```

2. **Double-click `start-backend.command`** in Finder
   - This will open Terminal and start the backend
   - Backend will keep running until you close Terminal or stop it

### To Stop:
- Press `Ctrl+C` in Terminal, OR
- Run: `pm2 stop sioree-backend`

---

## 🔄 Method 2: PM2 Process Manager (Recommended)

PM2 keeps your backend running automatically, even if it crashes or you close Terminal.

### Setup:
1. **Install PM2:**
   ```bash
   npm install -g pm2
   ```

2. **Start backend:**
   ```bash
   cd "Skeleton Backend/sioree-backend"
   bash start-backend.sh
   ```

### Useful Commands:
```bash
pm2 status              # Check if backend is running
pm2 logs sioree-backend # View logs
pm2 restart sioree-backend # Restart backend
pm2 stop sioree-backend    # Stop backend
pm2 delete sioree-backend  # Remove from PM2
```

### Auto-Start on Mac Boot:
```bash
# After starting with PM2, save the process list
pm2 save

# Generate startup script
pm2 startup

# Follow the instructions it prints (usually involves running a sudo command)
```

---

## 🍎 Method 3: macOS Launch Agent (Auto-Start on Boot)

This makes the backend start automatically when you turn on your Mac.

### Setup:
1. **Create Launch Agent:**
   ```bash
   # Create the plist file
   cat > ~/Library/LaunchAgents/com.sioree.backend.plist << 'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.sioree.backend</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/local/bin/node</string>
           <string>/Users/YOUR_USERNAME/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend/src/index.js</string>
       </array>
       <key>WorkingDirectory</key>
       <string>/Users/YOUR_USERNAME/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend</string>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
       <key>StandardOutPath</key>
       <string>/Users/YOUR_USERNAME/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend/logs/out.log</string>
       <key>StandardErrorPath</key>
       <string>/Users/YOUR_USERNAME/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend/logs/err.log</string>
   </dict>
   </plist>
   EOF
   ```

2. **Update paths** (replace `YOUR_USERNAME` with your actual username)

3. **Load the agent:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.sioree.backend.plist
   ```

4. **Start it:**
   ```bash
   launchctl start com.sioree.backend
   ```

### To Stop:
```bash
launchctl stop com.sioree.backend
launchctl unload ~/Library/LaunchAgents/com.sioree.backend.plist
```

---

## 📋 Quick Reference

### Check if Backend is Running:
```bash
curl http://192.168.1.200:4000/health
```

### View Logs:
```bash
# If using PM2:
pm2 logs sioree-backend

# If using Launch Agent:
tail -f ~/Library/Logs/com.sioree.backend/out.log
```

### Restart Backend:
```bash
# PM2:
pm2 restart sioree-backend

# Launch Agent:
launchctl stop com.sioree.backend
launchctl start com.sioree.backend
```

---

## 🎯 Recommended Setup

**For Development:**
- Use **Method 2 (PM2)** - Easy to start/stop, keeps running if it crashes

**For Always-On:**
- Use **Method 3 (Launch Agent)** - Starts automatically on boot

---

## ✅ Test It

1. Start backend using one of the methods above
2. Check it's running:
   ```bash
   curl http://192.168.1.200:4000/health
   ```
3. Should return: `{"status":"Backend running","database":"Supabase Postgres"}`

---

## 🐛 Troubleshooting

### Backend won't start:
- Check Node.js is installed: `node --version`
- Check you're in the right directory
- Check `.env` file exists with `DATABASE_URL`

### Port already in use:
```bash
# Find what's using port 4000:
lsof -i :4000

# Kill it:
kill -9 <PID>
```

### PM2 not found:
```bash
npm install -g pm2
```

---

**Your backend will now start automatically!** 🎉


