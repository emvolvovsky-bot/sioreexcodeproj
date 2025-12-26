-- Add looking_for_talent_type and talent_ids to events
ALTER TABLE events
ADD COLUMN IF NOT EXISTS looking_for_talent_type TEXT;

ALTER TABLE events
ADD COLUMN IF NOT EXISTS talent_ids TEXT[] DEFAULT '{}'::text[];

-- Ensure defaults are applied to existing rows
UPDATE events SET talent_ids = '{}'::text[] WHERE talent_ids IS NULL;
