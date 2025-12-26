-- Migration: Add event_talent junction table
-- This table links events to specific talent that are booked for the event

CREATE TABLE IF NOT EXISTS event_talent (
    id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
    talent_id INTEGER REFERENCES talent(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(event_id, talent_id)
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_event_talent_event_id ON event_talent(event_id);
CREATE INDEX IF NOT EXISTS idx_event_talent_talent_id ON event_talent(talent_id);

COMMENT ON TABLE event_talent IS 'Junction table linking events to specific talent that are booked for the event';








