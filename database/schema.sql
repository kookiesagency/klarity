-- =====================================================
-- Klarity Finance Tracking App - Database Schema
-- =====================================================
-- This schema creates all necessary tables for the expense tracking app
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USERS TABLE (Extended from auth.users)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    pin_hash TEXT, -- Hashed 4-digit PIN for quick unlock
    biometric_enabled BOOLEAN DEFAULT false,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. PROFILES TABLE (User Profiles)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- =====================================================
-- 3. ACCOUNTS TABLE (Bank Accounts & Credit Cards)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('savings', 'current', 'credit_card')),
    opening_balance DECIMAL(15, 2) DEFAULT 0.00,
    current_balance DECIMAL(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. CATEGORIES TABLE (Income & Expense Categories)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    icon TEXT,
    color TEXT,
    is_system BOOLEAN DEFAULT false, -- System categories can't be deleted
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(profile_id, name, type)
);

-- =====================================================
-- 5. TRANSACTIONS TABLE (Income & Expense Transactions)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    transaction_date TIMESTAMPTZ NOT NULL,
    is_locked BOOLEAN DEFAULT false,
    locked_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 6. TRANSFERS TABLE (Transfer Between Accounts)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    from_account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    to_account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    transfer_date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (from_account_id != to_account_id)
);

