-- =====================================================
-- Fix Category Delete Policy
-- =====================================================
-- Allow users to delete default categories
-- Run this in Supabase SQL Editor
-- =====================================================

-- Drop old policy that restricts default category deletion
DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;

-- Create new policy that allows deleting ALL categories (including default ones)
CREATE POLICY "Users can delete own categories" ON public.categories FOR DELETE USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = categories.profile_id
        AND profiles.user_id = auth.uid()
    )
);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Category delete policy updated!';
    RAISE NOTICE 'Users can now delete default categories.';
END $$;
