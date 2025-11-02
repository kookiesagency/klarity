-- =====================================================
-- Bank of Baroda Account Breakdown
-- =====================================================
-- This shows detailed calculation for Bank of Baroda account

-- Step 1: Get account info
SELECT
    '=== BANK OF BARODA ACCOUNT INFO ===' as info;

SELECT
    name as "Account Name",
    opening_balance as "Opening Balance",
    current_balance as "Current Balance in DB",
    created_at as "Account Created On"
FROM public.accounts
WHERE name = 'Bank of Baroda';

-- Step 2: Show ALL income transactions
SELECT
    '=== ALL INCOME TRANSACTIONS ===' as info;

SELECT
    transaction_date as "Date",
    c.name as "Category",
    amount as "Amount",
    description as "Description"
FROM public.transactions t
JOIN public.categories c ON c.id = t.category_id
WHERE t.account_id = (SELECT id FROM public.accounts WHERE name = 'Bank of Baroda')
AND t.type = 'income'
ORDER BY transaction_date DESC;

-- Step 3: Show total income
SELECT
    'TOTAL INCOME' as "Summary",
    COALESCE(SUM(amount), 0) as "Total"
FROM public.transactions t
WHERE t.account_id = (SELECT id FROM public.accounts WHERE name = 'Bank of Baroda')
AND t.type = 'income';

-- Step 4: Show ALL expense transactions
SELECT
    '=== ALL EXPENSE TRANSACTIONS ===' as info;

SELECT
    transaction_date as "Date",
    c.name as "Category",
    amount as "Amount",
    description as "Description"
FROM public.transactions t
JOIN public.categories c ON c.id = t.category_id
WHERE t.account_id = (SELECT id FROM public.accounts WHERE name = 'Bank of Baroda')
AND t.type = 'expense'
ORDER BY transaction_date DESC;

-- Step 5: Show total expenses
SELECT
    'TOTAL EXPENSES' as "Summary",
    COALESCE(SUM(amount), 0) as "Total"
FROM public.transactions t
WHERE t.account_id = (SELECT id FROM public.accounts WHERE name = 'Bank of Baroda')
AND t.type = 'expense';

-- Step 6: Show final calculation
SELECT
    '=== FINAL CALCULATION ===' as info;

SELECT
    a.opening_balance as "Opening Balance",
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) as "Total Income",
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) as "Total Expenses",
    (a.opening_balance +
     COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) -
     COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)
    ) as "Calculated Balance",
    a.current_balance as "Current Balance in DB",
    CASE
        WHEN a.current_balance = (a.opening_balance +
                                  COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) -
                                  COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0))
        THEN '✅ CORRECT'
        ELSE '❌ MISMATCH'
    END as "Status"
FROM public.accounts a
LEFT JOIN public.transactions t ON t.account_id = a.id
WHERE a.name = 'Bank of Baroda'
GROUP BY a.id, a.name, a.opening_balance, a.current_balance;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'BANK OF BARODA DETAILED BREAKDOWN';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Check the results above to see:';
    RAISE NOTICE '- Opening balance when account was created';
    RAISE NOTICE '- All income transactions';
    RAISE NOTICE '- All expense transactions';
    RAISE NOTICE '- Final calculation';
END $$;
