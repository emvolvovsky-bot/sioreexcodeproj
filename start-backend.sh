#!/bin/bash

# Auto-start script for Sioree Backend
# This script will start the backend and keep it running

cd "$(dirname "$0")"

echo "🚀 Starting Sioree Backend..."

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2 (process manager)..."
    npm install -g pm2
fi

# Check if backend is already running
if pm2 list | grep -q "sioree-backend"; then
    echo "✅ Backend is already running!"
    echo "   To restart: pm2 restart sioree-backend"
    echo "   To stop: pm2 stop sioree-backend"
    echo "   To view logs: pm2 logs sioree-backend"
else
    # Start backend with PM2
    echo "🔄 Starting backend with PM2..."
    pm2 start ecosystem.config.cjs
    
    # Save PM2 process list (so it restarts on reboot)
    pm2 save
    
    echo "✅ Backend started successfully!"
    echo ""
    echo "📊 Useful commands:"
    echo "   pm2 status              - Check status"
    echo "   pm2 logs sioree-backend - View logs"
    echo "   pm2 restart sioree-backend - Restart"
    echo "   pm2 stop sioree-backend - Stop"
    echo "   pm2 delete sioree-backend - Remove"
fi


