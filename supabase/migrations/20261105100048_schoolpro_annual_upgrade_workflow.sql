
-- ============================================================
-- SchoolPro annual subscription upgrades
-- Section 1: Immutable financial quote and request foundation
-- ============================================================

create table public.schoolpro_upgrade_requests (
  id uuid primary key default gen_random_uuid(),

  school_id uuid not null
    references public.schoolpro_schools(id) on delete cascade,

  requested_by uuid not null
    references auth.users(id) on delete restrict,

  source_subscription_id uuid
    references public.schoolpro_subscriptions(id) on delete restrict,

  target_catalog_id uuid not null
    references public.schoolpro_subscription_catalog(id) on delete restrict,

  -- Source subscription snapshot
  source_tier text not null,
  source_paid_amount numeric(14,2) not null,
  source_starts_at timestamptz not null,
  source_renews_at timestamptz not null,

  -- Target catalogue snapshot
  target_tier text not null,
  target_annual_price numeric(14,2) not null,

  -- Deterministic UTC quote calculation snapshot
  quote_calculated_at timestamptz not null,
  quote_total_seconds bigint not null,
  quote_unused_seconds bigint not null,
  credit_amount numeric(14,2) not null,
  outstanding_amount numeric(14,2) not null,

  status text not null default 'pending_review'
    check (status in (
      'pending_review',
      'approved',
      'paid',
      'rejected',
      'cancelled',
      'stale'
    )),

  version integer not null default 1
    check (version > 0),

  review_note text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint schoolpro_upgrade_source_term_valid
    check (source_starts_at < source_renews_at),

  constraint schoolpro_upgrade_source_amount_positive
    check (source_paid_amount > 0),

  constraint schoolpro_upgrade_target_price_positive
    check (target_annual_price > 0),

  constraint schoolpro_upgrade_term_seconds_valid
    check (
      quote_total_seconds > 0
      and quote_unused_seconds >= 0
      and quote_unused_seconds <= quote_total_seconds
    ),

  constraint schoolpro_upgrade_credit_valid
    check (
      credit_amount >= 0
      and credit_amount < target_annual_price
    ),

  constraint schoolpro_upgrade_outstanding_valid
    check (
      outstanding_amount > 0
      and outstanding_amount = target_annual_price - credit_amount
    )
);

comment on table public.schoolpro_upgrade_requests is
  'SchoolPro annual tier-upgrade requests with server-calculated, auditable financial snapshots.';

create index schoolpro_upgrade_requests_school_created_idx
  on public.schoolpro_upgrade_requests (school_id, created_at desc);

create index schoolpro_upgrade_requests_status_created_idx
  on public.schoolpro_upgrade_requests (status, created_at);

create unique index schoolpro_one_open_upgrade_per_school
  on public.schoolpro_upgrade_requests (school_id)
  where status in ('pending_review', 'approved');

alter table public.schoolpro_upgrade_requests enable row level security;


-- ============================================================
-- Section 2: Link upgrade requests to existing billing records
-- ============================================================

alter table public.schoolpro_subscription_intents
  add column upgrade_request_id uuid;

alter table public.schoolpro_subscription_intents
  add constraint schoolpro_subscription_intents_upgrade_request_fkey
  foreign key (upgrade_request_id)
  references public.schoolpro_upgrade_requests(id)
  on delete restrict;

create unique index schoolpro_upgrade_one_invoice_per_request
  on public.schoolpro_subscription_intents (upgrade_request_id)
  where upgrade_request_id is not null;

comment on column public.schoolpro_subscription_intents.upgrade_request_id is
  'Links a difference-only annual subscription invoice to its approved upgrade request.';

alter table public.schoolpro_subscription_payments
  add column upgrade_request_id uuid;

alter table public.schoolpro_subscription_payments
  add constraint schoolpro_subscription_payments_upgrade_request_fkey
  foreign key (upgrade_request_id)
  references public.schoolpro_upgrade_requests(id)
  on delete restrict;

create unique index schoolpro_upgrade_one_payment_per_request
  on public.schoolpro_subscription_payments (upgrade_request_id)
  where upgrade_request_id is not null;

comment on column public.schoolpro_subscription_payments.upgrade_request_id is
  'Links the credited bank-transfer payment to its annual subscription upgrade request.';


-- ============================================================
-- Section 3: Read access and immutable quote protection
-- ============================================================

create policy schoolpro_upgrade_requests_read
  on public.schoolpro_upgrade_requests
  for select
  to authenticated
  using (
    requested_by = (select auth.uid())
    or private.has_school_access(
      school_id,
      array['proprietor', 'administrator', 'bursar']::public.school_member_role[]
    )
    or (
      coalesce(private.is_active_account(), false)
      and coalesce(
        private.is_admin(array['super_admin', 'finance']::public.user_role[]),
        false
      )
    )
  );

revoke all on public.schoolpro_upgrade_requests from anon, authenticated;
grant select on public.schoolpro_upgrade_requests to authenticated;

