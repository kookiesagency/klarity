-- =====================================================
-- Fix Transfer Double Balance Update Bug
-- =====================================================
-- This script removes the redundant transfer trigger
-- that was causing balances to be updated twice
--
-- Run this in your Supabase SQL Editor

-- Drop the transfer balance update trigger
DROP TRIGGER IF EXISTS update_balance_on_transfer_trigger ON public.transfers;

-- Drop the transfer balance update function
DROP FUNCTION IF EXISTS update_balance_on_transfer();

-- =====================================================
-- EXPLANATION
-- =====================================================
-- The balance updates are already handled by the transaction trigger
-- (update_balance_on_transaction) which runs when the linked
-- transactions are created. Having both triggers causes double updates.
--
-- After this fix, transfers will work correctly:
-- 1. Transfer record is created (no balance update)
-- 2. Expense transaction is created → savings balance decreases
-- 3. Income transaction is created → credit card balance increases
--
-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Transfer double balance update bug fixed!';
    RAISE NOTICE 'Transfers will now update balances correctly.';
    RAISE NOTICE '';
    RAISE NOTICE 'IMPORTANT: Your existing account balances may be incorrect.';
    RAISE NOTICE 'You may need to manually correct them or re-create your accounts.';
END $$;
