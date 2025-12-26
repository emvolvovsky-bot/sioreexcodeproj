-- Add user_type column to follows table to track which role the user was using when following
-- This allows separate followers/following lists for each user type (partier, host, talent, brand)
ALTER TABLE follows ADD COLUMN IF NOT EXISTS follower_user_type VARCHAR(50);
ALTER TABLE follows ADD COLUMN IF NOT EXISTS following_user_type VARCHAR(50);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_follows_follower_user_type ON follows(follower_id, follower_user_type);
CREATE INDEX IF NOT EXISTS idx_follows_following_user_type ON follows(following_id, following_user_type);








