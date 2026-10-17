-- Isolated disposable PostgreSQL test for effective payment-review RLS.
-- Uses a reduced schema but mirrors the current production policy names/predicates and broad grants;
-- it is not a full production schema restore. Applies the actual draft migration and switches roles.
create schema if not exists auth;
create schema if not exists private;
do $$ begin create role authenticated nologin; exception when duplicate_object then null; end $$;
do $$ begin create role anon nologin; exception when duplicate_object then null; end $$;
do $$ begin create role service_role nologin; exception when duplicate_object then null; end $$;
do $$ begin create type public.user_role as enum ('super_admin'); exception when duplicate_object then null; end $$;
do $$ begin create type public.school_member_role as enum ('proprietor','administrator','accountant','bursar'); exception when duplicate_object then null; end $$;
do $$ begin create type public.schoolpro_invoice_status as enum ('unpaid','part_paid','paid','waived'); exception when duplicate_object then null; end $$;

create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create or replace function private.is_admin(p_roles public.user_role[])
returns boolean language sql stable
as $$ select coalesce(current_setting('test.is_super_admin', true), 'false') = 'true' $$;
create table public.schoolpro_test_memberships (
 user_id uuid not null, school_id uuid not null, role public.school_member_role not null,
 primary key (user_id,school_id,role)
);
create or replace function private.has_school_access(p_school uuid, p_roles public.school_member_role[] default null)
returns boolean language sql stable security definer set search_path=''
as $$ select exists (
 select 1 from public.schoolpro_test_memberships m
 where m.user_id=(select auth.uid()) and m.school_id=p_school
 and (p_roles is null or m.role=any(p_roles))
) $$;
create or replace function private.schoolpro_module_allowed(p_school uuid, p_module text)
returns boolean language sql stable
as $$ select p_module = 'finance' and current_setting('test.finance_school', true) = p_school::text $$;

create table public.schoolpro_invoices (
 id uuid primary key, school_id uuid not null, student_id uuid not null,
 amount_due numeric not null, amount_paid numeric not null default 0,
 status public.schoolpro_invoice_status not null default 'unpaid', updated_at timestamptz not null default now()
);
create table public.schoolpro_guardian_links (
 id uuid primary key, school_id uuid not null, student_id uuid not null,
 guardian_user_id uuid not null, status text not null
);

create or replace function private.schoolpro_owns_invoice_student(p_school uuid,p_student uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.schoolpro_guardian_links g
 where g.school_id=p_school and g.student_id=p_student
 and g.guardian_user_id=(select auth.uid()) and g.status='active') $$;

create schema if not exists storage;
create table storage.objects (
 bucket_id text not null,
 name text not null,
 owner_id text,
 owner text
);
grant select on storage.objects to authenticated;
create table public.schoolpro_payment_submissions (
 id uuid primary key, school_id uuid not null, submitted_by uuid not null,
 bank_account_id uuid, total_amount numeric not null, payment_date date not null,
 payer_name text, bank_reference text, receipt_path text not null,
 receipt_mime text, status text not null default 'pending', review_note text,
 reviewed_by uuid, reviewed_at timestamptz, updated_at timestamptz not null default now()
);
create table public.schoolpro_payment_allocations (
 id uuid primary key, submission_id uuid not null, school_id uuid not null,
 student_id uuid not null, invoice_id uuid not null, amount numeric not null, payment_id uuid
);
create table public.schoolpro_payment_proofs (
 id uuid primary key, school_id uuid not null, student_id uuid not null,
 submitted_by uuid not null, receipt_path text
);
create table public.schoolpro_fee_payments (
 id uuid primary key default gen_random_uuid(), school_id uuid not null, student_id uuid not null,
 amount numeric not null, recorded_by uuid, invoice_id uuid, method text, reference text, notes text
);

-- Reproduce the broad legacy table grants observed on production so the migration
-- must prove it removes anonymous direct access while preserving authenticated tests.
grant all privileges on table
 public.schoolpro_invoices,
 public.schoolpro_payment_allocations,
 public.schoolpro_payment_proofs,
 public.schoolpro_payment_submissions,
 public.schoolpro_fee_payments
