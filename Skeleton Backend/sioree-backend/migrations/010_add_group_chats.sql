-- Add group chat members table
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

-- Update conversations table to ensure is_group and title columns exist
ALTER TABLE conversations
ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS title VARCHAR(255);

-- Update messages table to support group chats (already has conversation_id)
-- Add sender_role and receiver_role if not exists (from previous migration)
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS sender_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS receiver_role VARCHAR(50);








