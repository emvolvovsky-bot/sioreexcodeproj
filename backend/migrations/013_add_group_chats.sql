-- Add group chat support to conversations table
-- First, ensure is_group column exists with default value
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS title VARCHAR(255);

-- Update existing conversations to explicitly set is_group = false
UPDATE conversations SET is_group = FALSE WHERE is_group IS NULL;

-- Make participant columns nullable for group chats
-- Note: This allows NULL for group chats while keeping existing conversations valid
ALTER TABLE conversations 
  ALTER COLUMN participant1_id DROP NOT NULL,
  ALTER COLUMN participant2_id DROP NOT NULL;

-- Create group_members table for group chat membership
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member', -- 'admin', 'member'
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (conversation_id, user_id)
);

-- Add indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_group_members_conversation ON group_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members(user_id);

-- Add constraint: group chats must have created_by, regular chats must have participants
-- Drop constraint if it exists first to allow re-running migration
ALTER TABLE conversations DROP CONSTRAINT IF EXISTS check_group_chat_constraints;

ALTER TABLE conversations
  ADD CONSTRAINT check_group_chat_constraints 
  CHECK (
    (is_group = TRUE AND created_by IS NOT NULL AND participant1_id IS NULL AND participant2_id IS NULL) OR
    (is_group = FALSE AND participant1_id IS NOT NULL AND participant2_id IS NOT NULL)
  );

