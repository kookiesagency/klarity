-- =====================================================
-- Phase 4: Transactions & Transfers Schema
-- =====================================================
-- This script creates the transactions and transfers tables
-- Run this in your Supabase SQL Editor
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Creating transactions and transfers schema...';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 1. TRANSACTIONS TABLE (Income & Expense)
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 1: Creating transactions table...';
END $$;

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_locked BOOLEAN DEFAULT false,
    locked_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    RAISE NOTICE '✅ Transactions table created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 2. TRANSFERS TABLE (Transfer Between Accounts)
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 2: Creating transfers table...';
END $$;

CREATE TABLE IF NOT EXISTS public.transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    from_account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    to_account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    transfer_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (from_account_id != to_account_id)
);

DO $$
BEGIN
    RAISE NOTICE '✅ Transfers table created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 3. INDEXES for Performance
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 3: Creating indexes...';
END $$;

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

DO $$
BEGIN
    RAISE NOTICE '✅ Indexes created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS) Policies
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 4: Setting up RLS policies...';
END $$;

-- Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transfers ENABLE ROW LEVEL SECURITY;

-- Transactions policies
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
CREATE POLICY "Users can insert own transactions" ON public.transactions FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can update own unlocked transactions" ON public.transactions;
CREATE POLICY "Users can update own unlocked transactions" ON public.transactions FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
    AND is_locked = false
);

DROP POLICY IF EXISTS "Users can delete own unlocked transactions" ON public.transactions;
CREATE POLICY "Users can delete own unlocked transactions" ON public.transactions FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transactions.profile_id AND profiles.user_id = auth.uid())
    AND is_locked = false
);

-- Transfers policies
DROP POLICY IF EXISTS "Users can view own transfers" ON public.transfers;
CREATE POLICY "Users can view own transfers" ON public.transfers FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can insert own transfers" ON public.transfers;
CREATE POLICY "Users can insert own transfers" ON public.transfers FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can update own transfers" ON public.transfers;
CREATE POLICY "Users can update own transfers" ON public.transfers FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can delete own transfers" ON public.transfers;
CREATE POLICY "Users can delete own transfers" ON public.transfers FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = transfers.profile_id AND profiles.user_id = auth.uid())
);

DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 5. TRIGGERS for Updated_at and Balance Updates
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Step 5: Creating triggers...';
END $$;

-- Updated_at triggers
DROP TRIGGER IF EXISTS update_transactions_updated_at ON public.transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_transfers_updated_at ON public.transfers;
CREATE TRIGGER update_transfers_updated_at
    BEFORE UPDATE ON public.transfers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Balance update trigger for transactions
CREATE OR REPLACE FUNCTION update_account_balance_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    -- On INSERT: Update account balance based on transaction type
    IF TG_OP = 'INSERT' THEN
        IF NEW.type = 'income' THEN
            UPDATE public.accounts
            SET current_balance = current_balance + NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.account_id;
        ELSIF NEW.type = 'expense' THEN
            UPDATE public.accounts
            SET current_balance = current_balance - NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.account_id;
        END IF;
        RETURN NEW;
    END IF;

    -- On UPDATE: Reverse old transaction and apply new one
    IF TG_OP = 'UPDATE' THEN
        -- Reverse old transaction
        IF OLD.type = 'income' THEN
            UPDATE public.accounts
            SET current_balance = current_balance - OLD.amount
            WHERE id = OLD.account_id;
        ELSIF OLD.type = 'expense' THEN
            UPDATE public.accounts
            SET current_balance = current_balance + OLD.amount
            WHERE id = OLD.account_id;
        END IF;

        -- Apply new transaction
        IF NEW.type = 'income' THEN
            UPDATE public.accounts
            SET current_balance = current_balance + NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.account_id;
        ELSIF NEW.type = 'expense' THEN
            UPDATE public.accounts
            SET current_balance = current_balance - NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.account_id;
        END IF;
        RETURN NEW;
    END IF;

    -- On DELETE: Reverse transaction
    IF TG_OP = 'DELETE' THEN
        IF OLD.type = 'income' THEN
            UPDATE public.accounts
            SET current_balance = current_balance - OLD.amount,
                updated_at = NOW()
            WHERE id = OLD.account_id;
        ELSIF OLD.type = 'expense' THEN
            UPDATE public.accounts
            SET current_balance = current_balance + OLD.amount,
                updated_at = NOW()
            WHERE id = OLD.account_id;
        END IF;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_balance_on_transaction ON public.transactions;
CREATE TRIGGER update_balance_on_transaction
    AFTER INSERT OR UPDATE OR DELETE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance_on_transaction();

-- Balance update trigger for transfers
CREATE OR REPLACE FUNCTION update_balance_on_transfer()
RETURNS TRIGGER AS $$
BEGIN
    -- On INSERT: Deduct from source, add to destination
    IF TG_OP = 'INSERT' THEN
        UPDATE public.accounts
        SET current_balance = current_balance - NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.from_account_id;

        UPDATE public.accounts
        SET current_balance = current_balance + NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.to_account_id;
        RETURN NEW;
    END IF;

    -- On UPDATE: Reverse old and apply new
    IF TG_OP = 'UPDATE' THEN
        -- Reverse old transfer
        UPDATE public.accounts
        SET current_balance = current_balance + OLD.amount
        WHERE id = OLD.from_account_id;

        UPDATE public.accounts
        SET current_balance = current_balance - OLD.amount
        WHERE id = OLD.to_account_id;

        -- Apply new transfer
        UPDATE public.accounts
        SET current_balance = current_balance - NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.from_account_id;

        UPDATE public.accounts
        SET current_balance = current_balance + NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.to_account_id;
        RETURN NEW;
    END IF;

    -- On DELETE: Reverse transfer
    IF TG_OP = 'DELETE' THEN
        UPDATE public.accounts
        SET current_balance = current_balance + OLD.amount,
            updated_at = NOW()
        WHERE id = OLD.from_account_id;

        UPDATE public.accounts
        SET current_balance = current_balance - OLD.amount,
            updated_at = NOW()
        WHERE id = OLD.to_account_id;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_balance_on_transfer_trigger ON public.transfers;
CREATE TRIGGER update_balance_on_transfer_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.transfers
    FOR EACH ROW
    EXECUTE FUNCTION update_balance_on_transfer();

DO $$
BEGIN
    RAISE NOTICE '✅ Triggers created';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 6. VERIFICATION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '📊 VERIFICATION:';
    RAISE NOTICE '';
END $$;

-- Check if tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transactions') THEN
        RAISE NOTICE '✅ transactions table exists';
    ELSE
        RAISE NOTICE '❌ transactions table missing';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transfers') THEN
        RAISE NOTICE '✅ transfers table exists';
    ELSE
        RAISE NOTICE '❌ transfers table missing';
    END IF;
END $$;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ TRANSACTIONS SCHEMA CREATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✓ transactions table created';
    RAISE NOTICE '✓ transfers table created';
    RAISE NOTICE '✓ Indexes created for performance';
    RAISE NOTICE '✓ RLS policies configured';
    RAISE NOTICE '✓ Triggers for balance updates installed';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Next Steps:';
    RAISE NOTICE '1. Create transaction model in Flutter';
    RAISE NOTICE '2. Create transaction repository';
    RAISE NOTICE '3. Build transaction entry form';
    RAISE NOTICE '4. Build transaction list view';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Ready to track transactions!';
    RAISE NOTICE '========================================';
END $$;
