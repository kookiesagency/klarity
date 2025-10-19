-- ============================================================================
-- AUTOMATIC SCHEDULED PAYMENTS TEST DATA
-- ============================================================================
-- This script automatically fetches your IDs and inserts test data
-- Just run this entire script in Supabase SQL Editor!

DO $$
DECLARE
    v_profile_id UUID;
    v_account_id UUID;
    v_expense_category_id UUID;
    v_income_category_id UUID;
BEGIN
    -- Get first account ID and its profile_id (this ensures we have both)
    SELECT id, profile_id INTO v_account_id, v_profile_id
    FROM public.accounts
    LIMIT 1;

    -- Get first expense category ID
    SELECT id INTO v_expense_category_id
    FROM public.categories
    WHERE type = 'expense'
    LIMIT 1;

    -- Get first income category ID
    SELECT id INTO v_income_category_id
    FROM public.categories
    WHERE type = 'income'
    LIMIT 1;

    -- Verify we got all required IDs
    IF v_account_id IS NULL OR v_profile_id IS NULL THEN
        RAISE EXCEPTION 'No accounts found. Please create an account first.';
    END IF;

    IF v_expense_category_id IS NULL THEN
        RAISE EXCEPTION 'No expense categories found. Please create expense categories first.';
    END IF;

    IF v_income_category_id IS NULL THEN
        RAISE EXCEPTION 'No income categories found. Please create income categories first.';
    END IF;

    RAISE NOTICE 'Using Profile ID: %', v_profile_id;
    RAISE NOTICE 'Using Account ID: %', v_account_id;
    RAISE NOTICE 'Using Expense Category ID: %', v_expense_category_id;
    RAISE NOTICE 'Using Income Category ID: %', v_income_category_id;

    -- ========================================================================
    -- INSERT TEST DATA
    -- ========================================================================

    -- 1. Overdue Expense - Rent Payment (5 days overdue)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        25000.00, 25000.00, 0.00,
        'ABC Properties', 'Monthly rent payment',
        CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE - INTERVAL '7 days',
        false, true, 'pending'
    );

    -- 2. Due Today - Electricity Bill (auto-create enabled)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        3500.00, 3500.00, 0.00,
        'Power Company', 'Monthly electricity bill',
        CURRENT_DATE, CURRENT_DATE - INTERVAL '1 day',
        false, true, 'pending'
    );

    -- 3. Upcoming - Internet Bill (due in 3 days)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        1500.00, 1500.00, 0.00,
        'ISP Provider', 'Monthly internet subscription',
        CURRENT_DATE + INTERVAL '3 days', CURRENT_DATE + INTERVAL '1 day',
        false, true, 'pending'
    );

    -- 4. Partial Payment - Loan EMI (50% paid)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        10000.00, 10000.00, 5000.00,
        'Bank Loan', 'Monthly EMI payment',
        CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE + INTERVAL '5 days',
        true, false, 'partial'
    );

    -- 5. Income - Freelance Payment Expected
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_income_category_id, 'income',
        50000.00, 50000.00, 0.00,
        'Client ABC', 'Freelance project payment',
        CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE + INTERVAL '3 days',
        true, false, 'pending'
    );

    -- 6. Completed Payment - Insurance Premium
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, completed_at,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        5000.00, 5000.00, 5000.00,
        'Insurance Co.', 'Monthly insurance premium',
        CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '9 days',
        false, true, 'completed'
    );

    -- 7. Upcoming - Mobile Recharge (no reminder)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        599.00, 599.00, 0.00,
        'Mobile Operator', 'Monthly mobile plan',
        CURRENT_DATE + INTERVAL '15 days',
        false, true, 'pending'
    );

    -- 8. Large Partial Payment - House Purchase Installment (40% paid)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        500000.00, 500000.00, 200000.00,
        'Builder XYZ', 'House down payment - 2nd installment',
        CURRENT_DATE + INTERVAL '20 days', CURRENT_DATE + INTERVAL '15 days',
        true, false, 'partial'
    );

    -- 9. Income - Salary Expected
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date, reminder_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_income_category_id, 'income',
        75000.00, 75000.00, 0.00,
        'Employer Name', 'Monthly salary',
        CURRENT_DATE + INTERVAL '25 days', CURRENT_DATE + INTERVAL '23 days',
        false, false, 'pending'
    );

    -- 10. Overdue with Partial Payment - Credit Card Bill (2 days overdue)
    INSERT INTO public.scheduled_payments (
        profile_id, account_id, category_id, type,
        amount, total_amount, paid_amount,
        payee_name, description, due_date,
        allow_partial_payment, auto_create_transaction, status
    ) VALUES (
        v_profile_id, v_account_id, v_expense_category_id, 'expense',
        15000.00, 15000.00, 5000.00,
        'Credit Card Co.', 'Credit card minimum payment',
        CURRENT_DATE - INTERVAL '2 days',
        true, false, 'partial'
    );

    RAISE NOTICE '✅ Successfully inserted 10 scheduled payments!';
    RAISE NOTICE 'Breakdown:';
    RAISE NOTICE '  - 2 overdue payments (Rent, Credit Card)';
    RAISE NOTICE '  - 1 due today (Electricity)';
    RAISE NOTICE '  - 5 upcoming payments';
    RAISE NOTICE '  - 3 with partial payments';
    RAISE NOTICE '  - 1 completed payment';
    RAISE NOTICE '  - 2 income payments expected';

END $$;

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Run this to see all your scheduled payments
SELECT
    sp.payee_name,
    sp.type,
    '₹' || sp.total_amount as amount,
    '₹' || sp.paid_amount as paid,
    sp.due_date::date as due_date,
    sp.status,
    CASE
        WHEN sp.due_date::date < CURRENT_DATE AND sp.status != 'completed' THEN '🔴 OVERDUE'
        WHEN sp.due_date::date = CURRENT_DATE THEN '🟡 DUE TODAY'
        WHEN sp.due_date::date > CURRENT_DATE THEN '🟢 UPCOMING'
        ELSE '✅ COMPLETED'
    END as payment_status,
    sp.auto_create_transaction as auto_create
FROM public.scheduled_payments sp
ORDER BY sp.due_date;
