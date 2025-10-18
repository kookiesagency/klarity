-- =====================================================
-- Klarity Finance Tracking App - Seed Data
-- =====================================================
-- This script inserts default categories and sample data
-- Run this AFTER running schema.sql

-- =====================================================
-- DEFAULT EXPENSE CATEGORIES
-- =====================================================
-- Note: These will be inserted per profile when a new profile is created
-- This is a reference list for the app to use

-- Categories will be created dynamically in the app when user creates their first profile
-- Below is the structure for reference:

/*
DEFAULT EXPENSE CATEGORIES:
- 🏠 Housing (Rent, Mortgage, Property Tax)
- 🚗 Transportation (Fuel, Public Transport, Vehicle Maintenance)
- 🍔 Food & Dining (Groceries, Restaurants, Coffee)
- 💡 Utilities (Electricity, Water, Gas, Internet)
- 🏥 Healthcare (Medical, Pharmacy, Insurance)
- 🎓 Education (Tuition, Books, Courses)
- 🎬 Entertainment (Movies, Games, Subscriptions)
- 👕 Shopping (Clothing, Electronics, Home Goods)
- 💰 Financial (Bank Fees, Loan Payments, Insurance)
- 🎁 Personal (Gifts, Personal Care, Hobbies)
- 📱 Communication (Phone, Internet)
- ✈️ Travel (Flights, Hotels, Vacation)
- 🐕 Pets (Food, Vet, Supplies)
- 👨‍👩‍👧‍👦 Family (Childcare, School, Activities)
- 📊 Business (Office, Supplies, Services)
- 💳 Credit Card Payment
- 🔧 Maintenance (Home Repairs, Car Service)
- 🎯 Others

DEFAULT INCOME CATEGORIES:
- 💼 Salary
- 💰 Business Income
- 🏦 Investment Returns
- 🎁 Gifts Received
- 💵 Refunds
- 🏠 Rental Income
- 📈 Capital Gains
- 💸 Freelance
- 🎯 Others
*/

-- =====================================================
-- HELPER FUNCTION: Create Default Categories
-- =====================================================
-- This function will be called when a new profile is created

CREATE OR REPLACE FUNCTION create_default_categories(p_profile_id UUID)
RETURNS void AS $$
BEGIN
    -- Insert default expense categories
    INSERT INTO public.categories (profile_id, name, type, icon, color, is_system)
    VALUES
        (p_profile_id, 'Housing', 'expense', '🏠', '#FF6B6B', true),
        (p_profile_id, 'Transportation', 'expense', '🚗', '#4ECDC4', true),
        (p_profile_id, 'Food & Dining', 'expense', '🍔', '#FFE66D', true),
        (p_profile_id, 'Utilities', 'expense', '💡', '#95E1D3', true),
        (p_profile_id, 'Healthcare', 'expense', '🏥', '#F38181', true),
        (p_profile_id, 'Education', 'expense', '🎓', '#AA96DA', true),
        (p_profile_id, 'Entertainment', 'expense', '🎬', '#FCBAD3', true),
        (p_profile_id, 'Shopping', 'expense', '👕', '#A8D8EA', true),
        (p_profile_id, 'Financial', 'expense', '💰', '#FFD93D', true),
        (p_profile_id, 'Personal', 'expense', '🎁', '#6BCB77', true),
        (p_profile_id, 'Communication', 'expense', '📱', '#4D96FF', true),
        (p_profile_id, 'Travel', 'expense', '✈️', '#845EC2', true),
        (p_profile_id, 'Pets', 'expense', '🐕', '#FFC75F', true),
        (p_profile_id, 'Family', 'expense', '👨‍👩‍👧‍👦', '#FF6F91', true),
        (p_profile_id, 'Business', 'expense', '📊', '#C34A36', true),
        (p_profile_id, 'Credit Card Payment', 'expense', '💳', '#008F7A', true),
        (p_profile_id, 'Maintenance', 'expense', '🔧', '#845EC2', true),
        (p_profile_id, 'Others', 'expense', '🎯', '#B39CD0', true);

    -- Insert default income categories
    INSERT INTO public.categories (profile_id, name, type, icon, color, is_system)
    VALUES
        (p_profile_id, 'Salary', 'income', '💼', '#00C9A7', true),
        (p_profile_id, 'Business Income', 'income', '💰', '#845EC2', true),
        (p_profile_id, 'Investment Returns', 'income', '🏦', '#FF6F91', true),
        (p_profile_id, 'Gifts Received', 'income', '🎁', '#FFC75F', true),
        (p_profile_id, 'Refunds', 'income', '💵', '#F9F871', true),
        (p_profile_id, 'Rental Income', 'income', '🏠', '#C34A36', true),
        (p_profile_id, 'Capital Gains', 'income', '📈', '#00C9A7', true),
        (p_profile_id, 'Freelance', 'income', '💸', '#0089BA', true),
        (p_profile_id, 'Others', 'income', '🎯', '#B39CD0', true);

    RAISE NOTICE 'Default categories created for profile: %', p_profile_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER: Auto-create categories on profile creation
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Create default categories for the new profile
    PERFORM create_default_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS auto_create_categories ON public.profiles;
