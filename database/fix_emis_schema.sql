-- =====================================================
-- Fix EMI Schema - Add Missing Columns
-- =====================================================
-- Run this if you get "column does not exist" errors
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Fixing EMI schema...';
    RAISE NOTICE '';
END $$;

-- Fix emis table - add missing columns
DO $$
BEGIN
    -- Add description column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'emis'
        AND column_name = 'description'
    ) THEN
        ALTER TABLE public.emis ADD COLUMN description TEXT;
        RAISE NOTICE '✅ Added description column to emis table';
    ELSE
        RAISE NOTICE 'ℹ️  description column already exists';
    END IF;

    -- Add next_payment_date column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'emis'
        AND column_name = 'next_payment_date'
    ) THEN
        ALTER TABLE public.emis ADD COLUMN next_payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW();
        RAISE NOTICE '✅ Added next_payment_date column to emis table';
    ELSE
        RAISE NOTICE 'ℹ️  next_payment_date column already exists';
    END IF;

    -- Add payment_day_of_month column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'emis'
        AND column_name = 'payment_day_of_month'
    ) THEN
        ALTER TABLE public.emis ADD COLUMN payment_day_of_month INT NOT NULL DEFAULT 1 CHECK (payment_day_of_month >= 1 AND payment_day_of_month <= 31);
        RAISE NOTICE '✅ Added payment_day_of_month column to emis table';
    ELSE
        RAISE NOTICE 'ℹ️  payment_day_of_month column already exists';
    END IF;
END $$;

-- Fix emi_payments table - add missing columns
DO $$
BEGIN
    -- Add is_paid column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'emi_payments'
        AND column_name = 'is_paid'
    ) THEN
        ALTER TABLE public.emi_payments ADD COLUMN is_paid BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Added is_paid column to emi_payments table';
    ELSE
        RAISE NOTICE 'ℹ️  is_paid column already exists';
    END IF;

    -- Add due_date column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'emi_payments'
        AND column_name = 'due_date'
    ) THEN
        ALTER TABLE public.emi_payments ADD COLUMN due_date TIMESTAMPTZ NOT NULL DEFAULT NOW();
        RAISE NOTICE '✅ Added due_date column to emi_payments table';
    ELSE
        RAISE NOTICE 'ℹ️  due_date column already exists';
    END IF;

    -- Add notes column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'emi_payments'
        AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.emi_payments ADD COLUMN notes TEXT;
        RAISE NOTICE '✅ Added notes column to emi_payments table';
    ELSE
        RAISE NOTICE 'ℹ️  notes column already exists';
    END IF;
END $$;

-- Create index if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename = 'emis'
        AND indexname = 'idx_emis_next_payment_date'
    ) THEN
        CREATE INDEX idx_emis_next_payment_date ON public.emis(next_payment_date);
        RAISE NOTICE '✅ Created index on next_payment_date';
    ELSE
        RAISE NOTICE 'ℹ️  Index already exists';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ EMI SCHEMA FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'You can now run create_emis_schema.sql';
    RAISE NOTICE '========================================';
END $$;
