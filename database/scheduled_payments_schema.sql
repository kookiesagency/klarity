-- =====================================================
-- Scheduled Payments Feature - Database Schema
-- =====================================================
-- Run this in Supabase SQL Editor to add scheduled payments support

-- Table: scheduled_payments
-- Stores scheduled future payments (income/expenses)
CREATE TABLE IF NOT EXISTS public.scheduled_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    payee_name TEXT NOT NULL, -- Who you're paying or receiving from
    description TEXT,
    due_date TIMESTAMPTZ NOT NULL,
    reminder_date TIMESTAMPTZ, -- Optional reminder before due date

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

-- Table: scheduled_payment_history
-- Tracks partial payment history
CREATE TABLE IF NOT EXISTS public.scheduled_payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheduled_payment_id UUID NOT NULL REFERENCES public.scheduled_payments(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL,
    payment_type TEXT NOT NULL DEFAULT 'manual' CHECK (payment_type IN ('manual', 'auto', 'partial')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_scheduled_payments_profile
ON public.scheduled_payments(profile_id);

CREATE INDEX IF NOT EXISTS idx_scheduled_payments_due_date
ON public.scheduled_payments(due_date);

CREATE INDEX IF NOT EXISTS idx_scheduled_payments_status
ON public.scheduled_payments(status);

CREATE INDEX IF NOT EXISTS idx_scheduled_payments_profile_status_due
ON public.scheduled_payments(profile_id, status, due_date);

CREATE INDEX IF NOT EXISTS idx_scheduled_payment_history_scheduled_payment
ON public.scheduled_payment_history(scheduled_payment_id);

-- Row Level Security (RLS) Policies
ALTER TABLE public.scheduled_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_payment_history ENABLE ROW LEVEL SECURITY;

-- Scheduled Payments Policies
DROP POLICY IF EXISTS "Users can view own scheduled payments" ON public.scheduled_payments;
CREATE POLICY "Users can view own scheduled payments"
ON public.scheduled_payments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert own scheduled payments" ON public.scheduled_payments;
CREATE POLICY "Users can insert own scheduled payments"
ON public.scheduled_payments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update own scheduled payments" ON public.scheduled_payments;
CREATE POLICY "Users can update own scheduled payments"
ON public.scheduled_payments FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = scheduled_payments.profile_id
        AND profiles.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete own scheduled payments" ON public.scheduled_payments;
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
DROP POLICY IF EXISTS "Users can view own payment history" ON public.scheduled_payment_history;
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

DROP POLICY IF EXISTS "Users can insert own payment history" ON public.scheduled_payment_history;
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

DROP POLICY IF EXISTS "Users can delete own payment history" ON public.scheduled_payment_history;
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

-- Function to update scheduled payment status based on paid amount
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

    -- Update paid_amount, status, and completed_at in one query
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

-- Trigger to auto-update status on payment
DROP TRIGGER IF EXISTS trigger_update_scheduled_payment_status ON public.scheduled_payment_history;
CREATE TRIGGER trigger_update_scheduled_payment_status
AFTER INSERT OR DELETE ON public.scheduled_payment_history
FOR EACH ROW
EXECUTE FUNCTION update_scheduled_payment_status();

-- Function to process due scheduled payments
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
    RAISE NOTICE 'Tables: scheduled_payments, scheduled_payment_history';
    RAISE NOTICE 'Function: process_due_scheduled_payments()';
END $$;