CREATE TRIGGER auto_create_categories
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_categories();

-- =====================================================
-- TRIGGER: Create user record on auth signup
-- =====================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    _full_name TEXT;
    _phone TEXT;
BEGIN
    _full_name := NULLIF(btrim(COALESCE(NEW.raw_user_meta_data->>'full_name', '')), '');
    _phone := NULLIF(btrim(COALESCE(NEW.raw_user_meta_data->>'phone', '')), '');

    INSERT INTO public.users (id, email, full_name, phone)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(_full_name, 'User'),
        _phone
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- FUNCTION: Update account balance on transaction
-- =====================================================

CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
DECLARE
    account_balance DECIMAL(15, 2);
BEGIN
    -- Get current account balance
    SELECT current_balance INTO account_balance
    FROM public.accounts
    WHERE id = NEW.account_id;

    -- Update account balance based on transaction type
    IF NEW.type = 'income' THEN
        UPDATE public.accounts
        SET current_balance = current_balance + NEW.amount
        WHERE id = NEW.account_id;
    ELSIF NEW.type = 'expense' THEN
        UPDATE public.accounts
        SET current_balance = current_balance - NEW.amount
        WHERE id = NEW.account_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for transactions
DROP TRIGGER IF EXISTS update_balance_on_transaction ON public.transactions;
CREATE TRIGGER update_balance_on_transaction
    AFTER INSERT ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();

-- =====================================================
-- FUNCTION: Update account balance on transfer
-- =====================================================

CREATE OR REPLACE FUNCTION update_balance_on_transfer()
RETURNS TRIGGER AS $$
BEGIN
    -- Deduct from source account
    UPDATE public.accounts
    SET current_balance = current_balance - NEW.amount
    WHERE id = NEW.from_account_id;

    -- Add to destination account
    UPDATE public.accounts
    SET current_balance = current_balance + NEW.amount
    WHERE id = NEW.to_account_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for transfers
DROP TRIGGER IF EXISTS update_balance_on_transfer_trigger ON public.transfers;
CREATE TRIGGER update_balance_on_transfer_trigger
    AFTER INSERT ON public.transfers
    FOR EACH ROW
    EXECUTE FUNCTION update_balance_on_transfer();

-- =====================================================
-- FUNCTION: Calculate running balance
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_running_balance(
    p_profile_id UUID,
    p_account_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    transaction_id UUID,
    transaction_date TIMESTAMPTZ,
    description TEXT,
    amount DECIMAL(15, 2),
    type TEXT,
    running_balance DECIMAL(15, 2)
) AS $$
BEGIN
    RETURN QUERY
    WITH ordered_transactions AS (
        SELECT
            t.id,
            t.transaction_date,
            t.description,
            t.amount,
            t.type,
            t.account_id
        FROM public.transactions t
        WHERE t.profile_id = p_profile_id
            AND (p_account_id IS NULL OR t.account_id = p_account_id)
            AND (p_start_date IS NULL OR t.transaction_date >= p_start_date)
            AND (p_end_date IS NULL OR t.transaction_date <= p_end_date)
        ORDER BY t.transaction_date ASC, t.created_at ASC
    )
    SELECT
        ot.id,
        ot.transaction_date,
        ot.description,
        ot.amount,
        ot.type,
        SUM(CASE WHEN ot.type = 'income' THEN ot.amount ELSE -ot.amount END)
            OVER (PARTITION BY ot.account_id ORDER BY ot.transaction_date, ot.id) as running_balance
    FROM ordered_transactions ot;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Seed data and helper functions created successfully!';
    RAISE NOTICE 'Default categories will be auto-created when users create profiles.';
END $$;
