-- =====================================================
-- Klarity Finance Tracking App - Additional RLS Policies
-- =====================================================
-- Run this script after schema.sql has created the tables.

-- Ensure RLS is enabled on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Recreate insert policy so authenticated users can insert their own row
DROP POLICY IF EXISTS "Users can insert own data" ON public.users;
CREATE POLICY "Users can insert own data"
    ON public.users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Optional notice for confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Users INSERT policy created successfully.';
END $$;
