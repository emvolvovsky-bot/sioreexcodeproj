-- Add event and booking references to conversations for event-linked messaging
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS event_id INTEGER REFERENCES events(id) ON DELETE CASCADE;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS title VARCHAR(255); -- For event/booking context

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_event ON conversations(event_id);
CREATE INDEX IF NOT EXISTS idx_conversations_booking ON conversations(booking_id);

-- Ensure conversations are unique per booking (one conversation per booking)
ALTER TABLE conversations ADD CONSTRAINT IF NOT EXISTS unique_booking_conversation UNIQUE (booking_id);
