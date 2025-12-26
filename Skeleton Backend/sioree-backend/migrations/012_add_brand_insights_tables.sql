-- Create event_impressions table to track when partiers click on promoted events
CREATE TABLE IF NOT EXISTS event_impressions (
    id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    brand_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create unique index to prevent duplicate impressions per user per event per day
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_impressions_unique 
ON event_impressions(event_id, user_id, DATE(created_at));

-- Create brand_cities table to track cities where brands have promoted events
CREATE TABLE IF NOT EXISTS brand_cities (
    id SERIAL PRIMARY KEY,
    brand_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    activated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(brand_id, city)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_event_impressions_event_id ON event_impressions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_impressions_brand_id ON event_impressions(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_cities_brand_id ON brand_cities(brand_id);