to anon, authenticated;

insert into public.schoolpro_guardian_links values
 ('a0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001','active'),
 ('a0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','active');
insert into public.schoolpro_invoices(id,school_id,student_id,amount_due,amount_paid,status) values
 ('90000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001',500,0,'unpaid'),
 ('90000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002',500,0,'unpaid');
insert into public.schoolpro_payment_submissions values
 ('e0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001',null,100,current_date,'Guardian A','REF-A','path/a.pdf','application/pdf','pending'),
 ('e0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000002',null,200,current_date,'Guardian B','REF-B','path/b.pdf','application/pdf','pending');
insert into public.schoolpro_payment_allocations values
 ('f0000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001',100),
 ('f0000000-0000-0000-0000-000000000002','e0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000002',200);
insert into public.schoolpro_payment_proofs values
 ('11000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001','path/a.pdf'),
 ('11000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','path/b.pdf');

insert into storage.objects(bucket_id,name,owner_id,owner) values
 ('schoolpro-payment-receipts','d0000000-0000-0000-0000-000000000001/receipt-a.pdf','d0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001'),
 ('schoolpro-payment-receipts','d0000000-0000-0000-0000-000000000002/receipt-b.pdf','d0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002');
insert into public.schoolpro_fee_payments(id,school_id,student_id,amount,recorded_by) values
 ('12000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001',100,'d0000000-0000-0000-0000-000000000099'),
 ('12000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002',200,'d0000000-0000-0000-0000-000000000099');
insert into public.schoolpro_test_memberships(user_id,school_id,role) values
 ('d0000000-0000-0000-0000-000000000099','b0000000-0000-0000-0000-000000000001','accountant');

-- Reproduce the names and core predicates of the live production permissive policies.
create policy "submitter or finance reads submissions" on public.schoolpro_payment_submissions for select to authenticated using (
 submitted_by=auth.uid() or private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]));
create policy "guardian inserts submissions" on public.schoolpro_payment_submissions for insert to authenticated with check (
 submitted_by=auth.uid() and exists(select 1 from public.schoolpro_guardian_links g where g.school_id=schoolpro_payment_submissions.school_id and g.guardian_user_id=auth.uid() and g.status='active'));

create policy "submitter or finance reads allocations" on public.schoolpro_payment_allocations for select to authenticated using (
 exists(select 1 from public.schoolpro_payment_submissions s where s.id=submission_id and
 (s.submitted_by=auth.uid() or private.has_school_access(s.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]))));

create policy "guardian reads own proofs" on public.schoolpro_payment_proofs for select to authenticated using (
 submitted_by=auth.uid() or private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]));
create policy "guardian submits proof" on public.schoolpro_payment_proofs for insert to authenticated with check (
 submitted_by=auth.uid() and exists(select 1 from public.schoolpro_guardian_links g where g.school_id=schoolpro_payment_proofs.school_id and g.student_id=schoolpro_payment_proofs.student_id and g.guardian_user_id=auth.uid() and g.status='active'));

create policy "School members guardians and corporate finance read payments" on public.schoolpro_fee_payments for select to authenticated using (
 private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])
 or private.schoolpro_owns_invoice_student(school_id,student_id));
create policy "School finance records payments" on public.schoolpro_fee_payments for insert to authenticated with check (
 private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])
 and recorded_by=auth.uid());
create policy "Super admin full access schoolpro_fee_payments" on public.schoolpro_fee_payments for all to authenticated using (
 private.is_admin(array['super_admin']::public.user_role[])) with check (
 private.is_admin(array['super_admin']::public.user_role[]));

alter table public.schoolpro_guardian_links enable row level security;
create policy guardian_reads_own_link on public.schoolpro_guardian_links for select to authenticated
using (guardian_user_id = auth.uid() or private.schoolpro_module_allowed(school_id,'finance'));
grant select on public.schoolpro_guardian_links to authenticated;

