# Database Setup Guide

This folder contains SQL scripts for setting up the Klarity Finance Tracking App database in Supabase.

## Files

1. **schema.sql** - Main database schema with all tables, indexes, RLS policies, and triggers
2. **seed_data.sql** - Default categories and helper functions
3. **functions.sql** - Additional database functions (increment failed attempts, etc.)

## Setup Instructions

### Step 1: Access Supabase SQL Editor

1. Go to your Supabase project dashboard: https://supabase.com/dashboard/project/yjzyimlodxwryofqbcvn
2. Click on "SQL Editor" in the left sidebar

### Step 2: Run Schema Script

1. Click "New Query" in the SQL Editor
2. Copy the entire contents of `schema.sql`
3. Paste it into the SQL Editor
4. Click "Run" or press `Ctrl+Enter` (Windows/Linux) or `Cmd+Enter` (Mac)
5. Wait for the script to complete (should show success message)

### Step 3: Run Seed Data Script

1. Click "New Query" again
2. Copy the entire contents of `seed_data.sql`
3. Paste it into the SQL Editor
4. Click "Run"
5. Wait for completion

### Step 4: Run Additional Functions Script

1. Click "New Query" again
2. Copy the entire contents of `functions.sql`
3. Paste it into the SQL Editor
4. Click "Run"
5. Wait for completion

### Step 5: Verify Setup

Check that all tables were created:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

You should see 14 tables:
- users
- profiles
- accounts
- categories
- transactions
- transfers
- recurring_transactions
- recurring_history
- scheduled_payments
- partial_payments
- emis
- emi_payments
- budgets
- transaction_locks

## Database Schema Overview

### Core Tables

1. **users** - Extended user information from auth.users
2. **profiles** - Personal/Company expense profiles
3. **accounts** - Bank accounts, credit cards, cash, wallets
4. **categories** - Income and expense categories

### Transaction Tables

5. **transactions** - All income and expense transactions
6. **transfers** - Transfers between accounts
7. **recurring_transactions** - Recurring income/expenses
8. **recurring_history** - Track auto-created recurring transactions

### Payment Tables

9. **scheduled_payments** - Future scheduled payments
10. **partial_payments** - Partial payment tracking
11. **emis** - EMI loan tracking
12. **emi_payments** - Individual EMI payment records

### Management Tables

13. **budgets** - Budget limits per category
14. **transaction_locks** - Lock transactions for specific periods

## Security Features

### Row Level Security (RLS)

All tables have RLS enabled to ensure users can only access their own data.

### Authentication

- Uses Supabase Auth for user authentication
- Supports email/password authentication
- Auto-creates user profile on signup

## Helper Functions

The seed script includes several helper functions:

1. **create_default_categories(profile_id)** - Creates default income/expense categories
2. **calculate_running_balance()** - Calculates running balance for transactions
3. **update_account_balance()** - Auto-updates account balance on transaction
4. **update_balance_on_transfer()** - Auto-updates balances on transfer

## Auto-Triggers

- **Auto-create categories** - When a new profile is created, default categories are automatically added
- **Auto-update balances** - Account balances are automatically updated when transactions or transfers are created
- **Auto-update timestamps** - `updated_at` columns are automatically updated on record changes

## Notes

- The database is optimized with indexes for fast queries
- All monetary values use DECIMAL(15, 2) for precision
- Timestamps are stored in UTC using TIMESTAMPTZ
- Default categories are marked as `is_system = true` and cannot be deleted

## Troubleshooting

If you encounter any errors:

1. Make sure you're logged into the correct Supabase project
2. Check that you have necessary permissions (you should be the project owner)
3. Try running each script section by section if full script fails
4. Check the Supabase logs for detailed error messages

## Support

For issues with the database setup, check:
- Supabase documentation: https://supabase.com/docs
- Project roadmap: `/docs/roadmap.md`
- Project context: `/docs/context.md`
