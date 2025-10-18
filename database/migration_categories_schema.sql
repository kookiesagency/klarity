-- =====================================================
-- Migration: Fix Categories Table Schema
-- =====================================================
-- This script updates the categories table to match Flutter code expectations
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Step 1: Add missing columns
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
        RAISE NOTICE 'Added color_hex column';
    ELSE
        RAISE NOTICE 'color_hex column already exists';
    END IF;

    -- Add is_default column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'categories'
        AND column_name = 'is_default'
    ) THEN
        ALTER TABLE public.categories ADD COLUMN is_default BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added is_default column';
    ELSE
        RAISE NOTICE 'is_default column already exists';
    END IF;

    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'categories'
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.categories ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added is_active column';
    ELSE
        RAISE NOTICE 'is_active column already exists';
    END IF;
END $$;

-- Step 2: Migrate data from old columns to new columns
DO $$
BEGIN
    -- Copy color to color_hex if color_hex is empty
    UPDATE public.categories
    SET color_hex = COALESCE(color, '#6366F1')
    WHERE color_hex IS NULL;
    RAISE NOTICE 'Migrated color to color_hex';

    -- Copy is_system to is_default if needed
    UPDATE public.categories
    SET is_default = COALESCE(is_system, false)
    WHERE is_default IS NULL OR is_default = false;
    RAISE NOTICE 'Migrated is_system to is_default';

    -- Set all categories as active by default
    UPDATE public.categories
    SET is_active = true
    WHERE is_active IS NULL;
    RAISE NOTICE 'Set all categories as active';
END $$;

-- Step 3: Drop old columns (optional - keep commented out for safety)
-- DO $$
-- BEGIN
--     -- Drop color column if exists
--     IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'categories' AND column_name = 'color') THEN
--         ALTER TABLE public.categories DROP COLUMN color;
--         RAISE NOTICE 'Dropped color column';
--     END IF;

--     -- Drop is_system column if exists
--     IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'categories' AND column_name = 'is_system') THEN
--         ALTER TABLE public.categories DROP COLUMN is_system;
--         RAISE NOTICE 'Dropped is_system column';
--     END IF;
-- END $$;

-- Step 4: Verify the migration
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'categories'
ORDER BY ordinal_position;

-- Step 5: Show current categories
SELECT
    p.name AS profile_name,
    c.name AS category_name,
    c.type,
    c.color_hex,
    c.is_default,
    c.is_active
FROM public.categories c
JOIN public.profiles p ON p.id = c.profile_id
ORDER BY p.name, c.type, c.name;

-- =====================================================
-- Success Message
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Categories schema migration completed!';
    RAISE NOTICE 'New columns added: color_hex, is_default, is_active';
    RAISE NOTICE 'Old data migrated successfully';
    RAISE NOTICE '';
END $$;
