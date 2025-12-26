-- Add event_id column to posts table to link posts to events
ALTER TABLE posts
ADD COLUMN IF NOT EXISTS event_id INTEGER REFERENCES events(id) ON DELETE SET NULL;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_posts_event_id ON posts(event_id);








