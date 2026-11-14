-- Prevent paid annual billing and settlement while a calendar-reviewed term Demo is active.
-- The term end / exam grace calculation remains owned by activate_schoolpro_demo.

create or replace function private.schoolpro_term_demo_is_active(p_school uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.schoolpro_demo_requests d
      join public.schoolpro_subscriptions s
        on s.school_id = d.school_id
     where d.school_id = p_school
       and d.status = 'completed'
       and d.activated_at is not null
       and d.free_access_ends_at > now()
       and s.status = 'active'
       and s.amount = 0
       and s.billing_cycle = 'termly'
       and s.renews_at > now()
  );
$$;

revoke all on function private.schoolpro_term_demo_is_active(uuid)
  from public, anon, authenticated;

create or replace function private.guard_schoolpro_term_demo_invoice()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.invoice_kind = 'subscription'
     and new.amount > 0 then
    if tg_op = 'INSERT'
       and new.status = 'pending'
       and private.schoolpro_term_demo_is_active(new.school_id) then
      raise exception 'Paid annual subscription invoicing is unavailable during an active term Demo';
    end if;

    if tg_op = 'UPDATE'
       and new.status = 'paid'
       and old.status is distinct from 'paid'
       and private.schoolpro_term_demo_is_active(new.school_id) then
      raise exception 'Finance settlement is unavailable during an active term Demo';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.guard_schoolpro_term_demo_invoice()
  from public, anon, authenticated;

drop trigger if exists trg_schoolpro_term_demo_invoice_guard
  on public.schoolpro_subscription_intents;
create trigger trg_schoolpro_term_demo_invoice_guard
before insert or update of status
on public.schoolpro_subscription_intents
for each row
execute function private.guard_schoolpro_term_demo_invoice();

create or replace function private.guard_schoolpro_term_demo_transfer_submission()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_school uuid;
begin
  if new.platform_code = 'schoolpro_subscription' then
    select i.school_id
      into v_school
      from public.schoolpro_subscription_intents i
     where i.id = new.invoice_id;

    if v_school is not null
       and private.schoolpro_term_demo_is_active(v_school) then
      raise exception 'A subscription receipt cannot be submitted during an active term Demo';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.guard_schoolpro_term_demo_transfer_submission()
  from public, anon, authenticated;

drop trigger if exists trg_schoolpro_term_demo_transfer_submission
  on public.direct_transfer_submissions;
create trigger trg_schoolpro_term_demo_transfer_submission
before insert
on public.direct_transfer_submissions
for each row
execute function private.guard_schoolpro_term_demo_transfer_submission();

-- Keep the existing bank-transfer RPC contract and role checks; add the Demo
-- gate before it returns an existing pending invoice or creates a new one.
create or replace function public.prepare_schoolpro_bank_subscription(
  p_school uuid,
  p_catalog uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s public.schoolpro_schools%rowtype;
  c public.schoolpro_subscription_catalog%rowtype;
  i public.schoolpro_subscription_intents%rowtype;
begin
  if auth.uid() is null
     or not coalesce(private.is_active_account(), false) then
    raise exception 'Active account required';
  end if;

  select *
    into s
    from public.schoolpro_schools
   where id = p_school
   for update;

  if s.id is null or s.status = 'suspended' then
    raise exception 'School unavailable';
  end if;

  if s.owner_id is distinct from auth.uid()
     and not exists (
       select 1
         from public.schoolpro_members
        where school_id = s.id
          and user_id = auth.uid()
          and role in ('proprietor', 'administrator', 'bursar')
     ) then
    raise exception 'School billing permission required';
  end if;

  if private.schoolpro_term_demo_is_active(s.id) then
    raise exception 'Paid annual subscription invoicing is unavailable until the active term Demo ends';
  end if;

  select *
    into c
    from public.schoolpro_subscription_catalog
   where id = p_catalog
     and active = true;

  if c.id is null
     or c.annual_price is null
     or c.annual_price <= 0
     or c.annual_price <> round(c.annual_price, 2) then
    raise exception 'Published annual plan price required';
  end if;

  if not exists (
    select 1
      from public.ihlink_bank_accounts
     where is_active
  ) then
    raise exception 'Company bank accounts unavailable';
  end if;

  select *
    into i
    from public.schoolpro_subscription_intents
   where school_id = s.id
     and status = 'pending'
   order by created_at
   limit 1
   for update;

  if i.id is not null then
    if i.payment_method <> 'bank_transfer'
       or i.payer_user_id is distinct from auth.uid()
       or i.catalog_id is distinct from c.id
       or i.amount is distinct from c.annual_price then
      raise exception 'Existing subscription instruction requires Finance review before changing plan or payer';
    end if;

    return to_jsonb(i);
  end if;

  insert into public.schoolpro_subscription_intents (
    school_id,
    payer_user_id,
    catalog_id,
    billing_cycle,
    amount,
    virtual_account_id,
    reference,
    status,
    payment_method
  )
  values (
    s.id,
    auth.uid(),
    c.id,
    'annual',
    c.annual_price,
    null,
    'SCHSUB-' || upper(replace(gen_random_uuid()::text, '-', '')),
    'pending',
    'bank_transfer'
  )
  returning * into i;

  return to_jsonb(i);
end;
$$;

comment on function private.schoolpro_term_demo_is_active(uuid) is
  'True only while a calendar-reviewed, activated, zero-value term Demo has unexpired access.';
comment on function public.prepare_schoolpro_bank_subscription(uuid,uuid) is
  'Prepares annual bank billing only when no active term-based SchoolPro Demo is in effect.';
