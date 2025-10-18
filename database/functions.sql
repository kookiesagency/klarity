-- =====================================================
-- Additional Database Functions
-- =====================================================
-- Run this after schema.sql and seed_data.sql

-- =====================================================
-- FUNCTION: Increment Failed Login Attempts
-- =====================================================

CREATE OR REPLACE FUNCTION increment_failed_attempts(user_id UUID)
RETURNS void AS $$
DECLARE
    current_attempts INTEGER;
    max_attempts INTEGER := 5;
    lockout_duration INTERVAL := '15 minutes';
BEGIN
    -- Get current failed attempts
    SELECT failed_login_attempts INTO current_attempts
    FROM public.users
    WHERE id = user_id;

    -- Increment attempts
    current_attempts := current_attempts + 1;

    -- Check if account should be locked
    IF current_attempts >= max_attempts THEN
        UPDATE public.users
        SET
            failed_login_attempts = current_attempts,
            account_locked_until = NOW() + lockout_duration
        WHERE id = user_id;
    ELSE
        UPDATE public.users
        SET failed_login_attempts = current_attempts
        WHERE id = user_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Additional functions created successfully!';
END $$;
