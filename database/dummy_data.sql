-- =====================================================
-- Klarity Finance Tracking App - Dummy Data (Updated)
-- =====================================================
-- This script inserts realistic dummy data for testing
-- User ID: f43c0d1c-2651-4779-b32d-050f41e11694
--
-- IMPORTANT: Run this AFTER schema.sql and seed_data.sql
-- To delete all dummy data later, run: DELETE FROM public.profiles WHERE user_id = 'f43c0d1c-2651-4779-b32d-050f41e11694';
-- =====================================================

-- Set user ID variable
DO $$
DECLARE
    v_user_id UUID := 'f43c0d1c-2651-4779-b32d-050f41e11694';
    v_personal_profile_id UUID;
    v_company_profile_id UUID;

    -- Account IDs
    v_hdfc_savings_id UUID;
    v_icici_savings_id UUID;
    v_sbi_savings_id UUID;
    v_hdfc_credit_card_id UUID;

    v_company_hdfc_current_id UUID;
    v_company_icici_current_id UUID;
    v_company_petty_cash_id UUID;

    -- Category IDs (will be auto-created)
    v_salary_category UUID;
    v_shopping_category UUID;
    v_food_category UUID;
    v_transport_category UUID;
    v_utilities_category UUID;
    v_housing_category UUID;
    v_entertainment_category UUID;
    v_business_income_category UUID;
    v_business_expense_category UUID;