create or replace function private.guard_schoolpro_upgrade_snapshot()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  if row(
    new.id,
    new.school_id,
    new.requested_by,
    new.source_subscription_id,
    new.target_catalog_id,
    new.source_tier,
    new.source_paid_amount,
    new.source_starts_at,
    new.source_renews_at,
    new.target_tier,
    new.target_annual_price,
    new.quote_calculated_at,
    new.quote_total_seconds,
    new.quote_unused_seconds,
    new.credit_amount,
    new.outstanding_amount,
    new.created_at
  ) is distinct from row(
    old.id,
    old.school_id,
    old.requested_by,
    old.source_subscription_id,
    old.target_catalog_id,
    old.source_tier,
    old.source_paid_amount,
    old.source_starts_at,
    old.source_renews_at,
    old.target_tier,
    old.target_annual_price,
    old.quote_calculated_at,
    old.quote_total_seconds,
    old.quote_unused_seconds,
    old.credit_amount,
    old.outstanding_amount,
    old.created_at
  ) then
    raise exception 'SchoolPro upgrade quote snapshots are immutable';
  end if;

  if new.version < old.version then
    raise exception 'Upgrade request version cannot decrease';
  end if;

  return new;
end;
$function$;

revoke all on function private.guard_schoolpro_upgrade_snapshot() from public;

create trigger schoolpro_upgrade_snapshot_immutable
  before update on public.schoolpro_upgrade_requests
  for each row
  execute function private.guard_schoolpro_upgrade_snapshot();

comment on function private.guard_schoolpro_upgrade_snapshot() is
  'Prevents mutation of SchoolPro upgrade financial snapshots after request creation.';


-- ============================================================
-- Section 4: Server-calculated annual upgrade requests
-- ============================================================

-- Preserve fractional seconds for deterministic UTC quote calculations.
alter table public.schoolpro_upgrade_requests
  alter column quote_total_seconds type numeric(20,6)
    using quote_total_seconds::numeric,
  alter column quote_unused_seconds type numeric(20,6)
    using quote_unused_seconds::numeric;

