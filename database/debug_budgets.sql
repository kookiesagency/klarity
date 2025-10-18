-- =====================================================
-- Debug Budgets Query
-- =====================================================
-- Run this to see all budgets and their status

SELECT
  b.id as budget_id,
  b.profile_id,
  b.category_id,
  c.name as category_name,
  b.amount,
  b.period,
  b.is_active,
  b.start_date,
  b.end_date,
  b.alert_threshold,
  b.created_at
FROM budgets b
LEFT JOIN categories c ON c.id = b.category_id
ORDER BY b.created_at DESC;

-- Check if budgets exist but are inactive
SELECT
  COUNT(*) as total_budgets,
  SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_budgets,
  SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END) as inactive_budgets
FROM budgets;

-- If budgets exist but are not showing, run this to reactivate them:
-- UPDATE budgets SET is_active = true WHERE is_active = false;