alter table public.schoolpro_payment_submissions enable row level security;
alter table public.schoolpro_payment_allocations enable row level security;
alter table public.schoolpro_payment_proofs enable row level security;
alter table public.schoolpro_fee_payments enable row level security;
grant select,insert,update,delete on public.schoolpro_payment_submissions, public.schoolpro_payment_allocations, public.schoolpro_payment_proofs, public.schoolpro_fee_payments to authenticated;

\ir ../supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql

-- Snapshot of the currently deployed review RPC for disposable behavioral testing.
-- This is intentionally test-only and must be refreshed when the deployed function changes.
create or replace function public.review_schoolpro_payment_submission(p_submission uuid,p_decision text,p_note text default null)
returns jsonb language plpgsql security definer set search_path=''
as $$ 
declare s public.schoolpro_payment_submissions%rowtype;
 a public.schoolpro_payment_allocations%rowtype;
 inv public.schoolpro_invoices%rowtype;
 pid uuid;
 np numeric;
begin
 if not private.schoolpro_module_allowed((select school_id from public.schoolpro_payment_submissions where id=p_submission),'finance') then
  raise exception 'Module permission denied: finance';
 end if;
 if p_decision not in('confirmed','rejected') then raise exception 'Invalid decision'; end if;
 select * into s from public.schoolpro_payment_submissions where id=p_submission for update;
 if s.id is null then raise exception 'Submission not found'; end if;
 if not private.has_school_access(s.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then
  raise exception 'Permission denied';
 end if;
 if s.status<>'pending' then raise exception 'Already reviewed'; end if;
 if p_decision='rejected' then
  update public.schoolpro_payment_submissions set status='rejected',review_note=p_note,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=s.id;
  return jsonb_build_object('status','rejected');
 end if;
 for a in select * from public.schoolpro_payment_allocations where submission_id=s.id for update loop
  select * into inv from public.schoolpro_invoices where id=a.invoice_id for update;
  if inv.id is null or inv.school_id<>s.school_id or inv.student_id<>a.student_id or inv.amount_paid+a.amount>inv.amount_due then
   raise exception 'Allocation no longer matches invoice balance';
  end if;
  insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by)
  values(s.school_id,inv.id,inv.student_id,a.amount,'transfer',coalesce(s.bank_reference,'SUB-'||s.id::text)||'-'||a.id::text,'Confirmed uploaded receipt: '||coalesce(p_note,''),auth.uid())
  returning id into pid;
  np:=inv.amount_paid+a.amount;
  update public.schoolpro_invoices set amount_paid=np,status=case when np>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=inv.id;
  update public.schoolpro_payment_allocations set payment_id=pid where id=a.id;
 end loop;
 update public.schoolpro_payment_submissions set status='confirmed',review_note=p_note,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=s.id;
 return jsonb_build_object('status','confirmed');
end $$;
revoke all on function public.review_schoolpro_payment_submission(uuid,text,text) from public,anon;
grant execute on function public.review_schoolpro_payment_submission(uuid,text,text) to authenticated,service_role;

create function public.test_fail_invoice_update_for_rollback()
returns trigger language plpgsql as $trigger$
begin
 if current_setting('test.force_invoice_failure',true)='true' and new.amount_paid>old.amount_paid then
  raise exception 'synthetic trigger failure for rollback assertion';
 end if;
 return new;
end $trigger$;
create trigger test_fail_invoice_update_for_rollback before update on public.schoolpro_invoices
for each row execute function public.test_fail_invoice_update_for_rollback();

create function pg_temp.assert_rpc_rejected(p_name text,p_statement text,p_expected text)
returns void language plpgsql as $assert$
declare actual_message text;
begin
 begin
  execute p_statement;
 exception when others then
  get stacked diagnostics actual_message=message_text;
  if position(p_expected in actual_message)>0 then return; end if;
  raise exception 'FAIL: % returned unexpected error: %',p_name,actual_message;
 end;
 raise exception 'FAIL: RPC rejection was not enforced: %',p_name;
end;
$assert$;

