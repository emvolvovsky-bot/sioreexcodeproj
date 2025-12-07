-- Add sender_role column to messages table to support role-based messaging
-- This allows messages to be separated by role (partier, talent, host, brand)

ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS sender_role VARCHAR(50);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_sender_role ON messages(sender_id, sender_role);

-- Update existing messages to have a default role (can be updated later)
UPDATE messages 
SET sender_role = (SELECT user_type FROM users WHERE id = messages.sender_id)
WHERE sender_role IS NULL;

