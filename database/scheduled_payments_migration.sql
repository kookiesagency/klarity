-- =====================================================
-- Scheduled Payments Feature - Safe Migration
-- =====================================================
-- This version handles existing tables safely
-- Run this in Supabase SQL Editor

-- Drop existing tables if they exist (clean slate)
DROP TABLE IF EXISTS public.scheduled_payment_history CASCADE;
DROP TABLE IF EXISTS public.scheduled_payments CASCADE;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS update_scheduled_payment_status() CASCADE;
DROP FUNCTION IF EXISTS process_due_scheduled_payments() CASCADE;

-- =====================================================
-- TABLE: scheduled_payments
-- =====================================================
CREATE TABLE public.scheduled_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    payee_name TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMPTZ NOT NULL,
    reminder_date TIMESTAMPTZ,

    -- Partial payment support
    allow_partial_payment BOOLEAN DEFAULT false,
    total_amount DECIMAL(15, 2) NOT NULL CHECK (total_amount > 0),
    paid_amount DECIMAL(15, 2) DEFAULT 0 CHECK (paid_amount >= 0),

    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'partial', 'completed', 'cancelled')),

    -- Auto-creation flag
    auto_create_transaction BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- =====================================================
-- TABLE: scheduled_payment_history
-- =====================================================
CREATE TABLE public.scheduled_payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheduled_payment_id UUID NOT NULL REFERENCES public.scheduled_payments(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL,
    payment_type TEXT NOT NULL DEFAULT 'manual' CHECK (payment_type IN ('manual', 'auto', 'partial')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX idx_scheduled_payments_profile
ON public.scheduled_payments(profile_id);

CREATE INDEX idx_scheduled_payments_due_date
ON public.scheduled_payments(due_date);

CREATE INDEX idx_scheduled_payments_status
ON public.scheduled_payments(status);

CREATE INDEX idx_scheduled_payments_profile_status_due
ON public.scheduled_payments(profile_id, status, due_date);

CREATE INDEX idx_scheduled_payment_history_scheduled_payment
ON public.scheduled_payment_history(scheduled_payment_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE public.scheduled_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_payment_history ENABLE ROW LEVEL SECURITY;

-- Scheduled Payments Policies
CREATE POLICY "Users can view own scheduled payments"
ON public.scheduled_payments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own scheduled payments"
ON public.scheduled_payments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

CREATE POLICY "Users can update own scheduled payments"
ON public.scheduled_payments FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own scheduled payments"
ON public.scheduled_payments FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

-- Scheduled Payment History Policies
CREATE POLICY "Users can view own payment history"
ON public.scheduled_payment_history FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.scheduled_payments sp
        JOIN public.profiles p ON p.id = sp.profile_id
        WHERE sp.id = scheduled_payment_history.scheduled_payment_id
        AND p.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own payment history"
ON public.scheduled_payment_history FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.scheduled_payments sp
        JOIN public.profiles p ON p.id = sp.profile_id
        WHERE sp.id = scheduled_payment_history.scheduled_payment_id
        AND p.user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own payment history"
ON public.scheduled_payment_history FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.scheduled_payments sp
        JOIN public.profiles p ON p.id = sp.profile_id
        WHERE sp.id = scheduled_payment_history.scheduled_payment_id
        AND p.user_id = auth.uid()
    )
);

-- =====================================================
-- FUNCTION: Auto-update status on payment
-- =====================================================
CREATE OR REPLACE FUNCTION update_scheduled_payment_status()
RETURNS TRIGGER AS $$
DECLARE
    v_paid_amount DECIMAL(15, 2);
    v_total_amount DECIMAL(15, 2);
BEGIN
    -- Calculate total paid amount
    SELECT COALESCE(SUM(amount), 0)
    INTO v_paid_amount
    FROM public.scheduled_payment_history
    WHERE scheduled_payment_id = NEW.scheduled_payment_id;

    -- Get total amount
    SELECT total_amount
    INTO v_total_amount
    FROM public.scheduled_payments
    WHERE id = NEW.scheduled_payment_id;

    -- Update paid_amount, status, and completed_at
    UPDATE public.scheduled_payments
    SET
        paid_amount = v_paid_amount,
        status = CASE
            WHEN v_paid_amount >= v_total_amount THEN 'completed'
            WHEN v_paid_amount > 0 AND v_paid_amount < v_total_amount THEN 'partial'
            ELSE 'pending'
        END,
        completed_at = CASE
            WHEN v_paid_amount >= v_total_amount THEN now()
            ELSE NULL
        END,
        updated_at = now()
    WHERE id = NEW.scheduled_payment_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER: Auto-update status on payment
-- =====================================================
CREATE TRIGGER trigger_update_scheduled_payment_status
AFTER INSERT OR DELETE ON public.scheduled_payment_history
FOR EACH ROW
EXECUTE FUNCTION update_scheduled_payment_status();

-- =====================================================
-- FUNCTION: Process due scheduled payments
-- =====================================================
CREATE OR REPLACE FUNCTION process_due_scheduled_payments()
RETURNS TABLE (
    processed_count INTEGER,
    payment_ids UUID[]
) AS $$
DECLARE
    v_payment RECORD;
    v_transaction_id UUID;
    v_processed_ids UUID[] := '{}';
    v_count INTEGER := 0;
BEGIN
    -- Find all pending scheduled payments that are due today or overdue
    FOR v_payment IN
        SELECT *
        FROM public.scheduled_payments
        WHERE status = 'pending'
        AND due_date <= CURRENT_DATE
        AND auto_create_transaction = true
    LOOP
        -- Create transaction
        INSERT INTO public.transactions (
            profile_id,
            account_id,
            category_id,
            type,
            amount,
            description,
            transaction_date
        )
        VALUES (
            v_payment.profile_id,
            v_payment.account_id,
            v_payment.category_id,
            v_payment.type,
            v_payment.amount,
            COALESCE(v_payment.description, 'Scheduled payment: ' || v_payment.payee_name),
            v_payment.due_date
        )
        RETURNING id INTO v_transaction_id;

        -- Record payment in history
        INSERT INTO public.scheduled_payment_history (
            scheduled_payment_id,
            transaction_id,
            amount,
            payment_date,
            payment_type,
            notes
        )
        VALUES (
            v_payment.id,
            v_transaction_id,
            v_payment.amount,
            now(),
            'auto',
            'Auto-created from scheduled payment'
        );

        -- Add to processed list
        v_processed_ids := array_append(v_processed_ids, v_payment.id);
        v_count := v_count + 1;
    END LOOP;

    RETURN QUERY SELECT v_count, v_processed_ids;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION process_due_scheduled_payments TO authenticated;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Scheduled Payments schema created successfully!';
    RAISE NOTICE '📋 Tables: scheduled_payments, scheduled_payment_history';
    RAISE NOTICE '⚙️  Function: process_due_scheduled_payments()';
    RAISE NOTICE '🎯 Trigger: auto-update status on payment';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 You can now use the Scheduled Payments feature!';
END $$;
