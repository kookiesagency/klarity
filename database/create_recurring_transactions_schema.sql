-- =====================================================
-- Phase 5: Recurring Transactions Schema
-- =====================================================
-- This script creates the recurring_transactions table
-- Run this in your Supabase SQL Editor
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Creating recurring transactions schema...';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 1. RECURRING_TRANSACTIONS TABLE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 1: Creating recurring_transactions table...';
END $$;

CREATE TABLE IF NOT EXISTS public.recurring_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    next_due_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_date IS NULL OR end_date > start_date)
);

DO $$
BEGIN
    RAISE NOTICE '✅ Recurring transactions table created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 2. INDEXES for Performance
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 2: Creating indexes...';
END $$;

CREATE INDEX IF NOT EXISTS idx_recurring_transactions_profile_id ON public.recurring_transactions(profile_id);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_account_id ON public.recurring_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_category_id ON public.recurring_transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_type ON public.recurring_transactions(type);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_frequency ON public.recurring_transactions(frequency);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_next_due_date ON public.recurring_transactions(next_due_date);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_is_active ON public.recurring_transactions(is_active);

DO $$
BEGIN
    RAISE NOTICE '✅ Indexes created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) Policies
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 3: Setting up RLS policies...';
END $$;

-- Enable RLS
ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

-- View policy
DROP POLICY IF EXISTS "Users can view own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can view own recurring transactions" ON public.recurring_transactions FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);

-- Insert policy
DROP POLICY IF EXISTS "Users can insert own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can insert own recurring transactions" ON public.recurring_transactions FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);

-- Update policy
DROP POLICY IF EXISTS "Users can update own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can update own recurring transactions" ON public.recurring_transactions FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);

-- Delete policy
DROP POLICY IF EXISTS "Users can delete own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can delete own recurring transactions" ON public.recurring_transactions FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);

DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 4. TRIGGERS for Updated_at
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 4: Creating triggers...';
END $$;

-- Updated_at trigger
DROP TRIGGER IF EXISTS update_recurring_transactions_updated_at ON public.recurring_transactions;
CREATE TRIGGER update_recurring_transactions_updated_at
    BEFORE UPDATE ON public.recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DO $$
BEGIN
    RAISE NOTICE '✅ Triggers created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 5. HELPER FUNCTION: Process Due Recurring Transactions
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 5: Creating helper function...';
END $$;

CREATE OR REPLACE FUNCTION process_due_recurring_transactions()
RETURNS TABLE (
    created_count INT,
    processed_ids UUID[]
) AS $$
DECLARE
    v_rec RECORD;
    v_created_count INT := 0;
    v_processed_ids UUID[] := ARRAY[]::UUID[];
    v_next_due TIMESTAMPTZ;
BEGIN
    -- Find all active recurring transactions that are due today
    FOR v_rec IN
        SELECT * FROM public.recurring_transactions
        WHERE is_active = true
        AND DATE(next_due_date) <= CURRENT_DATE
        AND (end_date IS NULL OR end_date >= NOW())
    LOOP
        -- Create a new transaction
        INSERT INTO public.transactions (
            profile_id,
            account_id,
            category_id,
            type,
            amount,
            description,
            transaction_date,
            notes,
            is_locked
        ) VALUES (
            v_rec.profile_id,
            v_rec.account_id,
            v_rec.category_id,
            v_rec.type,
            v_rec.amount,
            v_rec.description || ' (Recurring)',
            v_rec.next_due_date,
            v_rec.notes,
            false
        );

        -- Calculate next due date based on frequency
        CASE v_rec.frequency
            WHEN 'daily' THEN
                v_next_due := v_rec.next_due_date + INTERVAL '1 day';
            WHEN 'weekly' THEN
                v_next_due := v_rec.next_due_date + INTERVAL '1 week';
            WHEN 'monthly' THEN
                v_next_due := v_rec.next_due_date + INTERVAL '1 month';
            WHEN 'yearly' THEN
                v_next_due := v_rec.next_due_date + INTERVAL '1 year';
            ELSE
                v_next_due := v_rec.next_due_date + INTERVAL '1 month';
        END CASE;

        -- Update the recurring transaction with new next_due_date
        UPDATE public.recurring_transactions
        SET next_due_date = v_next_due,
            updated_at = NOW()
        WHERE id = v_rec.id;

        -- If end_date is reached, mark as inactive
        IF v_rec.end_date IS NOT NULL AND v_next_due > v_rec.end_date THEN
            UPDATE public.recurring_transactions
            SET is_active = false,
                updated_at = NOW()
            WHERE id = v_rec.id;
        END IF;

        v_created_count := v_created_count + 1;
        v_processed_ids := array_append(v_processed_ids, v_rec.id);
    END LOOP;

    RETURN QUERY SELECT v_created_count, v_processed_ids;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
BEGIN
    RAISE NOTICE '✅ Helper function created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 6. VERIFICATION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '📊 VERIFICATION:';
    RAISE NOTICE '';
END $$;

-- Check if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recurring_transactions') THEN
        RAISE NOTICE '✅ recurring_transactions table exists';
    ELSE
        RAISE NOTICE '❌ recurring_transactions table missing';
    END IF;
END $$;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ RECURRING TRANSACTIONS SCHEMA CREATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✓ recurring_transactions table created';
    RAISE NOTICE '✓ Indexes created for performance';
    RAISE NOTICE '✓ RLS policies configured';
    RAISE NOTICE '✓ Updated_at trigger installed';
    RAISE NOTICE '✓ Helper function for processing created';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Next Steps:';
    RAISE NOTICE '1. Create recurring transaction model in Flutter';
    RAISE NOTICE '2. Create recurring transaction repository';
    RAISE NOTICE '3. Build recurring transaction form';
    RAISE NOTICE '4. Build recurring transaction list view';
    RAISE NOTICE '5. Implement background service';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 To process recurring transactions, call:';
    RAISE NOTICE 'SELECT * FROM process_due_recurring_transactions();';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Ready for recurring transactions!';
    RAISE NOTICE '========================================';
END $$;
