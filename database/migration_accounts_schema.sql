-- Migration script to update accounts table schema
-- Run this in your Supabase SQL Editor to update the existing table

-- Step 1: Add new columns if they don't exist
DO $$
BEGIN
    -- Add opening_balance column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'accounts'
        AND column_name = 'opening_balance'
    ) THEN
        ALTER TABLE public.accounts ADD COLUMN opening_balance DECIMAL(15, 2) DEFAULT 0.00;
        RAISE NOTICE 'Added opening_balance column';
    ELSE
        RAISE NOTICE 'opening_balance column already exists';
    END IF;
END $$;

-- Step 2: Migrate data from old columns to new columns (only if initial_balance exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'accounts'
        AND column_name = 'initial_balance'
    ) THEN
        UPDATE public.accounts
        SET opening_balance = COALESCE(initial_balance, 0.00)
        WHERE opening_balance IS NULL OR opening_balance = 0.00;
        RAISE NOTICE 'Migrated data from initial_balance to opening_balance';
    ELSE
        RAISE NOTICE 'initial_balance column does not exist, skipping data migration';
    END IF;
END $$;

-- Step 3: Drop the old constraint FIRST (before updating type values)
ALTER TABLE public.accounts
DROP CONSTRAINT IF EXISTS accounts_type_check;

-- Step 4: Update account types to match Flutter code
-- Map old types to new types:
-- 'bank' -> 'savings'
-- 'wallet' -> 'savings'
-- 'cash' -> 'savings'
-- 'credit_card' stays 'credit_card'
UPDATE public.accounts
SET type = CASE
    WHEN type = 'bank' THEN 'savings'
    WHEN type = 'wallet' THEN 'savings'
    WHEN type = 'cash' THEN 'savings'
    WHEN type = 'credit_card' THEN 'credit_card'
    ELSE 'savings'
END
WHERE type NOT IN ('savings', 'current', 'credit_card');

-- Step 5: Drop old columns that are no longer needed (one by one to handle missing columns gracefully)
DO $$
BEGIN
    -- Drop initial_balance if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'initial_balance') THEN
        ALTER TABLE public.accounts DROP COLUMN initial_balance;
        RAISE NOTICE 'Dropped initial_balance column';
    END IF;

    -- Drop bank_name if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'bank_name') THEN
        ALTER TABLE public.accounts DROP COLUMN bank_name;
        RAISE NOTICE 'Dropped bank_name column';
    END IF;

    -- Drop account_number if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'account_number') THEN
        ALTER TABLE public.accounts DROP COLUMN account_number;
        RAISE NOTICE 'Dropped account_number column';
    END IF;

    -- Drop icon if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'icon') THEN
        ALTER TABLE public.accounts DROP COLUMN icon;
        RAISE NOTICE 'Dropped icon column';
    END IF;

    -- Drop color if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'color') THEN
        ALTER TABLE public.accounts DROP COLUMN color;
        RAISE NOTICE 'Dropped color column';
    END IF;

    -- Drop currency if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'currency') THEN
        ALTER TABLE public.accounts DROP COLUMN currency;
        RAISE NOTICE 'Dropped currency column';
    END IF;

    -- Drop notes if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'notes') THEN
        ALTER TABLE public.accounts DROP COLUMN notes;
        RAISE NOTICE 'Dropped notes column';
    END IF;
END $$;

-- Step 6: Add the new type constraint with only new values (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'public'
        AND table_name = 'accounts'
        AND constraint_name = 'accounts_type_check'
    ) THEN
        ALTER TABLE public.accounts
        ADD CONSTRAINT accounts_type_check
        CHECK (type IN ('savings', 'current', 'credit_card'));
        RAISE NOTICE 'Added accounts_type_check constraint';
    ELSE
        RAISE NOTICE 'accounts_type_check constraint already exists';
    END IF;
END $$;

-- Step 7: Ensure updated_at trigger exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_accounts_updated_at ON public.accounts;

CREATE TRIGGER update_accounts_updated_at
    BEFORE UPDATE ON public.accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify the changes
SELECT
    id,
    name,
    type,
    opening_balance,
    current_balance,
    is_active,
    profile_id,
    created_at
FROM public.accounts;
