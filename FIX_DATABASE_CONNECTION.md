# Fix Database Connection - SCRAM Authentication Error

## The Problem
You're getting: `SASL: SCRAM-SERVER-FINAL-MESSAGE: server signature is missing`

This error means the **database password in your DATABASE_URL is incorrect**.

## Solution: Verify and Reset Your Database Password

### Step 1: Get Your Correct Password from Supabase

1. Go to **Supabase Dashboard** → Your Project
2. Go to **Settings** → **Database**
3. Scroll to **Connection string** section
4. Look for your database password OR click **"Reset database password"**
5. Copy the password

### Step 2: URL-Encode Special Characters (if needed)

If your password contains special characters, you MUST URL-encode them:

- `@` → `%40`
- `#` → `%23`
- `%` → `%25`
- `&` → `%26`
- `+` → `%2B`
- `=` → `%3D`
- `?` → `%3F`
- `/` → `%2F`
- `:` → `%3A`
- ` ` (space) → `%20`

### Step 3: Update DATABASE_URL in Render

Your connection string should be:

```
postgresql://postgres.vldeevpesjrmdckqfkjq:[YOUR-ACTUAL-PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true
```

**Replace `[YOUR-ACTUAL-PASSWORD]` with your actual password from Supabase.**

### Step 4: Alternative - Try Session Pooler Instead

If Transaction Pooler (port 6543) continues to have issues, try **Session Pooler**:

1. In Supabase → Settings → Database
2. Change **Method** from "Transaction Pooler" to **"Session Pooler"**
3. Copy the new connection string (will use port 6543 or different port)
4. Update `DATABASE_URL` in Render

Session Pooler connection string format:
```
postgresql://postgres.vldeevpesjrmdckqfkjq:[PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true
```

## Quick Test

After updating, the logs should show:
- ✅ Database pool connected

If you still see the SCRAM error, the password is definitely wrong.

## Common Mistakes

1. ❌ Using `[YOUR-PASSWORD]` placeholder instead of actual password
2. ❌ Not URL-encoding special characters in password
3. ❌ Using old/expired password
4. ❌ Copy-paste errors (extra spaces, missing characters)

