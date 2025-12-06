-- Migration: Add event promotions table for brands to promote events
-- This allows brands to feature/promote events, making them appear in the "Featured" section

CREATE TABLE IF NOT EXISTS event_promotions (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    brand_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    promoted_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    promotion_budget DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(event_id, brand_id)
);

CREATE INDEX IF NOT EXISTS idx_event_promotions_event_id ON event_promotions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_promotions_brand_id ON event_promotions(brand_id);
CREATE INDEX IF NOT EXISTS idx_event_promotions_active ON event_promotions(is_active, expires_at);

-- Add is_featured column to events table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='events' AND column_name='is_featured') THEN
        ALTER TABLE events ADD COLUMN is_featured BOOLEAN DEFAULT false;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_events_featured ON events(is_featured, event_date);

