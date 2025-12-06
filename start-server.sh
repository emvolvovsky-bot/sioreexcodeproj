#!/bin/bash
# Start the backend server with proper environment variables

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 18 > /dev/null 2>&1

# Allow self-signed SSL certificates for Supabase connection
export NODE_TLS_REJECT_UNAUTHORIZED=0

# Start the server
cd "$(dirname "$0")"
node src/index.js

