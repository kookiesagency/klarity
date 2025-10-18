-- =====================================================
-- Phase 6: EMI Tracking Schema
-- =====================================================
-- This script creates the emis and emi_payments tables
-- Run this in your Supabase SQL Editor
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Creating EMI tracking schema...';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 1. EMIS TABLE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 1: Creating emis table...';
END $$;

CREATE TABLE IF NOT EXISTS public.emis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    description TEXT,
    total_amount DECIMAL(15, 2) NOT NULL CHECK (total_amount > 0),
    monthly_payment DECIMAL(15, 2) NOT NULL CHECK (monthly_payment > 0),
    total_installments INT NOT NULL CHECK (total_installments > 0),
    paid_installments INT DEFAULT 0 CHECK (paid_installments >= 0 AND paid_installments <= total_installments),
    start_date TIMESTAMPTZ NOT NULL,
    payment_day_of_month INT NOT NULL CHECK (payment_day_of_month >= 1 AND payment_day_of_month <= 31),
    next_payment_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    RAISE NOTICE '✅ EMIs table created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 2. EMI_PAYMENTS TABLE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 2: Creating emi_payments table...';
END $$;

CREATE TABLE IF NOT EXISTS public.emi_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emi_id UUID NOT NULL REFERENCES public.emis(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    installment_number INT NOT NULL CHECK (installment_number > 0),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    is_paid BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(emi_id, installment_number)
);

DO $$
BEGIN
    RAISE NOTICE '✅ EMI payments table created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 3. INDEXES for Performance
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 3: Creating indexes...';
END $$;

-- EMIs indexes
CREATE INDEX IF NOT EXISTS idx_emis_profile_id ON public.emis(profile_id);
CREATE INDEX IF NOT EXISTS idx_emis_account_id ON public.emis(account_id);
CREATE INDEX IF NOT EXISTS idx_emis_category_id ON public.emis(category_id);
CREATE INDEX IF NOT EXISTS idx_emis_next_payment_date ON public.emis(next_payment_date);
CREATE INDEX IF NOT EXISTS idx_emis_is_active ON public.emis(is_active);

-- EMI payments indexes
CREATE INDEX IF NOT EXISTS idx_emi_payments_emi_id ON public.emi_payments(emi_id);
CREATE INDEX IF NOT EXISTS idx_emi_payments_transaction_id ON public.emi_payments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_emi_payments_due_date ON public.emi_payments(due_date);
CREATE INDEX IF NOT EXISTS idx_emi_payments_is_paid ON public.emi_payments(is_paid);

DO $$
BEGIN
    RAISE NOTICE '✅ Indexes created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS) Policies
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 4: Setting up RLS policies...';
END $$;

-- Enable RLS
ALTER TABLE public.emis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emi_payments ENABLE ROW LEVEL SECURITY;

-- EMIs policies
DROP POLICY IF EXISTS "Users can view own emis" ON public.emis;
CREATE POLICY "Users can view own emis" ON public.emis FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can insert own emis" ON public.emis;
CREATE POLICY "Users can insert own emis" ON public.emis FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can update own emis" ON public.emis;
CREATE POLICY "Users can update own emis" ON public.emis FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can delete own emis" ON public.emis;
CREATE POLICY "Users can delete own emis" ON public.emis FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

-- EMI payments policies
DROP POLICY IF EXISTS "Users can view own emi payments" ON public.emi_payments;
CREATE POLICY "Users can view own emi payments" ON public.emi_payments FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert own emi payments" ON public.emi_payments;
CREATE POLICY "Users can insert own emi payments" ON public.emi_payments FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update own emi payments" ON public.emi_payments;
CREATE POLICY "Users can update own emi payments" ON public.emi_payments FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete own emi payments" ON public.emi_payments;
CREATE POLICY "Users can delete own emi payments" ON public.emi_payments FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 5. TRIGGERS for Updated_at
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 5: Creating triggers...';
END $$;

