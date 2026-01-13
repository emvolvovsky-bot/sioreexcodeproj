-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Add Stripe Connect fields to users table for host onboarding
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_account_id VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_charges_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_payouts_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_onboarding_complete BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_onboarding_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_refresh_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_expires_at TIMESTAMP;

-- Update events table to include platform fee information
ALTER TABLE events ADD COLUMN IF NOT EXISTS ticket_price_cents INTEGER;
ALTER TABLE events ADD COLUMN IF NOT EXISTS platform_fee_bps INTEGER DEFAULT 200; -- 2% = 200 basis points
ALTER TABLE events ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'cancelled'));
ALTER TABLE events ADD COLUMN IF NOT EXISTS published_at TIMESTAMP;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create tickets table for tracking ticket purchases
CREATE TABLE IF NOT EXISTS tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    buyer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    ticket_amount_cents INTEGER NOT NULL, -- Amount per ticket (excluding fees)
    fees_amount_cents INTEGER NOT NULL, -- Platform fees
    total_amount_cents INTEGER NOT NULL, -- Total paid
    stripe_payment_intent_id VARCHAR(255) UNIQUE,
    stripe_charge_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'paid' CHECK (status IN ('paid', 'refunded', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for tickets
CREATE INDEX IF NOT EXISTS idx_tickets_event ON tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_buyer ON tickets(buyer_id);
CREATE INDEX IF NOT EXISTS idx_tickets_payment_intent ON tickets(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);

-- Update trigger for tickets updated_at
CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add webhook event tracking for idempotency
CREATE TABLE IF NOT EXISTS stripe_webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP,
    data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_event_id ON stripe_webhook_events(event_id);
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_processed ON stripe_webhook_events(processed);
