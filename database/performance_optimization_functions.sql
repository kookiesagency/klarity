-- =====================================================
-- Performance Optimization - Database Functions
-- =====================================================
-- Run this in your Supabase SQL Editor to add optimized
-- database functions for better query performance

-- Function to calculate category spending efficiently using database aggregation
-- This is much faster than fetching all rows and summing client-side
CREATE OR REPLACE FUNCTION get_category_spending(
    p_profile_id UUID,
    p_category_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS DECIMAL(15, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total DECIMAL(15, 2);
BEGIN
    -- Use database SUM aggregation for optimal performance
    SELECT COALESCE(SUM(amount), 0.00)
    INTO v_total
    FROM public.transactions
    WHERE profile_id = p_profile_id
      AND category_id = p_category_id
      AND type = 'expense'
      AND transaction_date >= p_start_date
      AND transaction_date <= p_end_date;

    RETURN v_total;
END;
$$;

-- Function to get analytics summary efficiently
-- Returns aggregated data without fetching all transactions
CREATE OR REPLACE FUNCTION get_analytics_summary(
    p_profile_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'total_income', COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0.00),
        'total_expense', COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0.00),
        'transaction_count', COUNT(*)
    )
    INTO v_result
    FROM public.transactions
    WHERE profile_id = p_profile_id
      AND transaction_date >= p_start_date
      AND transaction_date <= p_end_date;

    RETURN v_result;
END;
$$;

-- Function to get category breakdown for analytics
-- Returns top spending categories efficiently
CREATE OR REPLACE FUNCTION get_category_breakdown(
    p_profile_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    category_id UUID,
    category_name TEXT,
    category_icon TEXT,
    total_amount DECIMAL(15, 2),
    transaction_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.category_id,
        c.name as category_name,
        c.icon as category_icon,
        SUM(t.amount) as total_amount,
        COUNT(*) as transaction_count
    FROM public.transactions t
    INNER JOIN public.categories c ON c.id = t.category_id
    WHERE t.profile_id = p_profile_id
      AND t.type = 'expense'
      AND t.transaction_date >= p_start_date
      AND t.transaction_date <= p_end_date
    GROUP BY t.category_id, c.name, c.icon
    ORDER BY total_amount DESC
    LIMIT p_limit;
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_category_spending TO authenticated;
GRANT EXECUTE ON FUNCTION get_analytics_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_category_breakdown TO authenticated;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Performance optimization functions created successfully!';
    RAISE NOTICE 'Database-side aggregation will significantly improve query performance.';
END $$;
