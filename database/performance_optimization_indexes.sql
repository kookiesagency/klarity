-- =====================================================
-- Performance Optimization - Composite Indexes
-- =====================================================
-- Run this in your Supabase SQL Editor to add composite indexes
-- for better query performance

-- Composite index for date range queries on transactions
-- Used in: getTransactionsByDateRange, analytics queries
CREATE INDEX IF NOT EXISTS idx_transactions_profile_date
ON public.transactions(profile_id, transaction_date DESC);

-- Composite index for budget spending calculations
-- Used in: getCategorySpending for budget tracking
CREATE INDEX IF NOT EXISTS idx_transactions_budget_spending
ON public.transactions(profile_id, category_id, type, transaction_date);

-- Composite index for active budgets query
-- Used in: getBudgets to filter active budgets efficiently
CREATE INDEX IF NOT EXISTS idx_budgets_profile_active
ON public.budgets(profile_id, is_active);

-- Composite index for transaction listing with lock status
-- Used in: transaction list screens to show locked/unlocked transactions
CREATE INDEX IF NOT EXISTS idx_transactions_profile_lock_date
ON public.transactions(profile_id, is_locked, transaction_date DESC);

-- Composite index for auto-lock queries
-- Used in: autoLockOldTransactions to find old unlocked transactions
CREATE INDEX IF NOT EXISTS idx_transactions_lock_check
ON public.transactions(profile_id, transaction_date, is_locked)
WHERE is_locked = false;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Performance indexes added successfully!';
    RAISE NOTICE 'Query performance should be significantly improved.';
END $$;
