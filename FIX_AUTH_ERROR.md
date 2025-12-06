# Fix: "Data couldn't be read because it isn't in the correct format"

## ✅ Fixed!

The backend auth route has been updated to:
1. ✅ Use PostgreSQL syntax (was using SQLite)
2. ✅ Return correct format: `{ token, user }` (matches iOS expectations)
3. ✅ Include all required user fields

## 🔧 What Was Wrong

**Backend was returning:**
```json
{
  "message": "User created",
  "user": { "id": 1, "email": "...", "name": "..." },
  "accessToken": "...",
  "refreshToken": "..."
}
```

**iOS app expected:**
```json
{
  "token": "...",
  "user": {
    "id": "1",
    "email": "...",
    "username": "...",
    "name": "...",
    "userType": "partier",
    ...
  }
}
```

## 🚀 Quick Fix Steps

### 1. Update Database Schema

Run this SQL in your Supabase SQL Editor (or PostgreSQL client):

```sql
-- Add missing columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS name VARCHAR(255),
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS avatar TEXT,
ADD COLUMN IF NOT EXISTS user_type VARCHAR(50) DEFAULT 'partier',
ADD COLUMN IF NOT EXISTS location VARCHAR(255),
ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS follower_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS event_count INTEGER DEFAULT 0;
```

**OR** run the migration script:
```bash
cd "Skeleton Backend/sioree-backend"
npm run migrate
```

### 2. Restart Backend Server

```bash
cd "Skeleton Backend/sioree-backend"
npm run dev
```

### 3. Test Sign Up / Login

- Open iOS app
- Try to sign up or login
- Should work now! ✅

## 📋 What Changed

### Backend (`src/routes/auth.js`)

**Before:**
- Used SQLite syntax: `db.prepare()`
- Returned: `{ accessToken, refreshToken, user }`
- User object was incomplete

**After:**
- Uses PostgreSQL syntax: `db.query()`
- Returns: `{ token, user }`
- User object includes all required fields

### Database Schema

Added columns to `users` table:
- `name`
- `bio`
- `avatar`
- `user_type`
- `location`
- `verified`
- `follower_count`
- `following_count`
- `event_count`

## ✅ Test It

1. **Sign Up:**
   - Email: `test@example.com`
   - Password: `password123`
   - Username: `testuser`
   - Name: `Test User`
   - User Type: `partier`

2. **Login:**
   - Email: `test@example.com`
   - Password: `password123`

3. **Check:**
   - Should successfully authenticate
   - User data should load correctly
   - No JSON parsing errors

## 🐛 If Still Not Working

1. **Check backend logs:**
   ```bash
   # Look for errors in terminal where backend is running
   ```

2. **Check database connection:**
   - Make sure `DATABASE_URL` in `.env` is correct
   - Test connection in Supabase dashboard

3. **Check iOS app logs:**
   - Look in Xcode console for network errors
   - Check if backend URL is correct

4. **Verify database columns:**
   ```sql
   -- Run in Supabase SQL Editor
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'users';
   ```

## 🎉 Done!

After running the migration and restarting the backend, sign up/login should work perfectly!


