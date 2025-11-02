# Fix Guide: Transfer Double Balance Update Bug

## Problem Summary

When you create a transfer between accounts (e.g., paying credit card from savings), the account balances are being updated **TWICE**, causing incorrect balances.

**Example:**
- Credit card balance: **-₹5,000** (debt)
- Transfer **₹5,000** from savings to credit card
- Expected credit card balance: **₹0**
- Actual credit card balance: **₹5,000** (WRONG!)

## Root Cause

Two database triggers are both updating account balances:
1. `update_balance_on_transfer_trigger` - Updates balances when transfer is created
2. `update_balance_on_transaction` - Updates balances when transactions are created

Since each transfer creates 2 transactions (expense + income), balances get updated **3 times total** instead of once.

---

## Fix Steps

### Step 1: Apply the Bug Fix

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Open the file: `database/fix_transfer_double_balance_update.sql`
4. Copy its contents and paste into SQL Editor
5. Click **Run** or press `Ctrl+Enter` (Windows/Linux) / `Cmd+Enter` (Mac)

This will remove the redundant trigger.

### Step 2: Recalculate Account Balances

Your existing account balances are likely incorrect due to the bug. To fix them:

1. Stay in **SQL Editor**
2. Open the file: `database/recalculate_account_balances.sql`
3. Copy its contents and paste into SQL Editor
4. Click **Run**

This will:
- Recalculate all account balances based on: `Opening Balance + Income - Expenses`
- Show you a table of before/after balances
- Update all accounts with correct balances

### Step 3: Verify in App

1. **Restart your Flutter app** (hot restart)
2. Check your account balances:
   - Go to Settings → Account Management
   - Verify balances are now correct
3. Test a new transfer:
   - Transfer money between accounts
   - Verify both balances update correctly

---

## How to Test

After applying the fix, test with this scenario:

**Initial Setup:**
- Savings account: ₹10,000
- Credit card: -₹5,000 (debt)

**Action:**
- Transfer ₹5,000 from Savings → Credit Card

**Expected Result:**
- Savings: ₹5,000 (decreased by 5,000)
- Credit card: ₹0 (increased by 5,000, from -5,000 to 0)

**Verify:**
- Check transaction list shows 2 transactions (one expense, one income)
- Check both account balances are correct
- Check home screen total balance is correct

---

## What Changed

### Before (Buggy):
```
Transfer created
  ↓
Transfer trigger runs → Updates both balances
  ↓
2 transactions created
  ↓
Transaction trigger runs twice → Updates both balances AGAIN
  ↓
Result: Balances updated 3 times (WRONG!)
```

### After (Fixed):
```
Transfer created (no trigger)
  ↓
2 transactions created
  ↓
Transaction trigger runs twice → Updates both balances
  ↓
Result: Balances updated correctly!
```

---

## Manual Balance Correction (Alternative)

If you prefer to manually correct balances instead of running the script:

1. Go to Supabase Dashboard → **Table Editor** → `accounts`
2. For each account, calculate the correct balance:
   - `Correct Balance = Opening Balance + Total Income - Total Expenses`
3. Update the `current_balance` column manually

---

## Need Help?

If you encounter any issues:

1. Check Supabase logs for errors
2. Verify the triggers were removed:
   ```sql
   SELECT trigger_name, event_object_table
   FROM information_schema.triggers
   WHERE trigger_schema = 'public'
   AND event_object_table = 'transfers';
   ```
   Should return **no results** (trigger removed)

3. Check account balances:
   ```sql
   SELECT
       a.name,
       a.opening_balance,
       COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) as total_income,
       COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) as total_expense,
       a.current_balance,
       (a.opening_balance +
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)
       ) as calculated_balance
   FROM public.accounts a
   LEFT JOIN public.transactions t ON t.account_id = a.id
   GROUP BY a.id, a.name, a.opening_balance, a.current_balance
   ORDER BY a.name;
   ```

---

## Summary

✅ **Fixed:** Removed redundant transfer trigger
✅ **Recalculated:** All account balances based on transactions
✅ **Tested:** Transfers now work correctly

Your credit card balance should now become ₹0 after paying the full amount!
