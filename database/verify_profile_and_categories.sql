-- =====================================================
-- Verify Profile and Categories
-- =====================================================

-- 1. Check which profile the budgets belong to
SELECT
  p.id as profile_id,
  p.name as profile_name,
  p.user_id,
  COUNT(b.id) as budget_count
FROM profiles p
LEFT JOIN budgets b ON b.profile_id = p.id
GROUP BY p.id, p.name, p.user_id
ORDER BY budget_count DESC;

-- 2. Check if category IDs match between budgets and categories tables
SELECT
  b.id as budget_id,
  b.category_id as budget_category_id,
  c.id as actual_category_id,
  c.name as category_name,
  c.profile_id as category_profile_id,
  CASE
    WHEN b.category_id = c.id THEN '✅ MATCH'
    ELSE '❌ MISMATCH'
  END as id_match_status
FROM budgets b
LEFT JOIN categories c ON c.id = b.category_id
ORDER BY b.created_at DESC;

-- 3. Show all categories for the profile that has budgets
SELECT
  c.id as category_id,
  c.name as category_name,
  c.profile_id,
  c.type,
  CASE
    WHEN EXISTS (SELECT 1 FROM budgets WHERE category_id = c.id) THEN '✅ Has Budget'
    ELSE '❌ No Budget'
  END as budget_status
FROM categories c
WHERE c.profile_id = '665d12c3-b7c2-46a4-a1f3-958ebbce2980'
  AND c.type = 'expense'
ORDER BY c.name;