do $assert$
begin
  if has_table_privilege('anon','public.schoolpro_invoices','select')
    or has_table_privilege('anon','public.schoolpro_invoices','insert')
    or has_table_privilege('anon','public.schoolpro_payment_allocations','select')
    or has_table_privilege('anon','public.schoolpro_payment_allocations','insert')
    or has_table_privilege('anon','public.schoolpro_payment_proofs','select')
    or has_table_privilege('anon','public.schoolpro_payment_proofs','insert')
    or has_table_privilege('anon','public.schoolpro_payment_submissions','select')
    or has_table_privilege('anon','public.schoolpro_payment_submissions','insert')
    or has_table_privilege('anon','public.schoolpro_fee_payments','select')
    or has_table_privilege('anon','public.schoolpro_fee_payments','insert') then
    raise exception 'FAIL: anonymous direct privileges remain on SchoolPro financial tables';
  end if;
  if not has_table_privilege('authenticated','public.schoolpro_payment_submissions','select')
    or has_table_privilege('authenticated','public.schoolpro_payment_submissions','insert') then
    raise exception 'FAIL: submission read privilege should remain but direct insert must be revoked';
  end if;
end
$assert$;
select 'PASS: anonymous direct table grants revoked from SchoolPro financial tables.' as result;


create function pg_temp.assert_count(p_name text, p_actual bigint, p_expected bigint)
returns void language plpgsql as $$
begin if p_actual <> p_expected then raise exception 'FAIL: % expected %, got %',p_name,p_expected,p_actual; end if; end $$;
create function pg_temp.assert_no_rows_affected(p_name text, p_statement text)
returns void language plpgsql as $assert$
declare affected bigint;
begin
 execute p_statement;
 get diagnostics affected = row_count;
 if affected > 0 then raise exception 'FAIL: unauthorized action changed % row(s): %',affected,p_name; end if;
exception when insufficient_privilege then
 return;
end $assert$;

create function pg_temp.assert_rejected(p_name text, p_statement text)
returns void language plpgsql as $assert$
begin
  begin
    execute p_statement;
  exception when insufficient_privilege then
    return;
  end;
  raise exception 'FAIL: unauthorized action was accepted: %', p_name;
end $assert$;

set role authenticated;
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',false);select pg_temp.assert_rejected(
  'guardian cannot insert a pre-reviewed payment submission',
  $insert$ insert into public.schoolpro_payment_submissions
    (id, school_id, submitted_by, total_amount, payment_date, receipt_path, status)
    values
    ('e0000000-0000-0000-0000-000000000099',
     'b0000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     100, current_date, 'd0000000-0000-0000-0000-000000000001/not-a-verified-upload.pdf',
     'reviewed')$insert$
);

select pg_temp.assert_rejected(
  'guardian cannot bypass the receipt RPC with a pending fake-path submission',
  $insert$ insert into public.schoolpro_payment_submissions
    (id, school_id, submitted_by, total_amount, payment_date, receipt_path, status)
    values
    ('e0000000-0000-0000-0000-000000000098',
     'b0000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     100, current_date, 'd0000000-0000-0000-0000-000000000002/receipt-b.pdf',
     'pending')$insert$
);
select pg_temp.assert_rejected(
  'guardian cannot attach another account receipt to a legacy proof row',
  $insert$ insert into public.schoolpro_payment_proofs
    (id, school_id, student_id, submitted_by, receipt_path)
    values
    ('11000000-0000-0000-0000-000000000099',
     'b0000000-0000-0000-0000-000000000001',
     'c0000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000002/receipt-b.pdf')$insert$
);

