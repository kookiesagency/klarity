-- Scheduled Payments Test Data
-- Run this after creating your accounts and categories
-- Replace PROFILE_ID, ACCOUNT_IDs, and CATEGORY_IDs with your actual IDs

-- First, let's get some IDs (you'll need to run queries to get these)
-- SELECT id, user_id FROM public.profiles LIMIT 1; -- Get your profile ID
-- SELECT id, name FROM public.accounts; -- Get account IDs
-- SELECT id, name FROM public.categories WHERE type = 'expense'; -- Get expense category IDs
-- SELECT id, name FROM public.categories WHERE type = 'income'; -- Get income category IDs

-- ============================================================================
-- EXAMPLE: Replace these placeholder IDs with your actual IDs
-- ============================================================================
-- Get your profile ID first:
-- SELECT id FROM public.profiles WHERE user_id = auth.uid();

-- Then replace in the SQL below:
-- YOUR_PROFILE_ID = your profile ID from above
-- YOUR_ACCOUNT_ID = your account ID
-- YOUR_EXPENSE_CATEGORY_ID = expense category ID
-- YOUR_INCOME_CATEGORY_ID = income category ID

-- ============================================================================
-- SCHEDULED PAYMENTS TEST DATA
-- ============================================================================

-- 1. Overdue Expense - Rent Payment (should show as overdue)
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    25000.00,
    25000.00,
    0.00,
    'ABC Properties',
    'Monthly rent payment',
    CURRENT_DATE - INTERVAL '5 days',
    CURRENT_DATE - INTERVAL '7 days',
    false,
    true,
    'pending'
);

-- 2. Due Today - Electricity Bill (auto-create enabled)
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    3500.00,
    3500.00,
    0.00,
    'Power Company',
    'Monthly electricity bill',
    CURRENT_DATE,
    CURRENT_DATE - INTERVAL '1 day',
    false,
    true,
    'pending'
);

-- 3. Upcoming - Internet Bill (due in 3 days)
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    1500.00,
    1500.00,
    0.00,
    'ISP Provider',
    'Monthly internet subscription',
    CURRENT_DATE + INTERVAL '3 days',
    CURRENT_DATE + INTERVAL '1 day',
    false,
    true,
    'pending'
);

-- 4. Partial Payment - Loan EMI (50% paid)
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    10000.00,
    10000.00,
    5000.00,
    'Bank Loan',
    'Monthly EMI payment',
    CURRENT_DATE + INTERVAL '7 days',
    CURRENT_DATE + INTERVAL '5 days',
    true,
    false,
    'partial'
);

-- 5. Income - Freelance Payment Expected
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_INCOME_CATEGORY_ID',
    'income',
    50000.00,
    50000.00,
    0.00,
    'Client ABC',
    'Freelance project payment',
    CURRENT_DATE + INTERVAL '5 days',
    CURRENT_DATE + INTERVAL '3 days',
    true,
    false,
    'pending'
);

-- 6. Completed Payment - Insurance Premium
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    completed_at,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    5000.00,
    5000.00,
    5000.00,
    'Insurance Co.',
    'Monthly insurance premium',
    CURRENT_DATE - INTERVAL '10 days',
    CURRENT_DATE - INTERVAL '9 days',
    false,
    true,
    'completed'
);

-- 7. Upcoming - Mobile Recharge (no reminder)
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    599.00,
    599.00,
    0.00,
    'Mobile Operator',
    'Monthly mobile plan',
    CURRENT_DATE + INTERVAL '15 days',
    false,
    true,
    'pending'
);

-- 8. Large Partial Payment - House Purchase Installment
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    500000.00,
    500000.00,
    200000.00,
    'Builder XYZ',
    'House down payment - 2nd installment',
    CURRENT_DATE + INTERVAL '20 days',
    CURRENT_DATE + INTERVAL '15 days',
    true,
    false,
    'partial'
);

-- 9. Income - Salary Expected
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    reminder_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_INCOME_CATEGORY_ID',
    'income',
    75000.00,
    75000.00,
    0.00,
    'Employer Name',
    'Monthly salary',
    CURRENT_DATE + INTERVAL '25 days',
    CURRENT_DATE + INTERVAL '23 days',
    false,
    false,
    'pending'
);

