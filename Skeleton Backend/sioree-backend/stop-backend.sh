#!/bin/bash

# Stop script for Sioree Backend

cd "$(dirname "$0")"

echo "🛑 Stopping Sioree Backend..."

if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "sioree-backend"; then
        pm2 stop sioree-backend
        pm2 delete sioree-backend
        echo "✅ Backend stopped!"
    else
        echo "ℹ️  Backend is not running"
    fi
else
    echo "❌ PM2 not found. Install with: npm install -g pm2"
fi


