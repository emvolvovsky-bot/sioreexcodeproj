# Running Migration on Render

To run the group chat migration (`013_add_group_chats.sql`) on your Render database, you have several options:

## Option 1: Using Render Shell (Recommended)

1. Go to your Render dashboard
2. Navigate to your backend service
3. Click on the **Shell** tab (or use the "Open Shell" button)
4. Once in the shell, run:

```bash
cd backend
node run-migration.js
```

Or if you're in the project root:

```bash
cd backend && node run-migration.js
```

## Option 2: Using Render's Database Console

1. Go to your Render dashboard
2. Navigate to your PostgreSQL database service
3. Click on the **Connect** tab or **Info** tab
4. Copy your **Internal Database URL** or **External Connection String**
5. Use the **psql** command in a local terminal or Render Shell:

```bash
psql $DATABASE_URL -f backend/migrations/013_add_group_chats.sql
```

Or connect directly:

```bash
psql "postgresql://user:password@host:port/database" -f backend/migrations/013_add_group_chats.sql
```

## Option 3: Using npm Script (if you have shell access)

If you have shell access and npm scripts are available:

```bash
cd backend
npm run migrate:group-chats
```

## Option 4: Direct SQL Execution via Render Dashboard

1. Go to your PostgreSQL database in Render
2. Click on **Info** or **Connect** tab
3. Find the **Postgres connection info**
4. Use any PostgreSQL client (like pgAdmin, DBeaver, or psql) to connect
5. Copy and paste the contents of `backend/migrations/013_add_group_chats.sql` and execute it

## Option 5: Add to Server Startup (Automatic Migration)

If you want migrations to run automatically when the server starts, you can modify `backend/server.js` to include migration logic. However, this is **not recommended** for production as it can cause issues with multiple server instances.

---

## Stripe PaymentSheet curl test (optional)

Quick smoke test for the payment-sheet endpoint:

```bash
curl -i https://<YOUR-RENDER-DOMAIN>/payment-sheet
```

---

## Verify Migration Success

After running the migration, verify it worked by connecting to your database and running:

```sql
-- Check if group_members table exists
SELECT * FROM information_schema.tables WHERE table_name = 'group_members';

-- Check if is_group column exists in conversations
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'conversations' AND column_name = 'is_group';

-- Check if created_by column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'conversations' AND column_name = 'created_by';
```

All three queries should return results if the migration was successful.

---

## Troubleshooting

### Error: "relation already exists"
This means some parts of the migration already ran. The migration uses `IF NOT EXISTS` clauses, so this is safe to ignore for those parts.

### Error: "cannot drop NOT NULL constraint"
This might happen if you have existing conversations. The migration should handle this, but if it fails, you may need to temporarily make existing conversations nullable or handle them separately.

### Error: "constraint check_group_chat_constraints already exists"
The migration drops and recreates this constraint, so this should be handled automatically. If you see this error, it means the constraint is already there and the migration should continue.

---

**Note:** Make sure your `DATABASE_URL` environment variable is set correctly in your Render service settings!

