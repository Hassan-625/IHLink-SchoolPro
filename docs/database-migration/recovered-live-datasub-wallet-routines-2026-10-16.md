# Recovered live DataSub wallet routine snapshot

**Captured:** 2026-10-16  
**Project:** Supabase ref `lnqsroyiybutkfngbyge`  
**Method:** Read-only catalog inspection using `pg_get_functiondef`.  
**Purpose:** Forensic reference for source-to-live parity and MySQL port design.

> This is a snapshot of the currently deployed routine definitions, not the original migration file and not a migration to replay. It was recovered from the live database catalog after the migration ledger entry `20260925191607 harden_datasub_refund_idempotency` could not be found by exact filename in the inspected repositories. Do not apply this file to production or infer the original migration's exact content from it.

## `public.reserve_datasub_wallet(uuid, uuid, numeric, text)`

```sql
CREATE OR REPLACE FUNCTION public.reserve_datasub_wallet(p_user uuid, p_transaction uuid, p_amount numeric, p_reference text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare t public.datasub_transactions%rowtype; prior public.wallet_ledger%rowtype; balance_now numeric;
begin
 if p_user is null or p_transaction is null or p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then return false; end if;
 select * into t from public.datasub_transactions where id=p_transaction for update;
 if t.id is null or t.user_id<>p_user or t.amount<>p_amount or p_reference is distinct from 'RESERVE:'||t.reference then return false; end if;
 select * into prior from public.wallet_ledger where reference=p_reference;
 if prior.id is not null then return prior.user_id=p_user and prior.transaction_id=p_transaction and prior.amount=p_amount and prior.entry_type='reserve'; end if;
 if t.status<>'pending' then return false; end if;
 select balance into balance_now from public.datasub_wallets where user_id=p_user for update;
 if balance_now is null or balance_now<p_amount then return false; end if;
 insert into public.wallet_ledger(user_id,transaction_id,entry_type,amount,reference) values(p_user,p_transaction,'reserve',p_amount,p_reference);
 update public.datasub_wallets set balance=balance-p_amount,updated_at=now() where user_id=p_user;
 return true;
end $function$
```

## `public.refund_datasub_wallet(uuid, uuid, numeric, text)`

```sql
CREATE OR REPLACE FUNCTION public.refund_datasub_wallet(p_user uuid, p_transaction uuid, p_amount numeric, p_reference text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare t public.datasub_transactions%rowtype; prior public.wallet_ledger%rowtype;
begin
 if p_user is null or p_transaction is null or p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then return false; end if;
 select * into t from public.datasub_transactions where id=p_transaction for update;
 if t.id is null or t.user_id<>p_user or t.amount<>p_amount or p_reference is distinct from 'REFUND:'||t.reference then return false; end if;
 select * into prior from public.wallet_ledger where reference=p_reference;
 if prior.id is not null then return prior.user_id=p_user and prior.transaction_id=p_transaction and prior.amount=p_amount and prior.entry_type='refund'; end if;
 if t.status='success' or not exists(select 1 from public.wallet_ledger where reference='RESERVE:'||t.reference and user_id=p_user and transaction_id=p_transaction and amount=p_amount and entry_type='reserve') then return false; end if;
 perform 1 from public.datasub_wallets where user_id=p_user for update;
 if not found then raise exception 'DataSub wallet not found'; end if;
 insert into public.wallet_ledger(user_id,transaction_id,entry_type,amount,reference) values(p_user,p_transaction,'refund',p_amount,p_reference);
 update public.datasub_wallets set balance=balance+p_amount,updated_at=now() where user_id=p_user;
 return true;
end $function$
```

## Behavior preserved by the live definitions

- Both reject null identifiers, null/non-positive amounts, and amounts with more than two decimal places.
- Both lock the transaction row first and validate transaction owner, amount and exact derived ledger reference.
- Reservation only proceeds while the transaction is pending; it checks for an existing ledger entry before wallet debit.
- A matching existing reserve/refund ledger entry is idempotent; an existing entry with inconsistent user, transaction, amount or type returns false.
- Reservation locks the wallet and checks available balance before recording the reserve ledger entry and debiting the wallet.
- Refund requires a matching reserve ledger entry and rejects a transaction whose status is `success`; it locks the wallet, records the refund entry, then credits the wallet.
- Both routines are `SECURITY DEFINER` with an empty search path. All table references in the displayed bodies are schema-qualified.
- These functions do not alone establish the entire transaction lifecycle. Verify callers, status transitions, unique constraints/indexes on ledger references, callback ordering, transaction isolation and all other refund paths before porting.

## Provenance result

The exact ledger name `20260925191607 harden_datasub_refund_idempotency` was not recovered as a file from the inspected repository trees or exact-path commit history. The initial checked-in `20260924210000_datasub_transaction_safety.sql` is demonstrably weaker and is **not** an equivalent replacement. The live function definitions are recovered; the original migration artifact and its original commit remain unresolved.
