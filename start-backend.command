#!/bin/bash

# macOS Auto-Start Script
# Double-click this file to start the backend automatically

cd "$(dirname "$0")/Skeleton Backend/sioree-backend"

# Open Terminal window
osascript -e 'tell application "Terminal" to activate'

# Run the start script
bash start-backend.sh

# Keep terminal open
echo ""
echo "Press any key to close this window..."
read -n 1


