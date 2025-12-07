-- Migration: Add talent needs to events
-- This allows hosts to specify what type of talent they're looking for

-- Add column to store talent type needed (e.g., "DJ", "Bartender", etc.)
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS looking_for_talent_type VARCHAR(50);

-- Add index for faster queries when talent search for events
CREATE INDEX IF NOT EXISTS idx_events_looking_for_talent_type 
ON events(looking_for_talent_type) 
WHERE looking_for_talent_type IS NOT NULL;

-- Add comment
COMMENT ON COLUMN events.looking_for_talent_type IS 'Type of talent the host is looking for (e.g., DJ, Bartender, Security). If set, talent of this type can find this event in their gigs search.';

