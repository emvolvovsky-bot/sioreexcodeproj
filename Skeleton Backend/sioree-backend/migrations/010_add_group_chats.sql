-- Add group chat support to conversations table
-- First, ensure is_group column exists with default value
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS title VARCHAR(255);

-- Update existing conversations to explicitly set is_group = false
UPDATE conversations SET is_group = FALSE WHERE is_group IS NULL;

-- Make participant columns nullable for group chats (if they exist)
-- Note: This allows NULL for group chats while keeping existing conversations valid
DO $$ 
BEGIN
  -- Make user1_id nullable if it exists (added in migration 003)
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'user1_id') THEN
    ALTER TABLE conversations ALTER COLUMN user1_id DROP NOT NULL;
  END IF;
  
  -- Make user2_id nullable if it exists (added in migration 003)
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'user2_id') THEN
    ALTER TABLE conversations ALTER COLUMN user2_id DROP NOT NULL;
  END IF;
END $$;

-- Create group_members table for group chat membership
CREATE TABLE IF NOT EXISTS group_members (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member', -- 'admin', 'member'
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (conversation_id, user_id)
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_group_members_conversation ON group_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members(user_id);

-- Update messages table to support group chats (already has conversation_id)
-- Add sender_role and receiver_role if not exists (from previous migration)
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS sender_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS receiver_role VARCHAR(50);








