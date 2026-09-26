create type public.schoolpro_invoice_status as enum ('unpaid','part_paid','paid','waived');

create table public.schoolpro_fee_structures (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  class_name text,
  term text not null,
  session text not null,
  amount numeric(14,2) not null check (amount >= 0),
  due_date date,
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id, name, class_name, term, session)
);

create table public.schoolpro_invoices (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  fee_structure_id uuid references public.schoolpro_fee_structures(id) on delete set null,
  title text not null check (char_length(title) between 2 and 160),
  term text not null,
  session text not null,
  amount_due numeric(14,2) not null check (amount_due >= 0),
  amount_paid numeric(14,2) not null default 0 check (amount_paid >= 0 and amount_paid <= amount_due),
  due_date date,
  status public.schoolpro_invoice_status not null default 'unpaid',
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, fee_structure_id)
);

create table public.schoolpro_fee_payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  invoice_id uuid not null references public.schoolpro_invoices(id) on delete restrict,
  student_id uuid not null references public.schoolpro_students(id) on delete restrict,
  amount numeric(14,2) not null check (amount > 0),
  method text not null check (method in ('cash','transfer','card','pos','cheque','other')),
  reference text not null,
  notes text,
  paid_at timestamptz not null default now(),
  recorded_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (school_id, reference)
);

create table public.schoolpro_finance_settings (
  school_id uuid primary key references public.schoolpro_schools(id) on delete cascade,
  block_results_when_owing boolean not null default false,
  allowed_outstanding numeric(14,2) not null default 0 check (allowed_outstanding >= 0),
  updated_by uuid not null references public.profiles(id) on delete restrict,
  updated_at timestamptz not null default now()
);

create index schoolpro_structures_school_idx on public.schoolpro_fee_structures (school_id, session, term);
create index schoolpro_invoices_school_idx on public.schoolpro_invoices (school_id, session, term, status);
create index schoolpro_invoices_student_idx on public.schoolpro_invoices (student_id, session, term);
create index schoolpro_payments_invoice_idx on public.schoolpro_fee_payments (invoice_id, paid_at desc);
create index schoolpro_payments_school_idx on public.schoolpro_fee_payments (school_id, paid_at desc);

alter table public.schoolpro_fee_structures enable row level security;
alter table public.schoolpro_invoices enable row level security;
alter table public.schoolpro_fee_payments enable row level security;
alter table public.schoolpro_finance_settings enable row level security;

create policy "School finance reads structures" on public.schoolpro_fee_structures for select to authenticated using (private.has_school_access(school_id));
create policy "School finance creates structures" on public.schoolpro_fee_structures for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[]) and created_by=(select auth.uid()));
create policy "School finance updates structures" on public.schoolpro_fee_structures for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[]));
create policy "School leaders delete structures" on public.schoolpro_fee_structures for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));

create policy "School finance reads invoices" on public.schoolpro_invoices for select to authenticated using (private.has_school_access(school_id));
create policy "School finance creates invoices" on public.schoolpro_invoices for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[]) and created_by=(select auth.uid()));
create policy "School finance updates invoices" on public.schoolpro_invoices for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[]));
create policy "School leaders delete invoices" on public.schoolpro_invoices for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));

create policy "School finance reads payments" on public.schoolpro_fee_payments for select to authenticated using (private.has_school_access(school_id));
create policy "School finance records payments" on public.schoolpro_fee_payments for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[]) and recorded_by=(select auth.uid()));

create policy "School users read finance settings" on public.schoolpro_finance_settings for select to authenticated using (private.has_school_access(school_id));
create policy "School leaders create finance settings" on public.schoolpro_finance_settings for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]) and updated_by=(select auth.uid()));
create policy "School leaders update finance settings" on public.schoolpro_finance_settings for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]) and updated_by=(select auth.uid()));

grant select,insert,update,delete on public.schoolpro_fee_structures, public.schoolpro_invoices to authenticated;
grant select,insert on public.schoolpro_fee_payments to authenticated;
grant select,insert,update on public.schoolpro_finance_settings to authenticated;

create or replace function public.record_schoolpro_payment(
  target_invoice uuid,
  payment_amount numeric,
  payment_method text,
  payment_reference text,
  payment_notes text default null
) returns uuid
language plpgsql
set search_path = ''
as $$
declare
  invoice_row public.schoolpro_invoices%rowtype;
  payment_id uuid;
  new_paid numeric;
begin
  select * into invoice_row from public.schoolpro_invoices where id=target_invoice for update;
  if invoice_row.id is null then raise exception 'Invoice not found'; end if;
  if not private.has_school_access(invoice_row.school_id,array['proprietor','administrator','accountant']::public.school_member_role[]) then raise exception 'Permission denied'; end if;
  if payment_amount <= 0 or invoice_row.amount_paid + payment_amount > invoice_row.amount_due then raise exception 'Payment exceeds the outstanding invoice balance'; end if;
  if payment_method not in ('cash','transfer','card','pos','cheque','other') then raise exception 'Unsupported payment method'; end if;
  insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by)
  values(invoice_row.school_id,invoice_row.id,invoice_row.student_id,payment_amount,payment_method,trim(payment_reference),payment_notes,(select auth.uid())) returning id into payment_id;
  new_paid := invoice_row.amount_paid + payment_amount;
  update public.schoolpro_invoices set amount_paid=new_paid,status=case when new_paid>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=invoice_row.id;
  return payment_id;
end;
$$;
revoke all on function public.record_schoolpro_payment(uuid,numeric,text,text,text) from public,anon;
grant execute on function public.record_schoolpro_payment(uuid,numeric,text,text,text) to authenticated;

create or replace function public.schoolpro_result_access(target_student uuid, target_term text, target_session text)
returns table(allowed boolean,outstanding numeric,reason text)
language sql stable
set search_path = ''
as $$
  select
    not coalesce(fs.block_results_when_owing,false) or coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0) <= coalesce(fs.allowed_outstanding,0),
    coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0),
    case when coalesce(fs.block_results_when_owing,false) and coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0) > coalesce(fs.allowed_outstanding,0) then 'Result access is paused because this student has an outstanding fee balance.' else null end
  from public.schoolpro_students s
  left join public.schoolpro_finance_settings fs on fs.school_id=s.school_id
  left join public.schoolpro_invoices i on i.student_id=s.id and i.term=target_term and i.session=target_session and i.status<>'waived'
  where s.id=target_student and private.has_school_access(s.school_id)
  group by fs.block_results_when_owing,fs.allowed_outstanding;
$$;
revoke all on function public.schoolpro_result_access(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_result_access(uuid,text,text) to authenticated;
