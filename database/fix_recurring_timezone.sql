-- Fix recurring transaction processing to respect Asia/Kolkata timezone
-- Run this in Supabase SQL editor.

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
    v_local_today DATE := (NOW() AT TIME ZONE 'Asia/Kolkata')::DATE;
BEGIN
    FOR v_rec IN
        SELECT *
        FROM public.recurring_transactions
        WHERE is_active = true
          AND (next_due_date AT TIME ZONE 'Asia/Kolkata')::DATE <= v_local_today
          AND (end_date IS NULL OR (end_date AT TIME ZONE 'Asia/Kolkata')::DATE >= v_local_today)
    LOOP
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
            v_rec.profile_id,
            v_rec.account_id,
            v_rec.category_id,
            v_rec.type,
            v_rec.amount,
            v_rec.description || ' (Recurring)',
            v_rec.next_due_date,
            false
        );

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

        UPDATE public.recurring_transactions
        SET next_due_date = v_next_due,
            updated_at = NOW()
        WHERE id = v_rec.id;

        IF v_rec.end_date IS NOT NULL
           AND (v_next_due AT TIME ZONE 'Asia/Kolkata')::DATE >
               (v_rec.end_date AT TIME ZONE 'Asia/Kolkata')::DATE THEN
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
