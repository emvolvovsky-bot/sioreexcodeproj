# Running Migration on Render - Quick Guide

## Since the script file isn't on Render yet, run the SQL directly:

### Step 1: Check if migration file exists
```bash
ls -la migrations/010_add_group_chats.sql
```

### Step 2: If the file exists, run it:
```bash
psql $DATABASE_URL -f migrations/010_add_group_chats.sql
```

### Step 3: If DATABASE_URL isn't set, get it from Render:
1. Go to Render Dashboard
2. Click on your PostgreSQL database
3. Go to "Info" or "Connect" tab
4. Copy the "Internal Database URL" or connection string
5. Run:
```bash
psql "postgresql://user:password@host:port/database" -f migrations/010_add_group_chats.sql
```

### Alternative: Run SQL directly via psql interactive mode:
```bash
psql $DATABASE_URL
```

Then paste and execute:
```sql
-- Add group chat support to conversations table
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS title VARCHAR(255);

UPDATE conversations SET is_group = FALSE WHERE is_group IS NULL;

CREATE TABLE IF NOT EXISTS group_members (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_conversation ON group_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members(user_id);

ALTER TABLE messages
ADD COLUMN IF NOT EXISTS sender_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS receiver_role VARCHAR(50);
```

Type `\q` to exit psql when done.

