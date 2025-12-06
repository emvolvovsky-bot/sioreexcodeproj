# Cloud Database Setup Guide (No Installation Required)

This guide shows you how to set up a PostgreSQL database in the cloud without installing anything on your computer.

---

## 🎯 Recommended: Supabase (Easiest & Free)

### Step 1: Create Account (2 minutes)

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"**
3. Sign up with:
   - GitHub (easiest)
   - Google
   - Email

### Step 2: Create Project (3 minutes)

1. Click **"New Project"**
2. Fill in:
   - **Organization:** Create new or use existing
   - **Project Name:** `sioree`
   - **Database Password:** Create a strong password (SAVE THIS!)
   - **Region:** Choose closest to you (e.g., US East)
3. Click **"Create new project"**
4. Wait 2-3 minutes for setup

### Step 3: Get Database URL (1 minute)

1. In your project dashboard, click **Settings** (gear icon)
2. Click **Database** in left sidebar
3. Scroll to **"Connection string"** section
4. Under **"Connection pooling"**, copy the connection string
   - It looks like: `postgresql://postgres.xxxxx:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres`
   - **Important:** Replace `[YOUR-PASSWORD]` with the password you created

### Step 4: Run Database Migrations (5 minutes)

1. In Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **"New query"**
3. Open `backend/migrations/001_initial_schema.sql` in your code editor
4. Copy the entire contents
5. Paste into Supabase SQL Editor
6. Click **"Run"** (or press Cmd+Enter)
7. ✅ You should see "Success. No rows returned"

### Step 5: Update `.env` File (1 minute)

1. Open `backend/.env` file
2. Find the line: `DATABASE_URL=postgresql://localhost:5432/sioree`
3. Replace it with your Supabase connection string:
   ```bash
   DATABASE_URL=postgresql://postgres.xxxxx:YOUR_PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres
   ```
   (Use the actual connection string from Step 3)

4. Save the file

### Step 6: Test Connection (1 minute)

1. Start your backend:
   ```bash
   cd backend
   npm install  # If not done yet
   npm run dev
   ```

2. You should see:
   ```
   ✅ PostgreSQL connected: [timestamp]
   🚀 Sioree backend server running on port 4000
   ```

**Total Time: ~15 minutes**

---

## 🚀 Alternative: Neon (Also Free & Easy)

### Step 1: Create Account

1. Go to [https://neon.tech](https://neon.tech)
2. Click **"Sign Up"**
3. Sign up with GitHub/Google

### Step 2: Create Project

1. Click **"Create a project"**
2. Project name: `sioree`
3. Click **"Create project"**

### Step 3: Get Connection String

1. In dashboard, you'll see **"Connection string"**
2. Copy it (looks like: `postgresql://user:password@ep-xxxxx.us-east-2.aws.neon.tech/neondb`)

### Step 4: Run Migrations

1. Click **"SQL Editor"** in left sidebar
2. Click **"New query"**
3. Copy/paste contents of `backend/migrations/001_initial_schema.sql`
4. Click **"Run"**

### Step 5: Update `.env`

```bash
DATABASE_URL=[paste connection string from Step 3]
```

**Total Time: ~10 minutes**

---

## 🚂 Alternative: Railway (Auto-Setup)

### Step 1: Create Account

1. Go to [https://railway.app](https://railway.app)
2. Sign up with GitHub

### Step 2: Create Project

1. Click **"New Project"**
2. Select **"Provision PostgreSQL"**
3. Railway automatically creates database

### Step 3: Get Connection String

1. Click on **PostgreSQL** service
2. Go to **"Variables"** tab
3. Copy `DATABASE_URL` value

### Step 4: Run Migrations

1. Click **"Query"** tab in PostgreSQL service
2. Copy/paste `backend/migrations/001_initial_schema.sql`
3. Click **"Run"**

### Step 5: Update `.env`

```bash
DATABASE_URL=[paste from Railway Variables]
```

**Total Time: ~10 minutes**

---

## ✅ Quick Comparison

| Service | Free Tier | Setup Time | Easiest |
|---------|----------|------------|---------|
| **Supabase** | ✅ Yes | 15 min | ⭐⭐⭐⭐⭐ |
| **Neon** | ✅ Yes | 10 min | ⭐⭐⭐⭐ |
| **Railway** | ✅ Yes (limited) | 10 min | ⭐⭐⭐⭐ |
| **Heroku** | ⚠️ Limited | 20 min | ⭐⭐⭐ |

**Recommendation:** Start with **Supabase** - it's the easiest and has the best free tier.

---

## 🎯 Next Steps After Database Setup

1. ✅ Database is set up
2. ⚠️ Update `.env` with database URL
3. ⚠️ Add Stripe test keys to `.env`
4. ⚠️ Run `npm install` in backend folder
5. ⚠️ Start backend: `npm run dev`
6. ⚠️ Test: `curl http://localhost:4000/health`

---

## 🚨 Troubleshooting

**"Connection refused"**
- Check your `.env` file has correct `DATABASE_URL`
- Make sure you replaced `[YOUR-PASSWORD]` with actual password
- Verify database is running (check Supabase/Neon/Railway dashboard)

**"Authentication failed"**
- Double-check password in connection string
- Make sure you're using the correct connection string (pooler vs direct)

**"Database does not exist"**
- Make sure migrations ran successfully
- Check SQL Editor for any errors

---

**You're all set!** No PostgreSQL installation needed. 🎉