create or replace function public.request_schoolpro_upgrade(
  p_school_id uuid,
  p_target_catalog_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_school public.schoolpro_schools%rowtype;
  v_subscription public.schoolpro_subscriptions%rowtype;
  v_catalog public.schoolpro_subscription_catalog%rowtype;
  v_request public.schoolpro_upgrade_requests%rowtype;

  v_now timestamptz;
  v_total_seconds numeric(20,6);
  v_unused_seconds numeric(20,6);
  v_credit numeric(14,2);
  v_outstanding numeric(14,2);
  v_source_rank integer;
  v_target_rank integer;
begin
  if auth.uid() is null
     or not coalesce(private.is_active_account(), false) then
    raise exception 'An active signed-in account is required';
  end if;

  if not coalesce(
    private.has_school_access(
      p_school_id,
      array['proprietor', 'administrator', 'bursar']::public.school_member_role[]
    ),
    false
  ) then
    raise exception 'School billing permission required';
  end if;

  select *
    into v_school
    from public.schoolpro_schools
   where id = p_school_id
   for update;

  if v_school.id is null or v_school.status <> 'active' then
    raise exception 'Only an active school can request a subscription upgrade';
  end if;

  -- IHLINK Academy is intentionally restricted to Starter.
  if v_school.id = 'eb601205-cffd-420d-97d0-7d5ca081628a'::uuid then
    raise exception 'IHLINK Academy is restricted to the Starter plan';
  end if;

  select *
    into v_subscription
    from public.schoolpro_subscriptions
   where school_id = p_school_id
   for update;

  if v_subscription.id is null
     or v_subscription.status <> 'active'
     or v_subscription.billing_cycle <> 'annual'
     or v_subscription.amount is null
     or v_subscription.amount <= 0
     or v_subscription.starts_at is null
     or v_subscription.renews_at is null
     or v_subscription.starts_at >= v_subscription.renews_at then
    raise exception 'An active, unexpired paid annual subscription is required';
  end if;

  select *
    into v_catalog
    from public.schoolpro_subscription_catalog
   where id = p_target_catalog_id
     and active = true
   for share;

  if v_catalog.id is null then
    raise exception 'The selected subscription plan is unavailable';
  end if;

  -- Capture the quote instant only after all relevant rows are locked.
  v_now := clock_timestamp();

  if v_subscription.starts_at > v_now
     or v_subscription.renews_at <= v_now then
    raise exception 'An active, unexpired paid annual subscription is required';
  end if;

  v_source_rank := case v_subscription.tier
    when 'starter' then 1
    when 'professional' then 2
    when 'enterprise' then 3
    else null
  end;

  v_target_rank := case v_catalog.code
    when 'starter' then 1
    when 'professional' then 2
    when 'enterprise' then 3
    else null
  end;

  if v_source_rank is null or v_target_rank is null then
    raise exception 'Only Starter, Professional, and Enterprise tiers are supported';
  end if;

  if v_target_rank <= v_source_rank then
    raise exception 'The selected plan must be higher than the current plan';
  end if;

  if v_catalog.annual_price is null or v_catalog.annual_price <= 0 then
    raise exception 'The selected plan has no valid annual price';
  end if;

  if exists (
    select 1
      from public.schoolpro_subscription_intents i
     where i.school_id = p_school_id
       and i.status = 'pending'
  ) then
    raise exception 'Resolve the existing pending subscription invoice before requesting an upgrade';
  end if;

  if exists (
    select 1
      from public.schoolpro_upgrade_requests r
     where r.school_id = p_school_id
       and r.status in ('pending_review', 'approved')
  ) then
    raise exception 'This school already has an open upgrade request';
  end if;

  v_total_seconds :=
    extract(epoch from (v_subscription.renews_at - v_subscription.starts_at));

  v_unused_seconds := greatest(
    0::numeric,
    least(
      v_total_seconds,
      extract(epoch from (v_subscription.renews_at - v_now))
    )
  );

  if v_total_seconds <= 0 or v_unused_seconds <= 0 then
    raise exception 'The current subscription has no remaining paid term';
  end if;

  v_credit := round(
    v_subscription.amount * v_unused_seconds / v_total_seconds,
    2
  );

  if v_credit >= v_catalog.annual_price then
    raise exception 'The unused-term credit equals or exceeds the target price; contact IHLink for commercial review';
  end if;

  v_outstanding := v_catalog.annual_price - v_credit;

  insert into public.schoolpro_upgrade_requests (
    school_id,
    requested_by,
    source_subscription_id,
    target_catalog_id,
    source_tier,
    source_paid_amount,
    source_starts_at,
    source_renews_at,
    target_tier,
    target_annual_price,
    quote_calculated_at,
    quote_total_seconds,
    quote_unused_seconds,
    credit_amount,
    outstanding_amount
  )
  values (
    p_school_id,
    auth.uid(),
    v_subscription.id,
    v_catalog.id,
    v_subscription.tier,
    v_subscription.amount,
    v_subscription.starts_at,
    v_subscription.renews_at,
    v_catalog.code,
    v_catalog.annual_price,
    v_now,
    v_total_seconds,
    v_unused_seconds,
    v_credit,
    v_outstanding
  )
  returning * into v_request;

  return jsonb_build_object(
    'id', v_request.id,
    'school_id', v_request.school_id,
    'source_tier', v_request.source_tier,
    'target_tier', v_request.target_tier,
    'source_paid_amount', v_request.source_paid_amount,
    'target_annual_price', v_request.target_annual_price,
    'quote_calculated_at', v_request.quote_calculated_at,
    'quote_total_seconds', v_request.quote_total_seconds,
    'quote_unused_seconds', v_request.quote_unused_seconds,
    'credit_amount', v_request.credit_amount,
    'outstanding_amount', v_request.outstanding_amount,
    'status', v_request.status,
    'version', v_request.version
  );
end;
$function$;

revoke all on function public.request_schoolpro_upgrade(uuid, uuid)
  from public, anon;

grant execute on function public.request_schoolpro_upgrade(uuid, uuid)
  to authenticated;

comment on function public.request_schoolpro_upgrade(uuid, uuid) is
  'Creates a server-priced annual SchoolPro tier-upgrade request using the unused-term credit from the current paid subscription.';


-- ============================================================
-- Section 5: IHLink review, quote revalidation and invoice issue
-- ============================================================

create or replace function public.review_schoolpro_upgrade(
  p_request_id uuid,
  p_decision text,
  p_note text,
  p_expected_version integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_request public.schoolpro_upgrade_requests%rowtype;
  v_school public.schoolpro_schools%rowtype;
  v_subscription public.schoolpro_subscriptions%rowtype;
  v_catalog public.schoolpro_subscription_catalog%rowtype;
  v_invoice public.schoolpro_subscription_intents%rowtype;
  v_school_id uuid;
  v_reference text;
begin
  if auth.uid() is null
     or not coalesce(private.is_active_account(), false)
     or not coalesce(
       private.is_admin(
         array['super_admin', 'finance']::public.user_role[]
       ),
       false
     ) then
    raise exception 'Active IHLink Finance or Super Admin permission required';
  end if;

  if p_decision not in ('approved', 'rejected')
     or length(trim(coalesce(p_note, ''))) < 3
     or p_expected_version is null
     or p_expected_version < 1 then
    raise exception 'A valid decision, review note and request version are required';
  end if;

  -- Initial unlocked read obtains the school ID for consistent lock ordering.
  select school_id
    into v_school_id
    from public.schoolpro_upgrade_requests
   where id = p_request_id;

  if v_school_id is null then
    raise exception 'Upgrade request not found';
  end if;

  select *
    into v_school
    from public.schoolpro_schools
   where id = v_school_id
   for update;

  if v_school.id is null then
    raise exception 'School no longer exists';
  end if;

  if p_decision = 'approved' then
    select *
      into v_subscription
      from public.schoolpro_subscriptions
     where school_id = v_school_id
     for update;

    select c.*
      into v_catalog
      from public.schoolpro_subscription_catalog c
      join public.schoolpro_upgrade_requests r
        on r.target_catalog_id = c.id
     where r.id = p_request_id
     for share of c;
  end if;

  select *
    into v_request
    from public.schoolpro_upgrade_requests
   where id = p_request_id
   for update;

  if v_request.id is null then
    raise exception 'Upgrade request not found';
  end if;

  if v_request.school_id <> v_school_id then
    raise exception 'Upgrade request school changed unexpectedly';
  end if;

  if v_request.version <> p_expected_version then
    raise exception 'Upgrade request has changed; refresh before reviewing';
  end if;

  if v_request.status <> 'pending_review' then
    raise exception 'Only pending upgrade requests can be reviewed';
  end if;

  if p_decision = 'rejected' then
    update public.schoolpro_upgrade_requests
       set status = 'rejected',
           review_note = trim(p_note),
           reviewed_by = auth.uid(),
           reviewed_at = clock_timestamp(),
           version = version + 1,
           updated_at = clock_timestamp()
     where id = v_request.id
     returning * into v_request;

    return jsonb_build_object(
      'id', v_request.id,
      'status', v_request.status,
      'version', v_request.version
    );
  end if;

  -- A changed or unavailable source/target makes the quote stale.
  if v_school.status <> 'active'
     or v_school.id = 'eb601205-cffd-420d-97d0-7d5ca081628a'::uuid
     or v_subscription.id is null
     or v_subscription.id is distinct from v_request.source_subscription_id
     or v_subscription.status <> 'active'
     or v_subscription.billing_cycle <> 'annual'
     or v_subscription.tier is distinct from v_request.source_tier
     or v_subscription.amount is distinct from v_request.source_paid_amount
     or v_subscription.starts_at is distinct from v_request.source_starts_at
     or v_subscription.renews_at is distinct from v_request.source_renews_at
     or v_catalog.id is null
     or not v_catalog.active
     or v_catalog.code is distinct from v_request.target_tier
     or v_catalog.annual_price is distinct from v_request.target_annual_price
     or v_subscription.renews_at <= clock_timestamp() then

    update public.schoolpro_upgrade_requests
       set status = 'stale',
           review_note = 'The source subscription, school eligibility or target catalogue changed. Submit a new request.',
           reviewed_by = auth.uid(),
           reviewed_at = clock_timestamp(),
           version = version + 1,
           updated_at = clock_timestamp()
     where id = v_request.id
     returning * into v_request;

    return jsonb_build_object(
      'id', v_request.id,
      'status', v_request.status,
      'version', v_request.version,
      'message', 'Quote is stale; no invoice was created'
    );
  end if;

  if exists (
    select 1
      from public.schoolpro_subscription_intents i
     where i.school_id = v_school_id
       and i.status = 'pending'
  ) then
    raise exception 'Resolve the existing pending subscription invoice before approving this upgrade';
  end if;

  v_reference :=
    'SPU-' || replace(gen_random_uuid()::text, '-', '');

  insert into public.schoolpro_subscription_intents (
    school_id,
    payer_user_id,
    catalog_id,
    billing_cycle,
    amount,
    virtual_account_id,
    reference,
    status,
    payment_method,
    invoice_kind,
    upgrade_request_id
  )
  values (
    v_school_id,
    v_request.requested_by,
    v_request.target_catalog_id,
    'annual',
    v_request.outstanding_amount,
    null,
    v_reference,
    'pending',
    'bank_transfer',
    'subscription',
    v_request.id
  )
  returning * into v_invoice;

  update public.schoolpro_upgrade_requests
     set status = 'approved',
         review_note = trim(p_note),
         reviewed_by = auth.uid(),
         reviewed_at = clock_timestamp(),
         version = version + 1,
         updated_at = clock_timestamp()
   where id = v_request.id
   returning * into v_request;

  return jsonb_build_object(
    'id', v_request.id,
    'status', v_request.status,
    'version', v_request.version,
    'invoice_id', v_invoice.id,
    'invoice_reference', v_invoice.reference,
    'invoice_amount', v_invoice.amount,
    'billing_cycle', v_invoice.billing_cycle,
    'payment_method', v_invoice.payment_method
  );
end;
$function$;

revoke all on function public.review_schoolpro_upgrade(uuid, text, text, integer)
  from public, anon;

grant execute on function public.review_schoolpro_upgrade(uuid, text, text, integer)
  to authenticated;

comment on function public.review_schoolpro_upgrade(uuid, text, text, integer) is
  'Allows active IHLink Finance or Super Admin reviewers to reject an upgrade or approve it after revalidating its quote and issuing a difference-only bank-transfer invoice.';


-- ============================================================
-- Section 6: Controlled cancellation of upgrade requests
-- ============================================================

alter table public.schoolpro_upgrade_requests
  add column cancelled_by uuid references auth.users(id) on delete set null,
  add column cancelled_at timestamptz,
  add column cancellation_note text;

create or replace function public.cancel_schoolpro_upgrade(
  p_request_id uuid,
  p_note text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_school_id uuid;
  v_source_subscription_id uuid;
  v_request_status text;
  v_request public.schoolpro_upgrade_requests%rowtype;
  v_invoice public.schoolpro_subscription_intents%rowtype;
  v_is_billing_manager boolean;
  v_is_ihlink_reviewer boolean;
begin
  if auth.uid() is null
     or not coalesce(private.is_active_account(), false) then
    raise exception 'An active signed-in account is required';
  end if;

  if length(trim(coalesce(p_note, ''))) < 3 then
    raise exception 'A cancellation reason of at least three characters is required';
  end if;

  select school_id
    into v_school_id
    from public.schoolpro_upgrade_requests
   where id = p_request_id;

  if v_school_id is null then
    raise exception 'Upgrade request not found';
  end if;

  -- Match the school-first lock order used by request and review RPCs.
  perform 1
    from public.schoolpro_schools
   where id = v_school_id
   for update;

  if not found then
    raise exception 'School not found';
  end if;

  select status, source_subscription_id
    into v_request_status, v_source_subscription_id
    from public.schoolpro_upgrade_requests
   where id = p_request_id
     and school_id = v_school_id;

  if not found then
    raise exception 'Upgrade request not found';
  end if;

  -- Approved requests lock the source subscription before the request.
  if v_request_status = 'approved' then
    perform 1
      from public.schoolpro_subscriptions
     where id = v_source_subscription_id
       and school_id = v_school_id
     for update;

    if not found then
      raise exception 'Source subscription not found';
    end if;
  end if;

  select *
    into v_request
    from public.schoolpro_upgrade_requests
   where id = p_request_id
     and school_id = v_school_id
   for update;

  if v_request.id is null then
    raise exception 'Upgrade request not found';
  end if;

  v_is_billing_manager := coalesce(
    private.has_school_access(
      v_school_id,
      array['proprietor', 'administrator', 'bursar']::public.school_member_role[]
    ),
    false
  );

  v_is_ihlink_reviewer := coalesce(
    private.is_admin(
      array['super_admin', 'finance']::public.user_role[]
    ),
    false
  );

  if v_request.status = 'pending_review' and v_is_billing_manager then
    null;
  elsif v_request.status = 'approved' and v_is_ihlink_reviewer then
    select *
      into v_invoice
      from public.schoolpro_subscription_intents
     where upgrade_request_id = v_request.id
     for update;

    if v_invoice.id is null or v_invoice.status <> 'pending' then
      raise exception 'Only an approved upgrade with an unpaid pending invoice can be cancelled';
    end if;

    update public.schoolpro_subscription_intents
       set status = 'cancelled',
           updated_at = clock_timestamp()
     where id = v_invoice.id;
  else
    raise exception 'You are not permitted to cancel this upgrade request in its current state';
  end if;

  update public.schoolpro_upgrade_requests
     set status = 'cancelled',
         cancelled_by = auth.uid(),
         cancelled_at = clock_timestamp(),
         cancellation_note = trim(p_note),
         version = version + 1,
         updated_at = clock_timestamp()
   where id = v_request.id
   returning * into v_request;

  return jsonb_build_object(
    'id', v_request.id,
    'status', v_request.status,
    'version', v_request.version,
    'cancelled_at', v_request.cancelled_at,
    'invoice_id', v_invoice.id
  );
end;
$function$;

revoke all on function public.cancel_schoolpro_upgrade(uuid, text)
  from public, anon;

grant execute on function public.cancel_schoolpro_upgrade(uuid, text)
  to authenticated;

comment on function public.cancel_schoolpro_upgrade(uuid, text) is
  'Allows school billing managers to cancel pending requests and active IHLink Finance or Super Admin reviewers to cancel approved requests with unpaid invoices.';


-- ============================================================
-- Section 7: Finance verification and atomic upgrade settlement
-- ============================================================

create or replace function private.review_school_subscription_transfer(
  p_submission uuid,
  p_decision text,
  p_note text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  t public.direct_transfer_submissions%rowtype;
  i public.schoolpro_subscription_intents%rowtype;
  c public.schoolpro_subscription_catalog%rowtype;
  s public.schoolpro_subscriptions%rowtype;
  v_school public.schoolpro_schools%rowtype;
  v_upgrade public.schoolpro_upgrade_requests%rowtype;
  r timestamptz;
  receipt text;
  v_verified_at timestamptz;
begin
  if auth.uid() is null
     or not coalesce(private.is_active_account(), false)
     or not coalesce(
       private.is_admin(
         array['super_admin', 'finance']::public.user_role[]
       ),
       false
     ) then
    raise exception 'Company Finance approval permission required';
  end if;

  if p_decision is null
     or p_decision not in ('approved', 'rejected')
     or length(trim(coalesce(p_note, ''))) < 3 then
    raise exception 'Review decision and verification note required';
  end if;

  select *
    into t
    from public.direct_transfer_submissions
   where id = p_submission
     and platform_code = 'schoolpro_subscription'
   for update;

  if t.id is null then
    raise exception 'Subscription proof unavailable';
  end if;

  -- Read the invoice without locking it yet. Upgrade settlement must
  -- acquire shared records in school -> subscription -> catalogue ->
  -- request -> invoice order, matching the upgrade RPCs.
  select *
    into i
    from public.schoolpro_subscription_intents
   where id = t.invoice_id;

  if i.id is null then
    raise exception 'Subscription invoice unavailable';
  end if;

  if i.upgrade_request_id is not null then
    -- Lock the school first. Do not change its operational status here.
    select *
      into v_school
      from public.schoolpro_schools
     where id = i.school_id
     for update;

    if v_school.id is null then
      raise exception 'School unavailable';
    end if;

    select *
      into s
      from public.schoolpro_subscriptions
     where school_id = i.school_id
     for update;

    if s.id is null then
      raise exception 'Source subscription unavailable';
    end if;

    select *
      into c
      from public.schoolpro_subscription_catalog
     where id = i.catalog_id
     for share;

    if c.id is null then
      raise exception 'Target subscription plan unavailable';
    end if;

    select *
      into v_upgrade
      from public.schoolpro_upgrade_requests
     where id = i.upgrade_request_id
       and school_id = i.school_id
     for update;

    if v_upgrade.id is null then
      raise exception 'Linked upgrade request unavailable';
    end if;

    select *
      into i
      from public.schoolpro_subscription_intents
     where id = t.invoice_id
     for update;

    if i.id is null
       or i.upgrade_request_id is distinct from v_upgrade.id
       or i.school_id is distinct from v_upgrade.school_id
       or i.catalog_id is distinct from v_upgrade.target_catalog_id
       or i.payer_user_id is distinct from v_upgrade.requested_by
       or t.user_id is distinct from v_upgrade.requested_by
       or t.source_reference is distinct from i.reference
       or i.billing_cycle <> 'annual'
       or i.invoice_kind <> 'subscription'
       or i.payment_method <> 'bank_transfer'
       or i.virtual_account_id is not null
       or i.amount is distinct from v_upgrade.outstanding_amount
       or t.amount is distinct from i.amount then
      raise exception 'Upgrade transfer does not match its approved invoice and quote';
    end if;

    receipt := 'DIRECT-' || t.id::text;

    -- Idempotency is accepted only when every settlement record agrees.
    if t.status = 'approved' and p_decision = 'approved' then
      if v_upgrade.status = 'paid'
         and i.status = 'paid'
         and i.transaction_ref = receipt
         and exists (
           select 1
             from public.schoolpro_subscription_payments p
            where p.upgrade_request_id = v_upgrade.id
              and p.school_id = v_upgrade.school_id
              and p.subscription_id = s.id
              and p.payer_user_id = v_upgrade.requested_by
              and p.amount = v_upgrade.outstanding_amount
              and p.status = 'credited'
              and p.transaction_ref = receipt
              and p.reference = receipt
              and p.provider = 'bank_transfer'
              and p.verified_at is not null
              and p.credited_at is not null
              and p.provider_payload->>'source' =
                  'finance_verified_schoolpro_upgrade'
              and p.provider_payload->>'submission_id' = t.id::text
              and p.provider_payload->>'invoice_id' = i.id::text
              and p.provider_payload->>'upgrade_request_id' =
                  v_upgrade.id::text
              and p.provider_payload->>'target_tier' =
                  v_upgrade.target_tier
              and p.provider_payload->>'target_annual_price' =
                  v_upgrade.target_annual_price::text
         ) then
        return jsonb_build_object(
          'id', t.id,
          'status', t.status,
          'school_id', i.school_id,
          'upgrade_request_id', v_upgrade.id,
          'invoice_id', i.id,
          'already_settled', true
        );
      end if;

      raise exception 'Approved transfer has inconsistent upgrade settlement records';
    end if;

    if t.status = 'rejected' and p_decision = 'rejected' then
      if v_upgrade.status = 'approved' and i.status = 'pending' then
        return jsonb_build_object(
          'id', t.id,
          'status', t.status,
          'school_id', i.school_id,
          'upgrade_request_id', v_upgrade.id,
          'invoice_id', i.id,
          'already_reviewed', true
        );
      end if;

      raise exception 'Rejected transfer has inconsistent upgrade records';
    end if;

    if t.status not in ('pending', 'awaiting_verification') then
      raise exception 'Proof already reviewed';
    end if;

    if v_upgrade.status <> 'approved' or i.status <> 'pending' then
      raise exception 'Only an approved upgrade with a pending invoice can be settled';
    end if;

    if p_decision = 'approved' then
      if t.proof_storage_path is null
         or t.proof_storage_path not like t.user_id::text || '/%'
         or not exists (
           select 1
             from storage.objects
            where bucket_id = 'direct-transfer-proofs'
              and name = t.proof_storage_path
         ) then
        raise exception 'Saved customer receipt required';
      end if;

      perform 1
        from public.ihlink_bank_accounts
       where id = t.bank_account_id
         and is_active
       for update;

      if not found then
        raise exception 'An active receiving bank account is required';
      end if;

      if length(trim(coalesce(t.customer_reference, ''))) = 0 then
        raise exception 'A bank transfer reference is required';
      end if;

      -- Serialize upgrade reference checks across all receiving accounts.
      perform pg_advisory_xact_lock(
        hashtextextended(lower(trim(t.customer_reference)), 0)
      );

      if exists (
        select 1
          from public.direct_transfer_submissions d
         where d.id <> t.id
           and d.status in ('approved', 'verified')
           and lower(trim(d.customer_reference)) =
               lower(trim(t.customer_reference))
      ) then
        raise exception 'Bank reference already reconciled';
      end if;

      v_verified_at := clock_timestamp();

      if v_school.status <> 'active'
         or v_school.plan is distinct from v_upgrade.source_tier then
        raise exception 'School status or plan changed after upgrade approval; Finance must not settle this transfer';
      end if;

      if v_upgrade.source_subscription_id is distinct from s.id
         or s.status <> 'active'
         or s.billing_cycle <> 'annual'
         or s.tier is distinct from v_upgrade.source_tier
         or s.amount is distinct from v_upgrade.source_paid_amount
         or s.starts_at is distinct from v_upgrade.source_starts_at
         or s.renews_at is distinct from v_upgrade.source_renews_at
         or s.renews_at is null
         or s.renews_at <= v_verified_at then
        raise exception 'Source subscription changed or expired after upgrade approval; Finance must not settle this transfer';
      end if;

      if not c.active
         or c.code is distinct from v_upgrade.target_tier
         or c.annual_price is distinct from v_upgrade.target_annual_price then
        raise exception 'Target plan or annual price changed after upgrade approval; Finance must not settle this transfer';
      end if;

      if exists (
        select 1
          from public.schoolpro_subscription_payments p
         where p.upgrade_request_id = v_upgrade.id
      ) then
        raise exception 'An upgrade payment ledger entry already exists';
      end if;

      -- The new annual term begins at Finance verification, not approval
      -- or receipt upload. The recorded amount is the full target price.
      update public.schoolpro_subscriptions
         set tier = v_upgrade.target_tier,
             billing_cycle = 'annual',
             amount = v_upgrade.target_annual_price,
             status = 'active',
             starts_at = v_verified_at,
             renews_at = v_verified_at + interval '1 year',
             managed_by_ihlink = true,
             updated_at = v_verified_at
       where id = s.id
       returning * into s;

      -- Do not change school status: activation triggers must not run
      -- as a side effect of a paid tier upgrade.
      update public.schoolpro_schools
         set plan = v_upgrade.target_tier,
             updated_at = v_verified_at
       where id = v_upgrade.school_id;

      update public.schoolpro_subscription_intents
         set status = 'paid',
             transaction_ref = receipt,
             paid_at = v_verified_at,
             updated_at = v_verified_at
       where id = i.id
         and status = 'pending';

      if not found then
        raise exception 'Upgrade invoice could not be marked paid';
      end if;

      insert into public.schoolpro_subscription_payments (
        school_id,
        subscription_id,
        payer_user_id,
        provider,
        reference,
        amount,
        status,
        transaction_ref,
        provider_payload,
        verified_at,
        credited_at,
        upgrade_request_id
      )
      values (
        v_upgrade.school_id,
        s.id,
        v_upgrade.requested_by,
        'bank_transfer',
        receipt,
        v_upgrade.outstanding_amount,
        'credited',
        receipt,
        jsonb_build_object(
          'source', 'finance_verified_schoolpro_upgrade',
          'submission_id', t.id,
          'invoice_id', i.id,
          'upgrade_request_id', v_upgrade.id,
          'bank_account_id', t.bank_account_id,
          'bank_reference', t.customer_reference,
          'verified_by', auth.uid(),
          'source_tier', v_upgrade.source_tier,
          'target_tier', v_upgrade.target_tier,
          'credit_amount', v_upgrade.credit_amount,
          'target_annual_price', v_upgrade.target_annual_price
        ),
        v_verified_at,
        v_verified_at,
        v_upgrade.id
      );

      update public.schoolpro_upgrade_requests
         set status = 'paid',
             version = version + 1,
             updated_at = v_verified_at
       where id = v_upgrade.id
         and status = 'approved'
       returning * into v_upgrade;

      if v_upgrade.id is null or v_upgrade.status <> 'paid' then
        raise exception 'Upgrade request could not be marked paid';
      end if;

      update public.direct_transfer_submissions
         set status = 'approved',
             admin_note = trim(p_note),
             verified_by = auth.uid(),
             verified_at = v_verified_at,
             updated_at = v_verified_at
       where id = t.id
         and status in ('pending', 'awaiting_verification');

      if not found then
        raise exception 'Transfer submission has already been reviewed';
      end if;

      insert into public.audit_logs (
        actor_id,
        action,
        product,
        target_type,
        target_id,
        metadata
      )
      values (
        auth.uid(),
        'schoolpro_upgrade_transfer_approved',
        'schoolpro',
        'upgrade_request',
        v_upgrade.id::text,
        jsonb_build_object(
          'school_id', v_upgrade.school_id,
          'upgrade_request_id', v_upgrade.id,
          'invoice_id', i.id,
          'submission_id', t.id,
          'amount', t.amount,
          'source_tier', v_upgrade.source_tier,
          'target_tier', v_upgrade.target_tier,
          'credit_amount', v_upgrade.credit_amount,
          'target_annual_price', v_upgrade.target_annual_price,
          'bank_reference', t.customer_reference,
          'finance_note', trim(p_note)
        )
      );

      return jsonb_build_object(
        'id', t.id,
        'status', 'approved',
        'school_id', v_upgrade.school_id,
        'upgrade_request_id', v_upgrade.id,
        'invoice_id', i.id,
        'subscription_id', s.id,
        'verified_at', v_verified_at
      );
    end if;

    update public.direct_transfer_submissions
       set status = 'rejected',
           admin_note = trim(p_note),
           verified_by = auth.uid(),
           verified_at = clock_timestamp(),
           updated_at = clock_timestamp()
     where id = t.id
       and status in ('pending', 'awaiting_verification');

    if not found then
      raise exception 'Transfer submission has already been reviewed';
    end if;

    insert into public.audit_logs (
      actor_id,
      action,
      product,
      target_type,
      target_id,
      metadata
    )
    values (
      auth.uid(),
      'schoolpro_upgrade_transfer_rejected',
      'schoolpro',
      'upgrade_request',
      v_upgrade.id::text,
      jsonb_build_object(
        'school_id', v_upgrade.school_id,
        'upgrade_request_id', v_upgrade.id,
        'invoice_id', i.id,
        'submission_id', t.id,
        'amount', t.amount,
        'bank_reference', t.customer_reference,
        'finance_note', trim(p_note)
      )
    );

    return jsonb_build_object(
      'id', t.id,
      'status', 'rejected',
      'school_id', v_upgrade.school_id,
      'upgrade_request_id', v_upgrade.id,
      'invoice_id', i.id
    );
  end if;

  -- Existing ordinary annual subscription settlement path.
  if t.status = p_decision then
    return jsonb_build_object('id', t.id, 'status', t.status);
  end if;

  if t.status not in ('pending', 'awaiting_verification') then
    raise exception 'Proof already reviewed';
  end if;

  select *
    into i
    from public.schoolpro_subscription_intents
   where id = t.invoice_id
   for update;

  if i.id is null
     or i.status <> 'pending'
     or i.payment_method <> 'bank_transfer'
     or i.payer_user_id is distinct from t.user_id
     or i.amount is distinct from t.amount
     or i.billing_cycle <> 'annual'
     or i.upgrade_request_id is not null then
    raise exception 'Subscription proof does not match the pending instruction';
  end if;

  if p_decision = 'approved' then
    if t.proof_storage_path not like t.user_id::text || '/%'
       or not exists (
         select 1
           from storage.objects
          where bucket_id = 'direct-transfer-proofs'
            and name = t.proof_storage_path
       ) then
      raise exception 'Saved customer receipt required';
    end if;

    perform 1
      from public.ihlink_bank_accounts
     where id = t.bank_account_id
     for update;

    if not found then
      raise exception 'Receiving account unavailable';
    end if;

    if length(trim(coalesce(t.customer_reference, ''))) = 0 then
      raise exception 'A bank transfer reference is required';
    end if;

    -- Use the same global reference lock as upgrade settlement.
    perform pg_advisory_xact_lock(
      hashtextextended(lower(trim(t.customer_reference)), 0)
    );

    if exists (
      select 1
        from public.direct_transfer_submissions d
       where d.id <> t.id
         and d.status in ('approved', 'verified')
         and lower(trim(d.customer_reference)) =
             lower(trim(t.customer_reference))
    ) then
      raise exception 'Bank reference already reconciled';
    end if;

    perform 1
      from public.schoolpro_schools
     where id = i.school_id
       and status <> 'suspended'
     for update;

    if not found then
      raise exception 'School requires review before activation';
    end if;

    select *
      into c
      from public.schoolpro_subscription_catalog
     where id = i.catalog_id
       and active;

    if c.id is null then
      raise exception 'Subscription plan unavailable';
    end if;

    select *
      into s
      from public.schoolpro_subscriptions
     where school_id = i.school_id
     for update;

    r := case
      when s.status = 'active'
       and s.amount > 0
       and s.renews_at > now()
      then s.renews_at + interval '1 year'
      else now() + interval '1 year'
    end;

    insert into public.schoolpro_subscriptions (
      school_id,
      tier,
      billing_cycle,
      amount,
      status,
      starts_at,
      renews_at,
      managed_by_ihlink,
      updated_at
    )
    values (
      i.school_id,
      c.code,
      'annual',
      i.amount,
      'active',
      now(),
      r,
      true,
      now()
    )
    on conflict (school_id) do update
      set tier = excluded.tier,
          billing_cycle = 'annual',
          amount = excluded.amount,
          status = 'active',
          starts_at = coalesce(
            public.schoolpro_subscriptions.starts_at,
            now()
          ),
          renews_at = r,
          managed_by_ihlink = true,
          updated_at = now()
    returning * into s;

    update public.schoolpro_schools
       set status = 'active',
           plan = c.code,
           updated_at = now()
     where id = i.school_id;

    receipt := 'DIRECT-' || t.id::text;

    update public.schoolpro_subscription_intents
       set status = 'paid',
           transaction_ref = receipt,
           paid_at = now(),
           updated_at = now()
     where id = i.id;

    insert into public.schoolpro_subscription_payments (
      school_id,
      subscription_id,
      payer_user_id,
      provider,
      reference,
      amount,
      status,
      transaction_ref,
      provider_payload,
      verified_at,
      credited_at
    )
    values (
      i.school_id,
      s.id,
      i.payer_user_id,
      'bank_transfer',
      receipt,
      i.amount,
      'credited',
      receipt,
      jsonb_build_object(
        'submission_id', t.id,
        'bank_account_id', t.bank_account_id,
        'bank_reference', t.customer_reference,
        'verified_by', auth.uid()
      ),
      now(),
      now()
    );
  end if;

  update public.direct_transfer_submissions
     set status = p_decision,
         admin_note = trim(p_note),
         verified_by = auth.uid(),
         verified_at = now(),
         updated_at = now()
   where id = t.id;

  insert into public.audit_logs (
    actor_id,
    action,
    product,
    target_type,
    target_id,
    metadata
  )
  values (
    auth.uid(),
    'subscription_transfer_' || p_decision,
    'schoolpro',
    'direct_transfer',
    t.id::text,
    jsonb_build_object(
      'school_id', i.school_id,
      'intent_id', i.id,
      'amount', t.amount,
      'bank_reference', t.customer_reference,
      'finance_note', trim(p_note)
    )
  );

  return jsonb_build_object(
    'id', t.id,
    'status', p_decision,
    'school_id', i.school_id
  );
end;
$function$;

revoke all on function private.review_school_subscription_transfer(
  uuid, text, text
) from public, anon, authenticated;
