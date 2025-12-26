-- Add array-based storage for events looking for talent and optional notes
ALTER TABLE events
ADD COLUMN IF NOT EXISTS looking_for_roles TEXT[] DEFAULT '{}'::text[];

ALTER TABLE events
ADD COLUMN IF NOT EXISTS looking_for_notes TEXT;

-- Backfill array values from legacy single-field column
UPDATE events
SET looking_for_roles = ARRAY[looking_for_talent_type]
WHERE looking_for_talent_type IS NOT NULL
  AND looking_for_talent_type <> ''
  AND (looking_for_roles IS NULL OR array_length(looking_for_roles, 1) = 0);

-- Normalize nulls to empty arrays for consistency
UPDATE events
SET looking_for_roles = '{}'::text[]
WHERE looking_for_roles IS NULL;
