-- =====================================================
-- Fix Budgets Table RLS Policies
-- =====================================================
-- This migration adds missing RLS policies for the budgets table
-- Run this in your Supabase SQL Editor

-- Drop existing policies if any (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can insert own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can update own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can delete own budgets" ON public.budgets;

-- Create RLS policies for budgets table (following the same pattern as other tables)

-- SELECT policy
CREATE POLICY "Users can view own budgets" ON public.budgets
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = budgets.profile_id
            AND profiles.user_id = auth.uid()
        )
    );

-- INSERT policy
CREATE POLICY "Users can insert own budgets" ON public.budgets
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = budgets.profile_id
            AND profiles.user_id = auth.uid()
        )
    );

-- UPDATE policy
CREATE POLICY "Users can update own budgets" ON public.budgets
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = budgets.profile_id
            AND profiles.user_id = auth.uid()
        )
    );

-- DELETE policy
CREATE POLICY "Users can delete own budgets" ON public.budgets
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = budgets.profile_id
            AND profiles.user_id = auth.uid()
        )
    );

-- Verify policies are created
DO $$
BEGIN
    RAISE NOTICE '✅ Budgets RLS policies created successfully!';
    RAISE NOTICE 'Users can now SELECT, INSERT, UPDATE, and DELETE their own budgets.';
END $$;
