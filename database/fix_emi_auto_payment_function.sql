-- =====================================================
-- Fix EMI Auto-Payment Function
-- =====================================================
-- This updates the process_due_emi_payments function
-- to remove the 'notes' column from transactions insert
-- =====================================================

-- Drop and recreate the function with the fix
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
        -- Create a transaction for this EMI payment (WITHOUT notes column)
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

        -- Record the EMI payment (notes column is kept here - it's for emi_payments table)
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
