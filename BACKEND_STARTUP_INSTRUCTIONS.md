# Backend Server Startup Instructions

## Fixed Issues
✅ **Removed duplicate import** in `src/index.js` (removed unused `paymentsRoutes`)
✅ **Fixed payment route** to properly extract `amount` and `hostStripeAccountId` from request body
✅ **Improved error handling** in payment route

## Step-by-Step Instructions

### 1. Open Terminal and Navigate
```bash
cd "/Users/evolvovsky26/Creative Cloud Files/Mobile App Design/Sioree XCode Project/Skeleton Backend/sioree-backend"
```

### 2. Load Node v18
```bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 18
```

### 3. Check Port 4000
```bash
lsof -i :4000
```

If any process shows, kill it:
```bash
kill -9 <PID>
```

### 4. Install Dependencies (if needed)
```bash
npm install
```

### 5. Start the Server
```bash
npm run dev
```

**OR** if that doesn't work:
```bash
node src/index.js
```

### 6. Verify Server is Running
In a **new terminal window**, test:
```bash
curl http://localhost:4000/health
```

You should see:
```json
{"status":"Backend running","database":"Supabase Postgres"}
```

### 7. Test Stripe Payment Endpoint
```bash
curl -X POST http://localhost:4000/api/payments/create-intent \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "hostStripeAccountId": "acct_1SbFzzEZUZnzE3CS"
  }'
```

**Expected Response:**
```json
{
  "clientSecret": "pi_xxxxx_secret_xxxxx"
}
```

**If you get an error**, check:
1. Stripe API key is set in `src/services/payments.js`
2. The Stripe account ID is valid
3. Backend console shows the error details

## Troubleshooting

### Server Won't Start
- Check if `.env` file exists with `DATABASE_URL`
- Check if database connection is working
- Look for error messages in console

### Payment Endpoint Fails
- Check Stripe API key is valid
- Verify the Stripe account ID format
- Check backend console for detailed error messages

### Port Already in Use
```bash
# Find process using port 4000
lsof -i :4000

# Kill it
kill -9 <PID>
```

## Keep Server Running
**Important:** Keep the terminal with `npm run dev` or `node src/index.js` **open** while testing. The server needs to stay running for the app to work.

## Next Steps
Once the server is running:
1. Test event creation in the iOS app
2. Test payment flow
3. Check backend console logs for any errors


