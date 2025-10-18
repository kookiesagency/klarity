-- =====================================================
-- COMPLETE EMI TABLE RECREATION
-- =====================================================
-- This script drops and recreates the emis table with
-- ALL required columns
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Recreating EMI tables...';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 1. DROP EXISTING TABLES (CASCADE to drop dependencies)
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 1: Dropping existing tables...';
END $$;

DROP TABLE IF EXISTS public.emi_payments CASCADE;
DROP TABLE IF EXISTS public.emis CASCADE;

DO $$
BEGIN
    RAISE NOTICE '✅ Old tables dropped';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 2. CREATE EMIS TABLE WITH ALL COLUMNS
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 2: Creating emis table...';
END $$;

CREATE TABLE public.emis (
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    RAISE NOTICE '✅ EMIs table created with all columns';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 3. CREATE EMI_PAYMENTS TABLE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 3: Creating emi_payments table...';
END $$;

CREATE TABLE public.emi_payments (
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
-- 4. CREATE INDEXES
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 4: Creating indexes...';
END $$;

-- EMIs indexes
CREATE INDEX idx_emis_profile_id ON public.emis(profile_id);
CREATE INDEX idx_emis_account_id ON public.emis(account_id);
CREATE INDEX idx_emis_category_id ON public.emis(category_id);
CREATE INDEX idx_emis_next_payment_date ON public.emis(next_payment_date);
CREATE INDEX idx_emis_is_active ON public.emis(is_active);

-- EMI payments indexes
CREATE INDEX idx_emi_payments_emi_id ON public.emi_payments(emi_id);
CREATE INDEX idx_emi_payments_transaction_id ON public.emi_payments(transaction_id);
CREATE INDEX idx_emi_payments_due_date ON public.emi_payments(due_date);
CREATE INDEX idx_emi_payments_is_paid ON public.emi_payments(is_paid);

DO $$
BEGIN
    RAISE NOTICE '✅ Indexes created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 5. ENABLE ROW LEVEL SECURITY
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 5: Setting up RLS...';
END $$;

-- Enable RLS
ALTER TABLE public.emis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emi_payments ENABLE ROW LEVEL SECURITY;

-- EMIs policies
CREATE POLICY "Users can view own emis" ON public.emis FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

CREATE POLICY "Users can insert own emis" ON public.emis FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

CREATE POLICY "Users can update own emis" ON public.emis FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

CREATE POLICY "Users can delete own emis" ON public.emis FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = emis.profile_id AND profiles.user_id = auth.uid())
);

-- EMI payments policies
CREATE POLICY "Users can view own emi payments" ON public.emi_payments FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own emi payments" ON public.emi_payments FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

CREATE POLICY "Users can update own emi payments" ON public.emi_payments FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.emis
        JOIN public.profiles ON profiles.id = emis.profile_id
        WHERE emis.id = emi_payments.emi_id AND profiles.user_id = auth.uid()
    )
);

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
-- 6. CREATE TRIGGERS
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 6: Creating triggers...';
END $$;

-- Updated_at trigger for emis
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
-- 7. CREATE AUTO-PAYMENT FUNCTION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 7: Creating auto-payment function...';
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
            is_locked
        ) VALUES (
            v_emi.profile_id,
            v_emi.account_id,
            v_emi.category_id,
            'expense',
            v_emi.monthly_payment,
            v_emi.name || ' - EMI Payment ' || (v_emi.paid_installments + 1) || '/' || v_emi.total_installments,
            v_emi.next_payment_date,
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
    RAISE NOTICE '✅ Auto-payment function created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ EMI TABLES RECREATED SUCCESSFULLY!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✓ emis table created with ALL columns';
    RAISE NOTICE '✓ emi_payments table created';
    RAISE NOTICE '✓ Indexes created';
    RAISE NOTICE '✓ RLS policies configured';
    RAISE NOTICE '✓ Triggers installed';
    RAISE NOTICE '✓ Auto-payment function created';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Ready to create EMIs!';
    RAISE NOTICE '========================================';
END $$;
