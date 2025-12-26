-- Add payment workflow tracking to bookings
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'pending_payment';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS refund_status VARCHAR(50) DEFAULT 'not_requested';

-- Track event lifecycle for cancellation and refunds
ALTER TABLE events ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'published';
ALTER TABLE events ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;
ALTER TABLE events ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
-- Ensure talent matching columns exist (defensive)
ALTER TABLE events ADD COLUMN IF NOT EXISTS looking_for_talent_type TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS talent_ids TEXT[] DEFAULT '{}'::text[];

-- Ledger for talent earnings (escrow-style)
CREATE TABLE IF NOT EXISTS talent_earnings (
    id SERIAL PRIMARY KEY,
    talent_id INTEGER REFERENCES talent(id) ON DELETE CASCADE,
    booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'available', -- available, pending_withdrawal, withdrawn, refunded
    available_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE talent_earnings ADD CONSTRAINT IF NOT EXISTS uniq_talent_earnings_booking UNIQUE (booking_id);

CREATE INDEX IF NOT EXISTS idx_talent_earnings_talent ON talent_earnings(talent_id);
CREATE INDEX IF NOT EXISTS idx_talent_earnings_status ON talent_earnings(status);

-- Withdrawal requests to bank accounts
CREATE TABLE IF NOT EXISTS withdrawals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    bank_account_id INTEGER REFERENCES bank_accounts(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user ON withdrawals(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_status ON withdrawals(status);


