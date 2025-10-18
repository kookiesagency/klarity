-- Migration: Remove notes columns from tables
-- Keep only description field for user input
--
-- IMPORTANT: emi_payments.notes is NOT dropped because it's used internally
-- to track payment types (Manual/Auto-generated/Historical)

-- Drop notes column from transactions table
ALTER TABLE transactions
DROP COLUMN IF EXISTS notes;

-- Drop notes column from transfers table
ALTER TABLE transfers
DROP COLUMN IF EXISTS notes;

-- Drop notes column from recurring_transactions table
ALTER TABLE recurring_transactions
DROP COLUMN IF EXISTS notes;

-- Drop notes column from emis table (if exists)
ALTER TABLE emis
DROP COLUMN IF EXISTS notes;

-- Drop notes column from scheduled_payments table
ALTER TABLE scheduled_payments
DROP COLUMN IF EXISTS notes;

-- Note: emi_payments.notes is intentionally kept
-- It's used to store payment type indicators:
-- - "Manual payment" for user-created payments
-- - "Auto-generated payment" for scheduled payments
-- - "Historical payment" for backdated payments