select set_config('test.finance_school','',false);
select set_config('test.is_super_admin','false',false);
select pg_temp.assert_count('guardian sees own submission only',(select count(*) from public.schoolpro_payment_submissions),1);
select pg_temp.assert_count('guardian sees own allocation only',(select count(*) from public.schoolpro_payment_allocations),1);
select pg_temp.assert_count('guardian sees own proof only',(select count(*) from public.schoolpro_payment_proofs),1);
select pg_temp.assert_count('guardian sees linked fee payment only',(select count(*) from public.schoolpro_fee_payments),1);
select pg_temp.assert_no_rows_affected('guardian cannot update submission',$$update public.schoolpro_payment_submissions set total_amount=999 where id='e0000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('guardian cannot delete allocation',$$delete from public.schoolpro_payment_allocations where id='f0000000-0000-0000-0000-000000000001'$$);

insert into public.schoolpro_payment_proofs
  (id,school_id,student_id,submitted_by,receipt_path)
values
  ('11000000-0000-0000-0000-000000000099',
   'b0000000-0000-0000-0000-000000000001',
   'c0000000-0000-0000-0000-000000000001',
   'd0000000-0000-0000-0000-000000000001',
   'd0000000-0000-0000-0000-000000000001/receipt-a.pdf');
select pg_temp.assert_count('guardian can submit own uploaded receipt proof',
  (select count(*) from public.schoolpro_payment_proofs where id='11000000-0000-0000-0000-000000000099'),1);
reset role;
delete from public.schoolpro_payment_proofs where id='11000000-0000-0000-0000-000000000099';
set role authenticated;
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',false);

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000099',false);
select set_config('test.finance_school','b0000000-0000-0000-0000-000000000001',false);
select pg_temp.assert_count('finance can read all school submissions',(select count(*) from public.schoolpro_payment_submissions),2);
select pg_temp.assert_no_rows_affected('finance cannot directly change submission review status',$$update public.schoolpro_payment_submissions set status='reviewed' where id='e0000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('finance cannot directly alter invoice allocation amount',$$update public.schoolpro_payment_allocations set amount=101 where id='f0000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('finance cannot directly replace proof receipt path',$$update public.schoolpro_payment_proofs set receipt_path='reviewed/path.pdf' where id='11000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('finance cannot directly edit fee-payment ledger amount',$$update public.schoolpro_fee_payments set amount=101 where id='12000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('finance cannot delete fee-payment ledger row',$$delete from public.schoolpro_fee_payments where id='12000000-0000-0000-0000-000000000001'$$);
insert into public.schoolpro_fee_payments(id,school_id,student_id,amount,recorded_by)
values('12000000-0000-0000-0000-000000000099','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001',50,'d0000000-0000-0000-0000-000000000099');
select pg_temp.assert_count('finance can insert an intended school fee payment',(select count(*) from public.schoolpro_fee_payments where id='12000000-0000-0000-0000-000000000099'),1);

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',false);
select set_config('test.finance_school','',false);
select pg_temp.assert_rpc_rejected(
 'guardian cannot review a payment submission',
 $$select public.review_schoolpro_payment_submission('e0000000-0000-0000-0000-000000000002','rejected','unauthorized')$$,
 'Module permission denied');
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000099',false);
select set_config('test.finance_school','b0000000-0000-0000-0000-000000000001',false);
select pg_temp.assert_rpc_rejected(
 'review RPC does not treat cancellation as an accepted decision',
 $$select public.review_schoolpro_payment_submission('e0000000-0000-0000-0000-000000000002','cancelled','cancel request')$$,
 'Invalid decision');
select set_config('test.force_invoice_failure','true',false);
select pg_temp.assert_rpc_rejected(
 'invoice trigger failure rolls back earlier fee-payment insert',
 $$select public.review_schoolpro_payment_submission('e0000000-0000-0000-0000-000000000001','confirmed','force rollback')$$,
 'synthetic trigger failure for rollback assertion');
select set_config('test.force_invoice_failure','false',false);
select pg_temp.assert_count('failed confirmation leaves submission pending',
 (select count(*) from public.schoolpro_payment_submissions where id='e0000000-0000-0000-0000-000000000001' and status='pending'),1);
select pg_temp.assert_count('failed confirmation rolls invoice amount back',
 (select count(*) from public.schoolpro_invoices where id='90000000-0000-0000-0000-000000000001' and amount_paid=0 and status='unpaid'),1);
select pg_temp.assert_count('failed confirmation rolls allocation link back',
 (select count(*) from public.schoolpro_payment_allocations where id='f0000000-0000-0000-0000-000000000001' and payment_id is null),1);
select pg_temp.assert_count('failed confirmation rolls fee payment insert back',
 (select count(*) from public.schoolpro_fee_payments),3);
select public.review_schoolpro_payment_submission('e0000000-0000-0000-0000-000000000002','rejected','synthetic rejection');
select pg_temp.assert_count('authorized rejection transitions pending to rejected',
 (select count(*) from public.schoolpro_payment_submissions where id='e0000000-0000-0000-0000-000000000002' and status='rejected' and review_note='synthetic rejection'),1);
select public.review_schoolpro_payment_submission('e0000000-0000-0000-0000-000000000001','confirmed','synthetic confirmation');
select pg_temp.assert_count('authorized confirmation transitions pending to confirmed',
 (select count(*) from public.schoolpro_payment_submissions where id='e0000000-0000-0000-0000-000000000001' and status='confirmed'),1);
select pg_temp.assert_count('confirmed payment updates invoice atomically',
 (select count(*) from public.schoolpro_invoices where id='90000000-0000-0000-0000-000000000001' and amount_paid=100 and status='part_paid'),1);
select pg_temp.assert_count('confirmed payment links allocation to ledger entry',
 (select count(*) from public.schoolpro_payment_allocations where id='f0000000-0000-0000-0000-000000000001' and payment_id is not null),1);
select pg_temp.assert_rpc_rejected(
 'duplicate review cannot re-confirm an already confirmed submission',
 $$select public.review_schoolpro_payment_submission('e0000000-0000-0000-0000-000000000001','confirmed','duplicate')$$,
 'Already reviewed');

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000098',false);
select set_config('test.finance_school','',false);
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000098',false);
select set_config('test.finance_school','',false);
select set_config('test.is_super_admin','true',false);
select pg_temp.assert_count('Super Admin reads all submissions',(select count(*) from public.schoolpro_payment_submissions),2);
select pg_temp.assert_count('Super Admin reads all allocations',(select count(*) from public.schoolpro_payment_allocations),2);
select pg_temp.assert_count('Super Admin reads all proofs',(select count(*) from public.schoolpro_payment_proofs),2);
select pg_temp.assert_count('Super Admin reads all fee payments',(select count(*) from public.schoolpro_fee_payments),4);
select pg_temp.assert_no_rows_affected('Super Admin cannot update submission',$$update public.schoolpro_payment_submissions set total_amount=888 where id='e0000000-0000-0000-0000-000000000001'$$);
select pg_temp.assert_no_rows_affected('Super Admin cannot delete fee payment',$$delete from public.schoolpro_fee_payments where id='12000000-0000-0000-0000-000000000001'$$);
reset role;
-- Seed a third pending submission for a real two-connection review race in the CI workflow.
insert into public.schoolpro_invoices(id,school_id,student_id,amount_due,amount_paid,status)
values ('90000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001',500,0,'unpaid');
insert into public.schoolpro_payment_submissions(id,school_id,submitted_by,total_amount,payment_date,payer_name,bank_reference,receipt_path,receipt_mime,status)
values ('e0000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001',100,current_date,'Guardian A','REF-RACE','d0000000-0000-0000-0000-000000000001/race.pdf','application/pdf','pending');
insert into public.schoolpro_payment_allocations(id,submission_id,school_id,student_id,invoice_id,amount)
values ('f0000000-0000-0000-0000-000000000003','e0000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000003',100);
create function public.test_delay_review_commit()
returns trigger language plpgsql as $race$
begin
 if new.id='e0000000-0000-0000-0000-000000000003' and new.status='confirmed' and old.status is distinct from new.status then
   perform pg_sleep(2);
 end if;
 return new;
end
$race$;
create trigger test_delay_review_commit before update on public.schoolpro_payment_submissions
for each row execute function public.test_delay_review_commit();
select 'PASS: payment-review RLS behavior and concurrency fixture prepared.' as result;
