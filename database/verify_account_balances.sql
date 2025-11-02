-- =====================================================
-- Verify Account Balances Are Correct
-- =====================================================
-- This script checks if your account balances match
-- the calculated balances based on transactions
--
-- Run this in Supabase SQL Editor to verify everything is correct

SELECT
    a.name as "Account Name",
    a.type as "Account Type",
    a.opening_balance as "Opening Balance",
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) as "Total Income",
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) as "Total Expense",
    a.current_balance as "Current Balance (DB)",
    (a.opening_balance +
     COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) -
     COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)
    ) as "Calculated Balance",
    CASE
        WHEN a.current_balance = (a.opening_balance +
                                  COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) -
                                  COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0))
        THEN '✅ CORRECT'
        ELSE '❌ MISMATCH'
    END as "Status"
FROM public.accounts a
LEFT JOIN public.transactions t ON t.account_id = a.id
GROUP BY a.id, a.name, a.type, a.opening_balance, a.current_balance
ORDER BY a.name;

-- Show transfer transactions specifically
SELECT
    '--- Transfer Transactions ---' as "Info";

SELECT
    t.transaction_date as "Date",
    t.type as "Type",
    a.name as "Account",
    c.name as "Category",
    t.amount as "Amount",
    t.description as "Description"
FROM public.transactions t
JOIN public.accounts a ON a.id = t.account_id
JOIN public.categories c ON c.id = t.category_id
WHERE c.name = 'Transfer'
ORDER BY t.transaction_date DESC, t.created_at DESC;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VERIFICATION COMPLETE';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Check the results above:';
    RAISE NOTICE '- All accounts should show "✅ CORRECT" status';
    RAISE NOTICE '- Current Balance (DB) should match Calculated Balance';
    RAISE NOTICE '';
    RAISE NOTICE 'If you see "❌ MISMATCH", run recalculate_account_balances.sql again';
    RAISE NOTICE '';
END $$;
