-- Add updated_at timestamps and client_temp_id for message reconciliation
ALTER TABLE IF EXISTS conversations
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

ALTER TABLE IF EXISTS messages
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS client_temp_id VARCHAR(255);

ALTER TABLE IF EXISTS users
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Ensure updated_at is set on update via trigger (Postgres)
CREATE OR REPLACE FUNCTION set_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers (drop if exists then create) to ensure idempotency
DROP TRIGGER IF EXISTS set_updated_at_trigger_messages ON messages;
CREATE TRIGGER set_updated_at_trigger_messages
BEFORE UPDATE ON messages
FOR EACH ROW EXECUTE PROCEDURE set_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_trigger_conversations ON conversations;
CREATE TRIGGER set_updated_at_trigger_conversations
BEFORE UPDATE ON conversations
FOR EACH ROW EXECUTE PROCEDURE set_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_trigger_users ON users;
CREATE TRIGGER set_updated_at_trigger_users
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE PROCEDURE set_updated_at_column();

-- Indexes for fast delta queries
CREATE INDEX IF NOT EXISTS idx_messages_updated_at ON messages(updated_at);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at);
CREATE INDEX IF NOT EXISTS idx_users_updated_at ON users(updated_at);

