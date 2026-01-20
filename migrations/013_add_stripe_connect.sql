-- Add Stripe Connect fields for payouts
ALTER TABLE users
ADD COLUMN IF NOT EXISTS stripe_account_id TEXT;

ALTER TABLE bank_accounts
ADD COLUMN IF NOT EXISTS stripe_external_account_id TEXT;

ALTER TABLE bank_accounts
ADD COLUMN IF NOT EXISTS account_type VARCHAR(20);

ALTER TABLE bank_accounts
ADD COLUMN IF NOT EXISTS last4 VARCHAR(4);

ALTER TABLE withdrawals
ADD COLUMN IF NOT EXISTS stripe_payout_id TEXT;
