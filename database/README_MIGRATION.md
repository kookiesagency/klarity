# Database Schema Migration Guide

## Problem
Your Account Management screen shows "No Accounts Yet" because the database schema doesn't match the Flutter code expectations.

## What Changed

### Old Schema (Before)
- Columns: `initial_balance`, `icon`, `color`, `currency`, `notes`
- Account types: `'bank'`, `'credit_card'`, `'cash'`, `'wallet'`

### New Schema (After)
- Columns: `opening_balance`, `bank_name`
- Account types: `'savings'`, `'current'`, `'credit_card'`
- Removed: Wallet account type from app

## Migration Steps

### Option 1: If You Want to Keep Existing Data (Recommended)

Run the migration script in your Supabase SQL Editor:

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `migration_accounts_schema.sql`
4. Click "Run"

This will:
- Add new columns (`opening_balance`, `bank_name`)
- Migrate data from old columns to new ones
- Convert old account types to new types:
  - `'bank'` → `'savings'`
  - `'wallet'` → `'savings'`
  - `'cash'` → `'savings'`
  - `'credit_card'` stays `'credit_card'`
- Remove old unused columns
- Update constraints

### Option 2: Fresh Start (If You Don't Need Existing Data)

If you want to start fresh with clean dummy data:

1. **Delete existing accounts** (in Supabase SQL Editor):
   ```sql
   DELETE FROM public.accounts WHERE profile_id IN (
       SELECT id FROM public.profiles WHERE user_id = 'f43c0d1c-2651-4779-b32d-050f41e11694'
   );
   ```

2. **Run the migration** to update table structure:
   - Copy and paste contents of `migration_accounts_schema.sql`
   - Click "Run"

3. **Insert new dummy data**:
   - Copy and paste contents of `dummy_data.sql`
   - Click "Run"

## Verification

After running the migration, verify your data:

```sql
SELECT
    id,
    name,
    type,
    bank_name,
    account_number,
    opening_balance,
    current_balance,
    is_active,
    profile_id
FROM public.accounts;
```

You should see:
- Correct account types: `'savings'`, `'current'`, or `'credit_card'`
- `opening_balance` and `bank_name` columns populated
- No `initial_balance`, `icon`, `color`, `currency`, or `notes` columns

## What's in the New Dummy Data

After running the updated `dummy_data.sql`, you'll have:

### Personal Profile Accounts (5):
1. HDFC Savings - ₹15,250.00
2. ICICI Savings - ₹12,750.00
3. SBI Savings - ₹8,500.00
4. HDFC Credit Card - -₹8,500.00
5. ICICI Amazon Pay Card - -₹3,250.00

### Company Profile Accounts (3):
1. HDFC Current Account - ₹125,000.00
2. ICICI Current Account - ₹85,000.00
3. Petty Cash - ₹15,000.00

Plus:
- 20+ transactions
- 5 recurring transactions
- 4 scheduled payments
- 2 EMIs
- 4 budgets
- 2 transfers

## After Migration

1. **Restart your Flutter app** - The app should now show your accounts
2. **Test account creation** - Try creating a new account manually
3. **Verify transactions** - Check if transactions are displayed correctly

## Notes

- The app no longer auto-creates default accounts on profile creation (as per your request)
- You'll need to create accounts manually through the app
- The migration preserves your existing data by mapping old types to new ones
- All existing transactions remain linked to their accounts

## Troubleshooting

If accounts still don't show up:

1. Check the profile_id in your accounts matches your active profile:
   ```sql
   SELECT id, name FROM public.profiles WHERE user_id = 'f43c0d1c-2651-4779-b32d-050f41e11694';
   ```

2. Verify accounts exist for that profile:
   ```sql
   SELECT * FROM public.accounts WHERE profile_id = 'YOUR_PROFILE_ID_HERE';
   ```

3. Check Flutter console for any error messages during data fetch
