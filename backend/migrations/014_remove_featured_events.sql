-- Remove featured events functionality
-- Migration: 014_remove_featured_events.sql

-- Drop the index on is_featured column first
DROP INDEX IF EXISTS idx_events_featured;

-- Drop the is_featured column from events table
ALTER TABLE events DROP COLUMN IF EXISTS is_featured;