-- =====================================================
-- Add Low Balance Threshold to Profiles Table
-- =====================================================
-- This migration adds support for low balance alerts per profile
-- Run this in your Supabase SQL Editor

-- Add low_balance_threshold column to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS low_balance_threshold DECIMAL(15, 2) DEFAULT 1000.00;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.low_balance_threshold IS 'Minimum balance threshold for low balance alerts. When profile total balance falls below this, user gets alerted.';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Low balance threshold column added successfully!';
    RAISE NOTICE 'Default threshold set to 1000.00 for all profiles.';
END $$;
