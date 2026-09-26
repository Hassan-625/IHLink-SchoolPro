create table public.schoolpro_payment_intents (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  invoice_id uuid not null references public.schoolpro_invoices(id) on delete restrict,
  student_id uuid not null references public.schoolpro_students(id) on delete restrict,
  payer_user_id uuid not null references public.profiles(id) on delete restrict,
  gateway text not null default 'flutterwave' check(gateway='flutterwave'),
  reference text not null unique,
  amount numeric(14,2) not null check(amount>=100),
  currency text not null default 'NGN' check(currency='NGN'),
  status text not null default 'pending' check(status in ('pending','successful','failed','cancelled')),
  checkout_url text,
  gateway_transaction_id text,
  gateway_payload jsonb not null default '{}'::jsonb,
  credited_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index schoolpro_payment_intents_invoice_idx on public.schoolpro_payment_intents(invoice_id,created_at desc);
create index schoolpro_payment_intents_school_idx on public.schoolpro_payment_intents(school_id,status,created_at desc);
alter table public.schoolpro_payment_intents enable row level security;
create policy "Payers and school finance read fee intents" on public.schoolpro_payment_intents for select to authenticated using(payer_user_id=(select auth.uid()) or private.has_school_access(school_id,array['proprietor','administrator','accountant']::public.school_member_role[]));
grant select on public.schoolpro_payment_intents to authenticated;

create or replace function public.finalize_schoolpro_payment(p_reference text,p_gateway_transaction_id text,p_verified_amount numeric,p_status text,p_payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare intent public.schoolpro_payment_intents%rowtype; invoice public.schoolpro_invoices%rowtype; new_paid numeric; receipt_id uuid;
begin
 select * into intent from public.schoolpro_payment_intents where reference=trim(p_reference) for update;
 if intent.id is null then raise exception 'Payment intent not found'; end if;
 if intent.status='successful' then return jsonb_build_object('status','already_credited','reference',intent.reference); end if;
 if intent.status<>'pending' then return jsonb_build_object('status','already_finalized','reference',intent.reference); end if;
 if p_status='successful' then
  if p_verified_amount<>intent.amount then raise exception 'Verified amount does not match payment intent'; end if;
  select * into invoice from public.schoolpro_invoices where id=intent.invoice_id for update;
  if invoice.id is null or invoice.status in ('paid','waived') then raise exception 'Invoice is no longer payable'; end if;
  if invoice.amount_paid+intent.amount>invoice.amount_due then raise exception 'Payment exceeds outstanding invoice balance'; end if;
  insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by)
  values(intent.school_id,intent.invoice_id,intent.student_id,intent.amount,'card',intent.reference,'Verified Flutterwave online payment',intent.payer_user_id) returning id into receipt_id;
  new_paid:=invoice.amount_paid+intent.amount;
  update public.schoolpro_invoices set amount_paid=new_paid,status=case when new_paid>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=invoice.id;
  update public.schoolpro_payment_intents set status='successful',gateway_transaction_id=p_gateway_transaction_id,gateway_payload=coalesce(p_payload,'{}'::jsonb),credited_at=now(),updated_at=now() where id=intent.id;
 else
  update public.schoolpro_payment_intents set status='failed',gateway_transaction_id=p_gateway_transaction_id,gateway_payload=coalesce(p_payload,'{}'::jsonb),updated_at=now() where id=intent.id;
 end if;
 return jsonb_build_object('status',case when p_status='successful' then 'credited' else 'failed' end,'reference',intent.reference,'receipt_id',receipt_id,'amount',intent.amount);
end $$;
revoke all on function public.finalize_schoolpro_payment(text,text,numeric,text,jsonb) from public,anon,authenticated;
grant execute on function public.finalize_schoolpro_payment(text,text,numeric,text,jsonb) to service_role;