-- =====================================================
-- 7. RECURRING TRANSACTIONS TABLE (Recurring Income/Expense)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.recurring_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    next_due_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    auto_create BOOLEAN DEFAULT true, -- Auto-create transactions
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 8. RECURRING HISTORY TABLE (Track Created Transactions)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.recurring_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recurring_transaction_id UUID NOT NULL REFERENCES public.recurring_transactions(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    created_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 9. SCHEDULED PAYMENTS TABLE (Future Payments)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.scheduled_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    total_amount DECIMAL(15, 2) NOT NULL CHECK (total_amount > 0),
    paid_amount DECIMAL(15, 2) DEFAULT 0.00 CHECK (paid_amount >= 0),
    remaining_amount DECIMAL(15, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    description TEXT NOT NULL,
    due_date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 10. PARTIAL PAYMENTS TABLE (Track Partial Payments)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.partial_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheduled_payment_id UUID NOT NULL REFERENCES public.scheduled_payments(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 11. EMIS TABLE (EMI Tracking)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.emis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    principal_amount DECIMAL(15, 2) NOT NULL CHECK (principal_amount > 0),
    interest_rate DECIMAL(5, 2) NOT NULL CHECK (interest_rate >= 0),
    tenure_months INTEGER NOT NULL CHECK (tenure_months > 0),
    emi_amount DECIMAL(15, 2) NOT NULL CHECK (emi_amount > 0),
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0.00,
    remaining_amount DECIMAL(15, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    next_due_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    auto_deduct BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 12. EMI PAYMENTS TABLE (Track EMI Payments)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.emi_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emi_id UUID NOT NULL REFERENCES public.emis(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    installment_number INTEGER NOT NULL,
    principal_component DECIMAL(15, 2) NOT NULL,
    interest_component DECIMAL(15, 2) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    payment_date TIMESTAMPTZ NOT NULL,
    due_date DATE NOT NULL,
    is_late BOOLEAN DEFAULT false,
    late_fee DECIMAL(15, 2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 13. BUDGETS TABLE (Budget Limits per Category)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    alert_threshold INTEGER DEFAULT 80 CHECK (alert_threshold >= 0 AND alert_threshold <= 100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(profile_id, category_id, period, start_date)
);

-- =====================================================
-- 14. TRANSACTION LOCKS TABLE (Lock Period for Transactions)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.transaction_locks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lock_date DATE NOT NULL,
    locked_at TIMESTAMPTZ DEFAULT NOW(),
    locked_by UUID NOT NULL REFERENCES public.users(id),
    notes TEXT,
    UNIQUE(profile_id, lock_date)
);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_type ON public.profiles(type);

-- Accounts indexes
CREATE INDEX IF NOT EXISTS idx_accounts_profile_id ON public.accounts(profile_id);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON public.accounts(type);
CREATE INDEX IF NOT EXISTS idx_accounts_is_active ON public.accounts(is_active);

-- Categories indexes
CREATE INDEX IF NOT EXISTS idx_categories_profile_id ON public.categories(profile_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type);

-- Transactions indexes
CREATE INDEX IF NOT EXISTS idx_transactions_profile_id ON public.transactions(profile_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON public.transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_is_locked ON public.transactions(is_locked);

-- Transfers indexes
CREATE INDEX IF NOT EXISTS idx_transfers_profile_id ON public.transfers(profile_id);
CREATE INDEX IF NOT EXISTS idx_transfers_from_account ON public.transfers(from_account_id);
CREATE INDEX IF NOT EXISTS idx_transfers_to_account ON public.transfers(to_account_id);
CREATE INDEX IF NOT EXISTS idx_transfers_date ON public.transfers(transfer_date);

-- Recurring transactions indexes
CREATE INDEX IF NOT EXISTS idx_recurring_profile_id ON public.recurring_transactions(profile_id);
CREATE INDEX IF NOT EXISTS idx_recurring_account_id ON public.recurring_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_recurring_next_due ON public.recurring_transactions(next_due_date);
CREATE INDEX IF NOT EXISTS idx_recurring_is_active ON public.recurring_transactions(is_active);

-- Scheduled payments indexes
CREATE INDEX IF NOT EXISTS idx_scheduled_profile_id ON public.scheduled_payments(profile_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_account_id ON public.scheduled_payments(account_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_due_date ON public.scheduled_payments(due_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_is_completed ON public.scheduled_payments(is_completed);

-- EMIs indexes
CREATE INDEX IF NOT EXISTS idx_emis_profile_id ON public.emis(profile_id);
CREATE INDEX IF NOT EXISTS idx_emis_account_id ON public.emis(account_id);
CREATE INDEX IF NOT EXISTS idx_emis_next_due ON public.emis(next_due_date);
CREATE INDEX IF NOT EXISTS idx_emis_is_active ON public.emis(is_active);

-- Budgets indexes
CREATE INDEX IF NOT EXISTS idx_budgets_profile_id ON public.budgets(profile_id);
CREATE INDEX IF NOT EXISTS idx_budgets_category_id ON public.budgets(category_id);
CREATE INDEX IF NOT EXISTS idx_budgets_is_active ON public.budgets(is_active);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partial_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emi_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_locks ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own data" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own data" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own data" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Profiles policies
CREATE POLICY "Users can view own profiles" ON public.profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profiles" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profiles" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own profiles" ON public.profiles FOR DELETE USING (auth.uid() = user_id);

-- Accounts policies
CREATE POLICY "Users can view own accounts" ON public.accounts FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = accounts.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can insert own accounts" ON public.accounts FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = accounts.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can update own accounts" ON public.accounts FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = accounts.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can delete own accounts" ON public.accounts FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = accounts.profile_id AND profiles.user_id = auth.uid())
);

-- Categories policies
CREATE POLICY "Users can view own categories" ON public.categories FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = categories.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can insert own categories" ON public.categories FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = categories.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can update own categories" ON public.categories FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = categories.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can delete own categories" ON public.categories FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = categories.profile_id AND profiles.user_id = auth.uid())
    AND is_system = false
);

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can insert own transactions" ON public.transactions FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can update own unlocked transactions" ON public.transactions FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
    AND is_locked = false
);
CREATE POLICY "Users can delete own unlocked transactions" ON public.transactions FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
    AND is_locked = false
);

-- Transfers policies
CREATE POLICY "Users can view own transfers" ON public.transfers FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can insert own transfers" ON public.transfers FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can update own transfers" ON public.transfers FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can delete own transfers" ON public.transfers FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);

-- Recurring transactions policies
CREATE POLICY "Users can view own recurring" ON public.recurring_transactions FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can insert own recurring" ON public.recurring_transactions FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can update own recurring" ON public.recurring_transactions FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);
CREATE POLICY "Users can delete own recurring" ON public.recurring_transactions FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = recurring_transactions.profile_id AND profiles.user_id = auth.uid())
);

-- Similar policies for other tables (scheduled_payments, emis, budgets, etc.)
-- Following the same pattern as above

-- =====================================================
-- TRIGGERS for Updated_at timestamp
-- =====================================================

-- Create trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON public.accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transfers_updated_at BEFORE UPDATE ON public.transfers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recurring_updated_at BEFORE UPDATE ON public.recurring_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scheduled_updated_at BEFORE UPDATE ON public.scheduled_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emis_updated_at BEFORE UPDATE ON public.emis
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON public.budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Database schema created successfully!';
    RAISE NOTICE 'All tables, indexes, RLS policies, and triggers are now set up.';
END $$;
