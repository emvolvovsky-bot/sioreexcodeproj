-- Update conversations table to support 1-on-1 conversations
ALTER TABLE conversations 
ADD COLUMN IF NOT EXISTS user1_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS user2_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Update messages table structure
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS receiver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS text TEXT,
ADD COLUMN IF NOT EXISTS message_type VARCHAR(50) DEFAULT 'text',
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;

-- If content exists but text doesn't, copy content to text
UPDATE messages SET text = content WHERE text IS NULL AND content IS NOT NULL;

-- Add follow relationships table
CREATE TABLE IF NOT EXISTS follows (
    id SERIAL PRIMARY KEY,
    follower_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    following_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (follower_id, following_id)
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_conversations_users ON conversations(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);


