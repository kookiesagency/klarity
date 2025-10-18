-- =====================================================
-- Fix Missing Categories Issue
-- =====================================================
-- This script will:
-- 1. Ensure the category creation trigger exists
-- 2. Create default categories for existing profiles
--
-- Run this in your Supabase SQL Editor
-- =====================================================

-- =====================================================
-- Step 1: Create the helper function
-- =====================================================
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
        (p_profile_id, 'Others', 'expense', '🎯', '#B39CD0', true)
    ON CONFLICT (profile_id, name, type) DO NOTHING;

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
        (p_profile_id, 'Others', 'income', '🎯', '#B39CD0', true)
    ON CONFLICT (profile_id, name, type) DO NOTHING;

    RAISE NOTICE 'Default categories created for profile: %', p_profile_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Step 2: Create the trigger function
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Create default categories for the new profile
    PERFORM create_default_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Step 3: Create the trigger
-- =====================================================
DROP TRIGGER IF EXISTS auto_create_categories ON public.profiles;
CREATE TRIGGER auto_create_categories
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_categories();

-- =====================================================
-- Step 4: Create categories for ALL existing profiles
-- =====================================================
DO $$
DECLARE
    profile_record RECORD;
    category_count INTEGER;
BEGIN
    RAISE NOTICE 'Creating default categories for existing profiles...';

    -- Loop through all existing profiles
    FOR profile_record IN SELECT id, name FROM public.profiles
    LOOP
        -- Check if categories already exist for this profile
        SELECT COUNT(*) INTO category_count
        FROM public.categories
        WHERE profile_id = profile_record.id;

        IF category_count = 0 THEN
            -- Create default categories
            PERFORM create_default_categories(profile_record.id);
            RAISE NOTICE 'Created categories for profile: % (ID: %)', profile_record.name, profile_record.id;
        ELSE
            RAISE NOTICE 'Profile % already has % categories, skipping', profile_record.name, category_count;
        END IF;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '✅ Category fix completed!';
    RAISE NOTICE 'All existing profiles now have default categories.';
    RAISE NOTICE 'Future profiles will auto-create categories via trigger.';
END $$;

-- =====================================================
-- Step 5: Verify categories were created
-- =====================================================
SELECT
    p.name AS profile_name,
    COUNT(CASE WHEN c.type = 'expense' THEN 1 END) AS expense_categories,
    COUNT(CASE WHEN c.type = 'income' THEN 1 END) AS income_categories,
    COUNT(*) AS total_categories
FROM public.profiles p
LEFT JOIN public.categories c ON c.profile_id = p.id
GROUP BY p.id, p.name
ORDER BY p.name;
