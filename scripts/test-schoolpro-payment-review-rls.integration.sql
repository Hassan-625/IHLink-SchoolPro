-- Isolated disposable PostgreSQL test for effective payment-review RLS.
-- Applies the actual policy migration to minimal test-only tables and switches to authenticated.
create schema if not exists auth;
create schema if not exists private;
do $$ begin create role authenticated nologin; exception when duplicate_object then null; end $$;
do $$ begin create type public.user_role as enum ('super_admin'); exception when duplicate_object then null; end $$;

create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create or replace function private.is_admin(p_roles public.user_role[])
returns boolean language sql stable
as $$ select coalesce(current_setting('test.is_super_admin', true), 'false') = 'true' $$;
create or replace function private.schoolpro_module_allowed(p_school uuid, p_module text)
returns boolean language sql stable
as $$ select p_module = 'finance' and current_setting('test.finance_school', true) = p_school::text $$;

create table public.schoolpro_guardian_links (
 id uuid primary key, school_id uuid not null, student_id uuid not null,
 guardian_user_id uuid not null, status text not null
);
create table public.schoolpro_payment_submissions (
 id uuid primary key, school_id uuid not null, submitted_by uuid not null,
 bank_account_id uuid, total_amount numeric not null, payment_date date not null,
 payer_name text, bank_reference text, receipt_path text not null,
 receipt_mime text, status text not null default 'pending'
);
create table public.schoolpro_payment_allocations (
 id uuid primary key, submission_id uuid not null, school_id uuid not null,
 student_id uuid not null, invoice_id uuid not null, amount numeric not null
);
create table public.schoolpro_payment_proofs (
 id uuid primary key, school_id uuid not null, student_id uuid not null,
 submitted_by uuid not null, receipt_path text
);
create table public.schoolpro_fee_payments (
 id uuid primary key, school_id uuid not null, student_id uuid not null, amount numeric not null
);

insert into public.schoolpro_guardian_links values
 ('a0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001','active'),
 ('a0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','active');
insert into public.schoolpro_payment_submissions values
 ('e0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001',null,100,current_date,'Guardian A','REF-A','path/a.pdf','application/pdf','pending'),
 ('e0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000002',null,200,current_date,'Guardian B','REF-B','path/b.pdf','application/pdf','pending');
insert into public.schoolpro_payment_allocations values
 ('f0000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001',100),
 ('f0000000-0000-0000-0000-000000000002','e0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000002',200);
insert into public.schoolpro_payment_proofs values
 ('11000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001','path/a.pdf'),
 ('11000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','path/b.pdf');
insert into public.schoolpro_fee_payments values
 ('12000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001',100),
 ('12000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002',200);

-- Representative pre-existing permissive policies. The migration under test adds restrictive guards
-- and Super Admin SELECT policies; these permissive policies model the established guardian/finance scope.
create policy guardian_or_finance_read_submissions on public.schoolpro_payment_submissions for select to authenticated using (
 private.schoolpro_module_allowed(school_id,'finance') or submitted_by=auth.uid());
create policy guardian_own_insert_submissions on public.schoolpro_payment_submissions for insert to authenticated with check (
 submitted_by=auth.uid() and exists(select 1 from public.schoolpro_guardian_links g where g.school_id=schoolpro_payment_submissions.school_id and g.guardian_user_id=auth.uid() and g.status='active'));
create policy finance_update_submissions on public.schoolpro_payment_submissions for update to authenticated using(private.schoolpro_module_allowed(school_id,'finance')) with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy finance_delete_submissions on public.schoolpro_payment_submissions for delete to authenticated using(private.schoolpro_module_allowed(school_id,'finance'));

create policy guardian_or_finance_read_allocations on public.schoolpro_payment_allocations for select to authenticated using (
 private.schoolpro_module_allowed(school_id,'finance') or exists(select 1 from public.schoolpro_payment_submissions s where s.id=submission_id and s.submitted_by=auth.uid()));
create policy finance_insert_allocations on public.schoolpro_payment_allocations for insert to authenticated with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy finance_update_allocations on public.schoolpro_payment_allocations for update to authenticated using(private.schoolpro_module_allowed(school_id,'finance')) with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy finance_delete_allocations on public.schoolpro_payment_allocations for delete to authenticated using(private.schoolpro_module_allowed(school_id,'finance'));

create policy guardian_or_finance_read_proofs on public.schoolpro_payment_proofs for select to authenticated using (
 private.schoolpro_module_allowed(school_id,'finance') or submitted_by=auth.uid());
create policy guardian_own_insert_proofs on public.schoolpro_payment_proofs for insert to authenticated with check (
 submitted_by=auth.uid() and exists(select 1 from public.schoolpro_guardian_links g where g.school_id=schoolpro_payment_proofs.school_id and g.student_id=schoolpro_payment_proofs.student_id and g.guardian_user_id=auth.uid() and g.status='active'));
