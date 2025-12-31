-- Update booking statuses to match new enum values
-- Note: This migration updates existing statuses to match the new BookingStatus enum

-- Update existing 'pending' statuses to 'requested' (initial state)
UPDATE bookings SET status = 'requested' WHERE status = 'pending';

-- Update existing 'cancelled' statuses to 'canceled' (to match enum casing)
UPDATE bookings SET status = 'canceled' WHERE status = 'cancelled';

-- Ensure all statuses are valid according to the new enum
-- Any invalid statuses will be set to 'requested' as a fallback
UPDATE bookings SET status = 'requested'
WHERE status NOT IN ('requested', 'accepted', 'awaiting_payment', 'confirmed', 'declined', 'expired', 'canceled', 'completed');