-- Updated_at trigger for emis
DROP TRIGGER IF EXISTS update_emis_updated_at ON public.emis;
CREATE TRIGGER update_emis_updated_at
    BEFORE UPDATE ON public.emis
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DO $$
BEGIN
    RAISE NOTICE '✅ Triggers created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 6. HELPER FUNCTION: Process Due EMI Payments
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 6: Creating helper function...';
END $$;

CREATE OR REPLACE FUNCTION process_due_emi_payments()
RETURNS TABLE (
    created_count INT,
    processed_emi_ids UUID[]
) AS $$
DECLARE
    v_emi RECORD;
    v_created_count INT := 0;
    v_processed_ids UUID[] := ARRAY[]::UUID[];
    v_transaction_id UUID;
    v_next_payment TIMESTAMPTZ;
BEGIN
    -- Find all active EMIs that are due today and not yet completed
    FOR v_emi IN
        SELECT * FROM public.emis
        WHERE is_active = true
        AND paid_installments < total_installments
        AND DATE(next_payment_date) <= CURRENT_DATE
    LOOP
        -- Create a transaction for this EMI payment
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
            v_emi.profile_id,
            v_emi.account_id,
            v_emi.category_id,
            'expense',
            v_emi.monthly_payment,
            v_emi.name || ' - EMI Payment ' || (v_emi.paid_installments + 1) || '/' || v_emi.total_installments,
            v_emi.next_payment_date,
            'Auto-generated EMI payment',
            false
        ) RETURNING id INTO v_transaction_id;

        -- Record the EMI payment
        INSERT INTO public.emi_payments (
            emi_id,
            transaction_id,
            installment_number,
            amount,
            payment_date,
            due_date,
            is_paid,
            notes
        ) VALUES (
            v_emi.id,
            v_transaction_id,
            v_emi.paid_installments + 1,
            v_emi.monthly_payment,
            NOW(),
            v_emi.next_payment_date,
            true,
            'Auto-generated payment'
        );

        -- Calculate next payment date
        v_next_payment := v_emi.next_payment_date + INTERVAL '1 month';

        -- Handle month-end edge cases
        IF EXTRACT(DAY FROM v_next_payment) < v_emi.payment_day_of_month THEN
            v_next_payment := DATE_TRUNC('month', v_next_payment) +
                             INTERVAL '1 month' - INTERVAL '1 day';
        END IF;

        -- Update EMI record
        UPDATE public.emis
        SET paid_installments = paid_installments + 1,
            next_payment_date = v_next_payment,
            is_active = CASE
                WHEN paid_installments + 1 >= total_installments THEN false
                ELSE true
            END,
            updated_at = NOW()
        WHERE id = v_emi.id;

        v_created_count := v_created_count + 1;
        v_processed_ids := array_append(v_processed_ids, v_emi.id);
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
-- 7. VERIFICATION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '📊 VERIFICATION:';
    RAISE NOTICE '';
END $$;

-- Check if tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'emis') THEN
        RAISE NOTICE '✅ emis table exists';
    ELSE
        RAISE NOTICE '❌ emis table missing';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'emi_payments') THEN
        RAISE NOTICE '✅ emi_payments table exists';
    ELSE
        RAISE NOTICE '❌ emi_payments table missing';
    END IF;
END $$;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ EMI TRACKING SCHEMA CREATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✓ emis table created';
    RAISE NOTICE '✓ emi_payments table created';
    RAISE NOTICE '✓ Indexes created for performance';
    RAISE NOTICE '✓ RLS policies configured';
    RAISE NOTICE '✓ Updated_at trigger installed';
    RAISE NOTICE '✓ Auto-payment function created';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Next Steps:';
    RAISE NOTICE '1. Create EMI model in Flutter';
    RAISE NOTICE '2. Create EMI repository';
    RAISE NOTICE '3. Build EMI entry form';
    RAISE NOTICE '4. Build EMI list view';
    RAISE NOTICE '5. Build EMI detail view';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 To process EMI payments, call:';
    RAISE NOTICE 'SELECT * FROM process_due_emi_payments();';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Ready to track EMIs!';
    RAISE NOTICE '========================================';
END $$;