create policy finance_update_proofs on public.schoolpro_payment_proofs for update to authenticated using(private.schoolpro_module_allowed(school_id,'finance')) with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy finance_delete_proofs on public.schoolpro_payment_proofs for delete to authenticated using(private.schoolpro_module_allowed(school_id,'finance'));

create policy guardian_finance_read_fee_payments on public.schoolpro_fee_payments for select to authenticated using (
 private.schoolpro_module_allowed(school_id,'finance') or exists(select 1 from public.schoolpro_guardian_links g where g.school_id=schoolpro_fee_payments.school_id and g.student_id=schoolpro_fee_payments.student_id and g.guardian_user_id=auth.uid() and g.status='active'));
create policy finance_insert_fee_payments on public.schoolpro_fee_payments for insert to authenticated with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy finance_update_fee_payments on public.schoolpro_fee_payments for update to authenticated using(private.schoolpro_module_allowed(school_id,'finance')) with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy finance_delete_fee_payments on public.schoolpro_fee_payments for delete to authenticated using(private.schoolpro_module_allowed(school_id,'finance'));

alter table public.schoolpro_payment_submissions enable row level security;
alter table public.schoolpro_payment_allocations enable row level security;
alter table public.schoolpro_payment_proofs enable row level security;
alter table public.schoolpro_fee_payments enable row level security;
grant select,insert,update,delete on public.schoolpro_payment_submissions, public.schoolpro_payment_allocations, public.schoolpro_payment_proofs, public.schoolpro_fee_payments to authenticated;

\ir ../supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql

create function pg_temp.assert_count(p_name text, p_actual bigint, p_expected bigint)
returns void language plpgsql as $$
begin if p_actual <> p_expected then raise exception 'FAIL: % expected %, got %',p_name,p_expected,p_actual; end if; end $$;
create function pg_temp.assert_no_rows_affected(p_name text, p_statement text)
returns void language plpgsql as $
declare affected bigint;
begin
 execute p_statement;
 get diagnostics affected = row_count;
 if affected > 0 then raise exception 'FAIL: unauthorized action changed % row(s): %',affected,p_name; end if;
exception when insufficient_privilege then
 return;
end $;

set role authenticated;
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',false);
select set_config('test.finance_school','',false);
select set_config('test.is_super_admin','false',false);
select pg_temp.assert_count('guardian sees own submission only',(select count(*) from public.schoolpro_payment_submissions),1);
select pg_temp.assert_count('guardian sees own allocation only',(select count(*) from public.schoolpro_payment_allocations),1);
select pg_temp.assert_count('guardian sees own proof only',(select count(*) from public.schoolpro_payment_proofs),1);
select pg_temp.assert_count('guardian sees linked fee payment only',(select count(*) from public.schoolpro_fee_payments),1);
select pg_temp.assert_no_rows_affected('guardian cannot update submission',$$update public.schoolpro_payment_submissions set total_amount=999 where id='e0000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('guardian cannot delete allocation',$$delete from public.schoolpro_payment_allocations where id='f0000000-0000-0000-0000-000000000001'$$);

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000099',false);
select set_config('test.finance_school','b0000000-0000-0000-0000-000000000001',false);
select pg_temp.assert_count('finance can review all school submissions',(select count(*) from public.schoolpro_payment_submissions),2);
update public.schoolpro_payment_submissions set status='reviewed' where id='e0000000-0000-0000-0000-000000000001';
update public.schoolpro_payment_allocations set amount=101 where id='f0000000-0000-0000-0000-000000000001';
update public.schoolpro_payment_proofs set receipt_path='reviewed/path.pdf' where id='11000000-0000-0000-0000-000000000001';
update public.schoolpro_fee_payments set amount=101 where id='12000000-0000-0000-0000-000000000001';

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000098',false);
select set_config('test.finance_school','',false);
select set_config('test.is_super_admin','true',false);
select pg_temp.assert_count('Super Admin reads all submissions',(select count(*) from public.schoolpro_payment_submissions),2);
select pg_temp.assert_count('Super Admin reads all allocations',(select count(*) from public.schoolpro_payment_allocations),2);
select pg_temp.assert_count('Super Admin reads all proofs',(select count(*) from public.schoolpro_payment_proofs),2);
select pg_temp.assert_count('Super Admin reads all fee payments',(select count(*) from public.schoolpro_fee_payments),2);
select pg_temp.assert_no_rows_affected('Super Admin cannot update submission',$$update public.schoolpro_payment_submissions set total_amount=888 where id='e0000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('Super Admin cannot delete fee payment',$$delete from public.schoolpro_fee_payments where id='12000000-0000-0000-0000-000000000001'$$);
reset role;
select 'PASS: payment-review RLS restricted guardian scope, allowed school-finance review, and kept Super Admin read-only.' as result;