-- 10. Overdue with Partial Payment - Credit Card Bill
INSERT INTO public.scheduled_payments (
    profile_id,
    account_id,
    category_id,
    type,
    amount,
    total_amount,
    paid_amount,
    payee_name,
    description,
    due_date,
    allow_partial_payment,
    auto_create_transaction,
    status
) VALUES (
    'YOUR_PROFILE_ID',
    'YOUR_ACCOUNT_ID',
    'YOUR_EXPENSE_CATEGORY_ID',
    'expense',
    15000.00,
    15000.00,
    5000.00,
    'Credit Card Co.',
    'Credit card minimum payment',
    CURRENT_DATE - INTERVAL '2 days',
    true,
    false,
    'partial'
);

-- ============================================================================
-- PAYMENT HISTORY FOR PARTIAL PAYMENTS
-- ============================================================================

-- Get the IDs of partial payments (you'll need to get these after inserting above)
-- For demonstration, let's add payment history for the partial payments

-- Payment history for Loan EMI (assuming it's the 4th record)
-- You'll need to replace SCHEDULED_PAYMENT_ID with actual ID
INSERT INTO public.scheduled_payment_history (
    scheduled_payment_id,
    transaction_id,
    amount,
    payment_date,
    notes
) VALUES (
    'SCHEDULED_PAYMENT_ID_4',
    NULL, -- No transaction linked yet
    5000.00,
    CURRENT_DATE - INTERVAL '2 days',
    'First installment paid'
);

-- Payment history for House Purchase (assuming it's the 8th record)
INSERT INTO public.scheduled_payment_history (
    scheduled_payment_id,
    transaction_id,
    amount,
    payment_date,
    notes
) VALUES (
    'SCHEDULED_PAYMENT_ID_8',
    NULL,
    100000.00,
    CURRENT_DATE - INTERVAL '30 days',
    'First payment - 20%'
);

INSERT INTO public.scheduled_payment_history (
    scheduled_payment_id,
    transaction_id,
    amount,
    payment_date,
    notes
) VALUES (
    'SCHEDULED_PAYMENT_ID_8',
    NULL,
    100000.00,
    CURRENT_DATE - INTERVAL '15 days',
    'Second payment - 20%'
);

-- Payment history for Credit Card (assuming it's the 10th record)
INSERT INTO public.scheduled_payment_history (
    scheduled_payment_id,
    transaction_id,
    amount,
    payment_date,
    notes
) VALUES (
    'SCHEDULED_PAYMENT_ID_10',
    NULL,
    5000.00,
    CURRENT_DATE - INTERVAL '1 day',
    'Minimum payment made'
);

-- ============================================================================
-- HELPER QUERY: Get your actual IDs to replace placeholders
-- ============================================================================

-- Run these queries first to get your IDs:

/*
-- Get Profile ID (IMPORTANT: Use this ID in the inserts above)
SELECT id, user_id, full_name FROM public.profiles WHERE user_id = auth.uid();

-- Get Account IDs
SELECT id, name, account_type FROM public.accounts ORDER BY created_at;

-- Get Expense Category IDs
SELECT id, name FROM public.categories WHERE type = 'expense' ORDER BY name;

-- Get Income Category IDs
SELECT id, name FROM public.categories WHERE type = 'income' ORDER BY name;
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- After inserting, verify the data:

/*
-- View all scheduled payments
SELECT
    sp.id,
    sp.payee_name,
    sp.total_amount,
    sp.paid_amount,
    sp.due_date,
    sp.status,
    sp.type,
    CASE
        WHEN sp.due_date < CURRENT_DATE AND sp.status != 'completed' THEN 'OVERDUE'
        WHEN sp.due_date = CURRENT_DATE THEN 'DUE TODAY'
        WHEN sp.due_date > CURRENT_DATE THEN 'UPCOMING'
        ELSE 'N/A'
    END as payment_status
FROM public.scheduled_payments sp
ORDER BY sp.due_date;

-- View partial payments with history
SELECT
    sp.payee_name,
    sp.total_amount,
    sp.paid_amount,
    sp.status,
    COUNT(sph.id) as payment_count
FROM public.scheduled_payments sp
LEFT JOIN public.scheduled_payment_history sph ON sph.scheduled_payment_id = sp.id
WHERE sp.status = 'partial'
GROUP BY sp.id, sp.payee_name, sp.total_amount, sp.paid_amount, sp.status;

-- View overdue payments
SELECT
    payee_name,
    total_amount,
    due_date,
    CURRENT_DATE - due_date as days_overdue
FROM public.scheduled_payments
WHERE due_date < CURRENT_DATE
  AND status NOT IN ('completed', 'cancelled')
ORDER BY due_date;
*/
