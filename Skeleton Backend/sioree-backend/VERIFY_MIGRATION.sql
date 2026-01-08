-- Verify Group Chat Migration Success
-- Run these queries in Supabase SQL Editor to confirm everything was created

-- 1. Check if is_group column exists in conversations table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'conversations' 
  AND column_name IN ('is_group', 'created_by', 'title');

-- 2. Check if group_members table exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'group_members'
ORDER BY ordinal_position;

-- 3. Check if indexes were created
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename = 'group_members';

-- 4. Check if sender_role and receiver_role columns exist in messages table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND column_name IN ('sender_role', 'receiver_role');

-- Expected Results:
-- 1. Should return 3 rows: is_group (boolean), created_by (integer), title (character varying)
-- 2. Should return 5 rows: id, conversation_id, user_id, role, joined_at
-- 3. Should return 2 index rows: idx_group_members_conversation, idx_group_members_user
-- 4. Should return 2 rows: sender_role, receiver_role

