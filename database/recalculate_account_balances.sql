-- =====================================================
-- Recalculate All Account Balances
-- =====================================================
-- This script recalculates account balances based on:
-- Opening Balance + Income - Expenses
--
-- Run this AFTER running fix_transfer_double_balance_update.sql

-- Function to recalculate account balances
CREATE OR REPLACE FUNCTION recalculate_all_account_balances()
RETURNS TABLE(account_id UUID, account_name TEXT, old_balance DECIMAL, new_balance DECIMAL, difference DECIMAL)
LANGUAGE plpgsql
AS $$
DECLARE
    acc RECORD;
    total_income DECIMAL;
    total_expense DECIMAL;
    calculated_balance DECIMAL;
    old_bal DECIMAL;
BEGIN
    -- Loop through all accounts
    FOR acc IN SELECT id, name, opening_balance, current_balance FROM public.accounts
    LOOP
        old_bal := acc.current_balance;

        -- Calculate total income for this account
        SELECT COALESCE(SUM(t.amount), 0)
        INTO total_income
        FROM public.transactions t
        WHERE t.account_id = acc.id AND t.type = 'income';

        -- Calculate total expense for this account
        SELECT COALESCE(SUM(t.amount), 0)
        INTO total_expense
        FROM public.transactions t
        WHERE t.account_id = acc.id AND t.type = 'expense';

        -- Calculate correct balance
        calculated_balance := acc.opening_balance + total_income - total_expense;

        -- Update the account
        UPDATE public.accounts
        SET current_balance = calculated_balance
        WHERE id = acc.id;

        -- Return the result
        account_id := acc.id;
        account_name := acc.name;
        old_balance := old_bal;
        new_balance := calculated_balance;
        difference := calculated_balance - old_bal;

        RETURN NEXT;
    END LOOP;
END;
$$;

-- Run the recalculation and show results
SELECT * FROM recalculate_all_account_balances();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '✅ All account balances have been recalculated!';
    RAISE NOTICE 'Check the results above to see the changes.';
END $$;
