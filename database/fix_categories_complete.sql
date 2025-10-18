-- =====================================================
-- COMPLETE FIX: Categories Schema + Data
-- =====================================================
-- This ONE script will:
-- 1. Fix the categories table schema (add missing columns)
-- 2. Create the trigger for auto-creating categories
-- 3. Create default categories for existing profiles
--
-- Just run THIS SCRIPT in your Supabase SQL Editor
-- =====================================================

RAISE NOTICE '🔧 Starting complete categories fix...';
RAISE NOTICE '';

-- =====================================================
-- STEP 1: Fix Categories Table Schema
-- =====================================================
RAISE NOTICE 'Step 1: Fixing categories table schema...';

DO $$
BEGIN
    -- Add color_hex column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'categories'
        AND column_name = 'color_hex'
    ) THEN
        ALTER TABLE public.categories ADD COLUMN color_hex TEXT;
        RAISE NOTICE '✅ Added color_hex column';
    ELSE
        RAISE NOTICE '⏭️  color_hex column already exists';
    END IF;

    -- Add is_default column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'categories'
        AND column_name = 'is_default'
    ) THEN
        ALTER TABLE public.categories ADD COLUMN is_default BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Added is_default column';
    ELSE
        RAISE NOTICE '⏭️  is_default column already exists';
    END IF;

    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'categories'
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.categories ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Added is_active column';
    ELSE
        RAISE NOTICE '⏭️  is_active column already exists';
    END IF;

    -- Migrate data from old columns to new columns
    UPDATE public.categories
    SET color_hex = COALESCE(color_hex, color, '#6366F1');

    UPDATE public.categories
    SET is_default = COALESCE(is_default, is_system, false);

    UPDATE public.categories
    SET is_active = COALESCE(is_active, true);

    RAISE NOTICE '✅ Migrated data from old columns';
END $$;

RAISE NOTICE '';
RAISE NOTICE 'Step 1 Complete: Schema fixed!';
RAISE NOTICE '';

-- =====================================================
-- STEP 2: Create Helper Function
-- =====================================================
RAISE NOTICE 'Step 2: Creating helper function...';

CREATE OR REPLACE FUNCTION create_default_categories(p_profile_id UUID)
RETURNS void AS $$
BEGIN
    -- Insert default expense categories
    INSERT INTO public.categories (profile_id, name, type, icon, color_hex, is_default, is_active)
    VALUES
        (p_profile_id, 'Housing', 'expense', '🏠', '#EF4444', true, true),
        (p_profile_id, 'Transportation', 'expense', '🚗', '#3B82F6', true, true),
        (p_profile_id, 'Food & Dining', 'expense', '🍔', '#F97316', true, true),
        (p_profile_id, 'Utilities', 'expense', '💡', '#EAB308', true, true),
        (p_profile_id, 'Healthcare', 'expense', '🏥', '#EF4444', true, true),
        (p_profile_id, 'Education', 'expense', '🎓', '#6366F1', true, true),
        (p_profile_id, 'Entertainment', 'expense', '🎬', '#A855F7', true, true),
        (p_profile_id, 'Shopping', 'expense', '👕', '#EC4899', true, true),
        (p_profile_id, 'Personal Care', 'expense', '🎁', '#06B6D4', true, true),
        (p_profile_id, 'Others', 'expense', '🎯', '#14B8A6', true, true)
    ON CONFLICT (profile_id, name, type) DO UPDATE
    SET color_hex = EXCLUDED.color_hex,
        is_default = EXCLUDED.is_default,
        is_active = EXCLUDED.is_active;

    -- Insert default income categories
    INSERT INTO public.categories (profile_id, name, type, icon, color_hex, is_default, is_active)
    VALUES
        (p_profile_id, 'Salary', 'income', '💼', '#22C55E', true, true),
        (p_profile_id, 'Business Income', 'income', '💰', '#6366F1', true, true),
        (p_profile_id, 'Investments', 'income', '🏦', '#6366F1', true, true),
        (p_profile_id, 'Freelancing', 'income', '💸', '#A855F7', true, true),
        (p_profile_id, 'Gifts', 'income', '🎁', '#EC4899', true, true)
    ON CONFLICT (profile_id, name, type) DO UPDATE
    SET color_hex = EXCLUDED.color_hex,
        is_default = EXCLUDED.is_default,
        is_active = EXCLUDED.is_active;

    RAISE NOTICE '✅ Created default categories for profile: %', p_profile_id;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE 'Step 2 Complete: Helper function created!';
RAISE NOTICE '';

-- =====================================================
-- STEP 3: Create Trigger
-- =====================================================
RAISE NOTICE 'Step 3: Creating auto-category trigger...';

CREATE OR REPLACE FUNCTION trigger_create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM create_default_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_create_categories ON public.profiles;
CREATE TRIGGER auto_create_categories
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_categories();

RAISE NOTICE 'Step 3 Complete: Trigger created!';
RAISE NOTICE '';

-- =====================================================
-- STEP 4: Create Categories for Existing Profiles
-- =====================================================
RAISE NOTICE 'Step 4: Creating categories for existing profiles...';

DO $$
DECLARE
    profile_record RECORD;
    category_count INTEGER;
BEGIN
    FOR profile_record IN SELECT id, name FROM public.profiles
    LOOP
        -- Check if categories already exist
        SELECT COUNT(*) INTO category_count
        FROM public.categories
        WHERE profile_id = profile_record.id
        AND is_active = true;

        IF category_count = 0 THEN
            PERFORM create_default_categories(profile_record.id);
            RAISE NOTICE '✅ Created categories for: %', profile_record.name;
        ELSE
            RAISE NOTICE '⏭️  Profile "%" already has % categories', profile_record.name, category_count;
        END IF;
    END LOOP;
END $$;

RAISE NOTICE 'Step 4 Complete: Categories created!';
RAISE NOTICE '';

-- =====================================================
-- STEP 5: Verification
-- =====================================================
RAISE NOTICE '📊 VERIFICATION RESULTS:';
RAISE NOTICE '';

-- Show category counts per profile
DO $$
DECLARE
    result_record RECORD;
BEGIN
    FOR result_record IN
        SELECT
            p.name AS profile_name,
            COUNT(CASE WHEN c.type = 'expense' THEN 1 END) AS expense_categories,
            COUNT(CASE WHEN c.type = 'income' THEN 1 END) AS income_categories,
            COUNT(*) AS total_categories
        FROM public.profiles p
        LEFT JOIN public.categories c ON c.profile_id = p.id AND c.is_active = true
        GROUP BY p.id, p.name
        ORDER BY p.name
    LOOP
        RAISE NOTICE 'Profile: % | Expense: % | Income: % | Total: %',
            result_record.profile_name,
            result_record.expense_categories,
            result_record.income_categories,
            result_record.total_categories;
    END LOOP;
END $$;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ CATEGORIES FIX COMPLETED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✓ Schema updated (color_hex, is_default, is_active)';
    RAISE NOTICE '✓ Helper function created';
    RAISE NOTICE '✓ Auto-create trigger installed';
    RAISE NOTICE '✓ Categories created for all profiles';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Next Steps:';
    RAISE NOTICE '1. Restart your Flutter app';
    RAISE NOTICE '2. Go to Categories screen';
    RAISE NOTICE '3. You should see Expense (10) and Income (5)';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Future profiles will auto-create categories!';
    RAISE NOTICE '========================================';
END $$;
