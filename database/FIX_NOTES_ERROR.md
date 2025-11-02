# Fix: Column "notes" Does Not Exist Error

## Problem

You're getting this error:
```
column "notes" of relation "transactions" does not exist
```

## Root Cause

The EMI auto-payment function in your database is trying to insert transactions with a `notes` column, but your transactions table doesn't have this column (and you don't want it).

## Solution

**You already have the fix!** Just need to apply it.

### Quick Fix (1 minute):

1. **Open Supabase Dashboard** → **SQL Editor**
2. **Open this file:** `database/fix_emi_auto_payment_function.sql`
3. **Copy the entire contents**
4. **Paste into SQL Editor**
5. **Click Run** or press `Ctrl+Enter` / `Cmd+Enter`

That's it! ✅

---

## What This Does

The fix updates the `process_due_emi_payments()` function to:
- Remove `notes` column from the transaction INSERT
- Keep `notes` in the emi_payments table (where it belongs)

### Before (Broken):
```sql
INSERT INTO transactions (
    ...,
    notes  ← Trying to insert this
)
```

### After (Fixed):
```sql
INSERT INTO transactions (
    ...
    -- notes removed
)
```

---

## Verify It Worked

After running the script, restart your app and check:
- ✅ No more "notes" column error
- ✅ Auto-Payment Settings page loads correctly
- ✅ EMI payments process successfully
- ✅ Home screen shows data

---

## Summary

| Issue | EMI function trying to use notes column |
|-------|----------------------------------------|
| **Fix** | Run `fix_emi_auto_payment_function.sql` |
| **Time** | 30 seconds |
| **Risk** | Zero (only updates function) |

Done! 🎉