BEGIN
    RAISE NOTICE 'Starting dummy data insertion...';

    -- =====================================================
    -- 1. GET EXISTING PROFILES (or create if they don't exist)
    -- =====================================================
    RAISE NOTICE 'Getting existing profiles...';

    -- Get Personal Profile (or create if doesn't exist)
    SELECT id INTO v_personal_profile_id
    FROM public.profiles
    WHERE user_id = v_user_id AND name = 'Personal';

    IF v_personal_profile_id IS NULL THEN
        INSERT INTO public.profiles (id, user_id, name, is_default)
        VALUES (uuid_generate_v4(), v_user_id, 'Personal', true)
        RETURNING id INTO v_personal_profile_id;
        RAISE NOTICE 'Personal profile created: %', v_personal_profile_id;
    ELSE
        RAISE NOTICE 'Using existing Personal profile: %', v_personal_profile_id;
    END IF;

    -- Get Company Profile (or create if doesn't exist)
    SELECT id INTO v_company_profile_id
    FROM public.profiles
    WHERE user_id = v_user_id AND name = 'Company';

    IF v_company_profile_id IS NULL THEN
        INSERT INTO public.profiles (id, user_id, name, is_default)
        VALUES (uuid_generate_v4(), v_user_id, 'Company', false)
        RETURNING id INTO v_company_profile_id;
        RAISE NOTICE 'Company profile created: %', v_company_profile_id;
    ELSE
        RAISE NOTICE 'Using existing Company profile: %', v_company_profile_id;
    END IF;

    -- Wait for categories to be auto-created by trigger
    PERFORM pg_sleep(1);

    -- Get category IDs for Personal profile
    SELECT id INTO v_salary_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Salary' AND type = 'income';

    SELECT id INTO v_shopping_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Shopping' AND type = 'expense';

    SELECT id INTO v_food_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Food & Dining' AND type = 'expense';

    SELECT id INTO v_transport_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Transportation' AND type = 'expense';

    SELECT id INTO v_utilities_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Utilities' AND type = 'expense';

    SELECT id INTO v_housing_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Housing' AND type = 'expense';

    SELECT id INTO v_entertainment_category FROM public.categories
    WHERE profile_id = v_personal_profile_id AND name = 'Entertainment' AND type = 'expense';

    -- Get category IDs for Company profile
    SELECT id INTO v_business_income_category FROM public.categories
    WHERE profile_id = v_company_profile_id AND name = 'Business Income' AND type = 'income';

    SELECT id INTO v_business_expense_category FROM public.categories
    WHERE profile_id = v_company_profile_id AND name = 'Business' AND type = 'expense';

    -- =====================================================
    -- 2. CREATE ACCOUNTS (Personal)
    -- =====================================================
    RAISE NOTICE 'Creating personal accounts...';

    -- HDFC Savings Account
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_personal_profile_id, 'HDFC Savings', 'savings', 15250.00, 15250.00, true)
    RETURNING id INTO v_hdfc_savings_id;

    -- ICICI Savings Account
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_personal_profile_id, 'ICICI Savings', 'savings', 12750.00, 12750.00, true)
    RETURNING id INTO v_icici_savings_id;

    -- SBI Savings Account
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_personal_profile_id, 'SBI Savings', 'savings', 8500.00, 8500.00, true)
    RETURNING id INTO v_sbi_savings_id;

    -- HDFC Credit Card
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_personal_profile_id, 'HDFC Credit Card', 'credit_card', -8500.00, -8500.00, true)
    RETURNING id INTO v_hdfc_credit_card_id;

    -- =====================================================
    -- 3. CREATE ACCOUNTS (Company)
    -- =====================================================
    RAISE NOTICE 'Creating company accounts...';

    -- Company HDFC Current Account
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_company_profile_id, 'HDFC Current Account', 'current', 125000.00, 125000.00, true)
    RETURNING id INTO v_company_hdfc_current_id;

    -- Company ICICI Current Account
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_company_profile_id, 'ICICI Current Account', 'current', 85000.00, 85000.00, true)
    RETURNING id INTO v_company_icici_current_id;

    -- Company Petty Cash
    INSERT INTO public.accounts (id, profile_id, name, type, opening_balance, current_balance, is_active)
    VALUES (uuid_generate_v4(), v_company_profile_id, 'Petty Cash', 'savings', 15000.00, 15000.00, true)
    RETURNING id INTO v_company_petty_cash_id;

    -- =====================================================
    -- 4. CREATE TRANSACTIONS (Personal - Recent)
    -- =====================================================
    RAISE NOTICE 'Creating personal transactions...';

    -- Today's transactions
    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_personal_profile_id, v_icici_savings_id, v_shopping_category, 'expense', 2450.00, 'Shopping', NOW(), 'Amazon'),
        (v_personal_profile_id, v_hdfc_savings_id, v_food_category, 'expense', 350.00, 'Food & Dining', NOW(), 'Lunch at Subway');

    -- Yesterday's transactions
    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_personal_profile_id, v_hdfc_savings_id, v_salary_category, 'income', 45000.00, 'Salary', NOW() - INTERVAL '1 day', 'Monthly Salary'),
        (v_personal_profile_id, v_icici_savings_id, v_food_category, 'expense', 850.00, 'Food & Dining', NOW() - INTERVAL '1 day', 'Swiggy'),
        (v_personal_profile_id, v_hdfc_credit_card_id, v_entertainment_category, 'expense', 1200.00, 'Entertainment', NOW() - INTERVAL '1 day', 'Netflix & Amazon Prime');

    -- 2 days ago
    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_personal_profile_id, v_sbi_savings_id, v_transport_category, 'expense', 1200.00, 'Transport', NOW() - INTERVAL '2 days', 'Petrol'),
        (v_personal_profile_id, v_icici_savings_id, v_food_category, 'expense', 650.00, 'Food & Dining', NOW() - INTERVAL '2 days', 'Groceries');

    -- 3 days ago
    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_personal_profile_id, v_hdfc_savings_id, v_transport_category, 'expense', 450.00, 'Transport', NOW() - INTERVAL '3 days', 'Uber'),
        (v_personal_profile_id, v_hdfc_credit_card_id, v_shopping_category, 'expense', 3500.00, 'Shopping', NOW() - INTERVAL '3 days', 'Clothing');

    -- 5 days ago
    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_personal_profile_id, v_icici_savings_id, v_utilities_category, 'expense', 1450.00, 'Utilities', NOW() - INTERVAL '5 days', 'Electricity Bill'),
        (v_personal_profile_id, v_sbi_savings_id, v_utilities_category, 'expense', 899.00, 'Utilities', NOW() - INTERVAL '5 days', 'Internet Bill');

    -- Last week
    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_personal_profile_id, v_hdfc_savings_id, v_housing_category, 'expense', 15000.00, 'Housing', NOW() - INTERVAL '7 days', 'House Rent'),
        (v_personal_profile_id, v_sbi_savings_id, v_food_category, 'expense', 1200.00, 'Food & Dining', NOW() - INTERVAL '8 days', 'Restaurant Dinner'),
        (v_personal_profile_id, v_icici_savings_id, v_food_category, 'expense', 450.00, 'Food & Dining', NOW() - INTERVAL '9 days', 'Coffee'),
        (v_personal_profile_id, v_hdfc_credit_card_id, v_transport_category, 'expense', 2500.00, 'Transport', NOW() - INTERVAL '10 days', 'Car Service');

    -- =====================================================
    -- 5. CREATE TRANSACTIONS (Company - Recent)
    -- =====================================================
    RAISE NOTICE 'Creating company transactions...';

    INSERT INTO public.transactions (profile_id, account_id, category_id, type, amount, description, transaction_date, notes)
    VALUES
        (v_company_profile_id, v_company_hdfc_current_id, v_business_income_category, 'income', 85000.00, 'Business Income', NOW() - INTERVAL '2 days', 'Client Payment - Project ABC'),
        (v_company_profile_id, v_company_hdfc_current_id, v_business_income_category, 'income', 65000.00, 'Business Income', NOW() - INTERVAL '5 days', 'Client Payment - Project XYZ'),
        (v_company_profile_id, v_company_icici_current_id, v_business_expense_category, 'expense', 12500.00, 'Business', NOW() - INTERVAL '3 days', 'Office Supplies'),
        (v_company_profile_id, v_company_petty_cash_id, v_business_expense_category, 'expense', 3500.00, 'Business', NOW() - INTERVAL '4 days', 'Team Lunch'),
        (v_company_profile_id, v_company_hdfc_current_id, v_business_expense_category, 'expense', 8500.00, 'Business', NOW() - INTERVAL '6 days', 'Software Subscription');

    -- =====================================================
    -- 6. CREATE RECURRING TRANSACTIONS (Personal)
    -- =====================================================
    RAISE NOTICE 'Creating recurring transactions...';

    INSERT INTO public.recurring_transactions (profile_id, account_id, category_id, type, amount, description, frequency, start_date, next_due_date, is_active, auto_create)
    VALUES
        (v_personal_profile_id, v_hdfc_savings_id, v_salary_category, 'income', 45000.00, 'Monthly Salary', 'monthly', '2024-01-01', DATE_TRUNC('month', NOW() + INTERVAL '1 month'), true, true),
        (v_personal_profile_id, v_hdfc_savings_id, v_housing_category, 'expense', 15000.00, 'House Rent', 'monthly', '2024-01-05', DATE_TRUNC('month', NOW() + INTERVAL '1 month') + INTERVAL '4 days', true, true),
        (v_personal_profile_id, v_icici_savings_id, v_utilities_category, 'expense', 1450.00, 'Electricity Bill', 'monthly', '2024-01-10', DATE_TRUNC('month', NOW() + INTERVAL '1 month') + INTERVAL '9 days', true, true),
        (v_personal_profile_id, v_icici_savings_id, v_utilities_category, 'expense', 899.00, 'Internet Bill', 'monthly', '2024-01-15', DATE_TRUNC('month', NOW() + INTERVAL '1 month') + INTERVAL '14 days', true, true),
        (v_personal_profile_id, v_hdfc_credit_card_id, v_entertainment_category, 'expense', 1200.00, 'Streaming Services', 'monthly', '2024-01-01', DATE_TRUNC('month', NOW() + INTERVAL '1 month'), true, true);

    -- =====================================================
    -- 7. CREATE SCHEDULED PAYMENTS (Upcoming)
    -- =====================================================
    RAISE NOTICE 'Creating scheduled payments...';

    INSERT INTO public.scheduled_payments (profile_id, account_id, category_id, type, total_amount, paid_amount, description, due_date, is_completed)
    VALUES
        (v_personal_profile_id, v_icici_savings_id, v_utilities_category, 'expense', 1450.00, 0.00, 'Electricity Bill', NOW() + INTERVAL '2 days', false),
        (v_personal_profile_id, v_sbi_savings_id, v_utilities_category, 'expense', 899.00, 0.00, 'Internet Bill', NOW() + INTERVAL '5 days', false),
        (v_personal_profile_id, v_hdfc_savings_id, v_housing_category, 'expense', 15000.00, 0.00, 'House Rent', NOW() + INTERVAL '8 days', false),
        (v_personal_profile_id, v_hdfc_credit_card_id, v_transport_category, 'expense', 5000.00, 2000.00, 'Car Insurance', NOW() + INTERVAL '15 days', false);

    -- =====================================================
    -- 8. CREATE EMIs (Personal)
    -- =====================================================
    RAISE NOTICE 'Creating EMIs...';

    INSERT INTO public.emis (profile_id, account_id, category_id, name, principal_amount, interest_rate, tenure_months, emi_amount, total_amount, paid_amount, start_date, end_date, next_due_date, is_active, auto_deduct)
    VALUES
        (v_personal_profile_id, v_hdfc_savings_id, v_transport_category, 'Car Loan', 500000.00, 8.5, 60, 10245.00, 614700.00, 102450.00, '2024-01-01', '2028-12-31', DATE_TRUNC('month', NOW() + INTERVAL '1 month'), true, true),
        (v_personal_profile_id, v_icici_savings_id, v_shopping_category, 'iPhone 15 Pro', 125000.00, 12.0, 12, 11122.00, 133464.00, 44488.00, '2024-06-01', '2025-05-31', DATE_TRUNC('month', NOW() + INTERVAL '1 month'), true, true);

    -- =====================================================
    -- 9. CREATE BUDGETS (Personal)
    -- =====================================================
    RAISE NOTICE 'Creating budgets...';

    INSERT INTO public.budgets (profile_id, category_id, amount, period, start_date, alert_threshold, is_active)
    VALUES
        (v_personal_profile_id, v_food_category, 10000.00, 'monthly', DATE_TRUNC('month', NOW()), 80, true),
        (v_personal_profile_id, v_shopping_category, 15000.00, 'monthly', DATE_TRUNC('month', NOW()), 80, true),
        (v_personal_profile_id, v_transport_category, 5000.00, 'monthly', DATE_TRUNC('month', NOW()), 80, true),
        (v_personal_profile_id, v_entertainment_category, 3000.00, 'monthly', DATE_TRUNC('month', NOW()), 80, true);

    -- =====================================================
    -- 10. CREATE TRANSFERS (Sample)
    -- =====================================================
    RAISE NOTICE 'Creating transfers...';

    INSERT INTO public.transfers (profile_id, from_account_id, to_account_id, amount, description, transfer_date)
    VALUES
        (v_personal_profile_id, v_hdfc_savings_id, v_icici_savings_id, 2000.00, 'Fund Transfer', NOW() - INTERVAL '4 days'),
        (v_personal_profile_id, v_icici_savings_id, v_hdfc_savings_id, 5000.00, 'Fund Transfer', NOW() - INTERVAL '7 days');

    -- =====================================================
    -- SUCCESS MESSAGE
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ DUMMY DATA CREATED SUCCESSFULLY!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'User ID: %', v_user_id;
    RAISE NOTICE 'Personal Profile ID: %', v_personal_profile_id;
    RAISE NOTICE 'Company Profile ID: %', v_company_profile_id;
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '- 2 Profiles (Personal & Company)';
    RAISE NOTICE '- 7 Accounts (4 Personal + 3 Company)';
    RAISE NOTICE '- Auto-created Categories per profile';
    RAISE NOTICE '- 20+ Transactions (income & expenses)';
    RAISE NOTICE '- 5 Recurring Transactions';
    RAISE NOTICE '- 4 Scheduled Payments';
    RAISE NOTICE '- 2 EMIs';
    RAISE NOTICE '- 4 Budgets';
    RAISE NOTICE '- 2 Transfers';
    RAISE NOTICE '';
    RAISE NOTICE '💰 Personal Accounts: ₹18,500.00 (3 savings) + ₹-8,500.00 (1 credit card)';
    RAISE NOTICE '💼 Company Accounts Total: ₹225,000.00';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  To delete all this data later, run:';
    RAISE NOTICE 'DELETE FROM public.profiles WHERE user_id = ''%'';', v_user_id;
    RAISE NOTICE '========================================';

END $$;
