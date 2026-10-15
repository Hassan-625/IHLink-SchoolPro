-- SchoolPro annual Demo + annual paid subscriptions, with a reviewed annual-plan upgrade workflow.
-- This migration is committed for branch/CI review only; do not apply to production without approval.

-- Keep selected commercial tier independent from the active service entitlement.
-- Demo is a one-year free entitlement; paid plans renew annually and receive 14 days' grace.
create or replace function private.enforce_schoolpro_subscription_expiry()
returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 update public.schoolpro_subscriptions
 set status='suspended',updated_at=now()
 where (status='trial' and renews_at is not null and renews_at<=now())
    or (status='active' and renews_at is not null
        and renews_at + case when amount>0 and billing_cycle='annual' then interval '14 days' else interval '0 days' end <= now());
 get diagnostics n=row_count;
 return n;
end $$;

create table if not exists public.schoolpro_upgrade_requests(
 id uuid primary key default gen_random_uuid(),
 school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 requested_by uuid not null references auth.users(id),
 current_subscription_id uuid not null references public.schoolpro_subscriptions(id),
 from_plan text not null,
 to_catalog_id uuid not null references public.schoolpro_subscription_catalog(id),
 from_annual_price numeric(12,2) not null check(from_annual_price>=0),
 target_annual_price numeric(12,2) not null check(target_annual_price>0),
 balance_due numeric(12,2) not null check(balance_due>0),
 status text not null default 'pending' check(status in('pending','approved','rejected','invoiced','paid','cancelled')),
 invoice_id uuid,
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 review_reason text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists schoolpro_upgrade_requests_status_created_idx
 on public.schoolpro_upgrade_requests(status,created_at desc);
alter table public.schoolpro_upgrade_requests enable row level security;
grant select on public.schoolpro_upgrade_requests to authenticated;
drop policy if exists schoolpro_upgrade_request_read_scoped on public.schoolpro_upgrade_requests;
create policy schoolpro_upgrade_request_read_scoped on public.schoolpro_upgrade_requests
 for select to authenticated using(
  coalesce(private.has_product_access('schoolpro','approve'),false)
  or private.has_school_access(school_id,array['proprietor','administrator','bursar']::public.school_member_role[])
 );
revoke insert,update,delete on public.schoolpro_upgrade_requests from anon,authenticated;

alter table public.schoolpro_subscription_intents
 add column if not exists upgrade_request_id uuid unique references public.schoolpro_upgrade_requests(id);
alter table public.schoolpro_subscription_intents drop constraint if exists schoolpro_subscription_invoice_kind;
alter table public.schoolpro_subscription_intents drop constraint if exists schoolpro_subscription_invoice_amount;
alter table public.schoolpro_subscription_intents add constraint schoolpro_subscription_invoice_kind
 check(invoice_kind in ('subscription','demo','upgrade'));
alter table public.schoolpro_subscription_intents add constraint schoolpro_subscription_invoice_amount check(
 (invoice_kind='subscription' and amount>0 and demo_request_id is null and upgrade_request_id is null
  and status in('pending','paid','cancelled','reconciliation_required'))
 or
 (invoice_kind='demo' and amount=0 and demo_request_id is not null and upgrade_request_id is null
  and status='free' and paid_at is null and transaction_ref is null and virtual_account_id is null)
 or
 (invoice_kind='upgrade' and amount>0 and demo_request_id is null and upgrade_request_id is not null
  and status in('pending','paid','cancelled','reconciliation_required'))
);

create or replace function public.request_schoolpro_plan_upgrade(p_school uuid,p_catalog uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.schoolpro_subscriptions%rowtype; c public.schoolpro_subscription_catalog%rowtype;
 current_plan public.schoolpro_subscription_catalog%rowtype; r public.schoolpro_upgrade_requests%rowtype; owner_id uuid; balance numeric;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Active account required'; end if;
 select owner_id into owner_id from public.schoolpro_schools where id=p_school;
 if owner_id is null or (owner_id is distinct from auth.uid() and not private.has_school_access(p_school,array['proprietor']::public.school_member_role[])) then
  raise exception 'Only the school proprietor can request an upgrade';
 end if;
 if exists(select 1 from public.schoolpro_demo_requests d where d.school_id=p_school and d.activated_at is not null and d.free_access_ends_at>now()) then
  raise exception 'Demo is active; plan upgrades become payable after Demo expires';
 end if;
 select * into s from public.schoolpro_subscriptions where school_id=p_school for update;
 if s.id is null or s.status<>'active' or s.amount<=0 or s.billing_cycle<>'annual' or s.renews_at<=now() then
  raise exception 'An active paid annual subscription is required for an upgrade';
 end if;
 select * into c from public.schoolpro_subscription_catalog where id=p_catalog and active=true;
 if c.id is null or c.annual_price is null or c.annual_price<=0 then raise exception 'Published annual plan required'; end if;
 select * into current_plan from public.schoolpro_subscription_catalog where code=s.tier and active=true;
 if current_plan.id is null then raise exception 'Current annual plan price is unavailable; contact IHLink Finance'; end if;
 if c.annual_price<=current_plan.annual_price then raise exception 'Choose a higher-priced annual plan; downgrades are handled at renewal';
 end if;
 if exists(select 1 from public.schoolpro_upgrade_requests where school_id=p_school and status in('pending','approved','invoiced')) then
  raise exception 'An upgrade request is already in progress';
 end if;
 balance:=round(c.annual_price-current_plan.annual_price,2);
 insert into public.schoolpro_upgrade_requests(school_id,requested_by,current_subscription_id,from_plan,to_catalog_id,from_annual_price,target_annual_price,balance_due)
 values(p_school,auth.uid(),s.id,s.tier,c.id,current_plan.annual_price,c.annual_price,balance) returning * into r;
 return to_jsonb(r);
end $$;
revoke all on function public.request_schoolpro_plan_upgrade(uuid,uuid) from public,anon;
grant execute on function public.request_schoolpro_plan_upgrade(uuid,uuid) to authenticated;

create or replace function public.review_schoolpro_plan_upgrade(p_request uuid,p_decision text,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.schoolpro_upgrade_requests%rowtype; c public.schoolpro_subscription_catalog%rowtype;
 i public.schoolpro_subscription_intents%rowtype; sid uuid;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false)
  or not coalesce(private.has_product_access('schoolpro','approve'),false) then
  raise exception 'SchoolPro Super Admin approval permission required';
 end if;
 if p_decision not in('approve','reject') or length(trim(coalesce(p_reason,'')))<3 then raise exception 'Choose approve or reject and provide a reason'; end if;
 select * into r from public.schoolpro_upgrade_requests where id=p_request for update;
 if r.id is null then raise exception 'Upgrade request not found'; end if;
 if r.status not in('pending','approved') then raise exception 'Upgrade request has already been resolved'; end if;
 if p_decision='reject' then
  if r.status<>'pending' then raise exception 'An invoiced upgrade cannot be rejected here; resolve its invoice first'; end if;
  update public.schoolpro_upgrade_requests set status='rejected',reviewed_by=auth.uid(),reviewed_at=now(),review_reason=trim(p_reason),updated_at=now() where id=r.id;
  insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
   values(auth.uid(),'schoolpro_upgrade_rejected','schoolpro','schoolpro_upgrade_request',r.id::text,jsonb_build_object('school_id',r.school_id,'reason',trim(p_reason)));
  return jsonb_build_object('id',r.id,'status','rejected');
 end if;
 if r.status='approved' and r.invoice_id is not null then return jsonb_build_object('id',r.id,'invoice_id',r.invoice_id,'reused',true); end if;
 perform 1 from public.schoolpro_schools where id=r.school_id and status<>'suspended' for update;
 if not found then raise exception 'School is unavailable or suspended'; end if;
 select * into c from public.schoolpro_subscription_catalog where id=r.to_catalog_id and active=true;
 if c.id is null or c.annual_price<>r.target_annual_price then raise exception 'Target plan price changed; request a fresh upgrade quote'; end if;
 if exists(select 1 from public.schoolpro_subscription_intents where school_id=r.school_id and status='pending') then
  raise exception 'Resolve the existing subscription invoice before issuing the upgrade invoice';
 end if;
 sid:=gen_random_uuid();
 insert into public.schoolpro_subscription_intents(id,school_id,payer_user_id,catalog_id,billing_cycle,amount,reference,status,payment_method,invoice_kind,upgrade_request_id)
 values(sid,r.school_id,r.requested_by,r.to_catalog_id,'annual',r.balance_due,'SCHUPG-'||upper(replace(sid::text,'-','')),'pending','bank_transfer','upgrade',r.id)
 returning * into i;
 update public.schoolpro_upgrade_requests set status='invoiced',invoice_id=i.id,reviewed_by=auth.uid(),reviewed_at=now(),review_reason=trim(p_reason),updated_at=now() where id=r.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
  values(auth.uid(),'schoolpro_upgrade_invoice_issued','schoolpro','schoolpro_upgrade_request',r.id::text,jsonb_build_object('school_id',r.school_id,'invoice_id',i.id,'amount',r.balance_due,'target_plan',c.code,'reason',trim(p_reason)));
 return jsonb_build_object('id',r.id,'invoice_id',i.id,'amount',r.balance_due,'status','invoiced');
end $$;
revoke all on function public.review_schoolpro_plan_upgrade(uuid,text,text) from public,anon;
grant execute on function public.review_schoolpro_plan_upgrade(uuid,text,text) to authenticated;

-- Annual Demo starts when the Super Admin approves it, not at the submitted school-term date.
create or replace function public.activate_schoolpro_demo(p_school uuid,p_tier text,p_days integer,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.schoolpro_demo_requests%rowtype; finish timestamptz; result jsonb;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false)
  or not coalesce(private.has_product_access('schoolpro','approve'),false) then raise exception 'Authorized school administrator required'; end if;
 if length(trim(coalesce(p_reason,'')))<3 then raise exception 'Calendar review reason required'; end if;
 perform 1 from public.schoolpro_schools where id=p_school for update;
 if not found then raise exception 'School unavailable'; end if;
 if exists(select 1 from public.schoolpro_demo_requests where school_id=p_school and activated_at is not null) then raise exception 'This school has already used its demo'; end if;
 if exists(select 1 from public.schoolpro_subscriptions where school_id=p_school and status='active' and amount>0 and renews_at>now()) then raise exception 'Paid subscription cannot be replaced by a demo'; end if;
 select * into d from public.schoolpro_demo_requests where school_id=p_school and status='new' order by created_at desc limit 1 for update;
 if d.id is null or d.term_start is null or d.term_end is null or d.exam_start is null or d.exam_end is null
  or d.term_end<(d.term_start+interval '3 months')::date or d.exam_start<d.term_start or d.exam_end<d.exam_start or d.exam_end>d.term_end
  or d.calendar_path is null or d.letter_path is null then raise exception 'A complete term calendar and request letter are required'; end if;
 if not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=d.calendar_path and split_part(name,'/',1)=d.user_id::text)
  or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=d.letter_path and split_part(name,'/',1)=d.user_id::text) then raise exception 'Review documents unavailable'; end if;
 finish:=now()+interval '1 year';
 result:=public.control_center_activate_schoolpro(p_school,p_tier,p_reason);
 update public.schoolpro_subscriptions set amount=0,billing_cycle='annual',starts_at=now(),renews_at=finish,updated_at=now() where school_id=p_school;
 update public.schoolpro_onboarding_requests set status='active',updated_at=now() where school_id=p_school;
 update public.schoolpro_demo_requests set status='completed',activated_at=now(),free_access_ends_at=finish,reviewed_by=auth.uid(),reviewed_at=now(),review_reason=trim(p_reason),updated_at=now() where id=d.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'schoolpro_annual_demo_approved','schoolpro','schoolpro_school',p_school::text,jsonb_build_object('demo_request_id',d.id,'access_ends_at',finish,'payment_recorded',false));
 return result||jsonb_build_object('source','annual_demo','renews_at',finish);
end $$;

-- Do not create or expose a payable subscription instruction while the annual Demo is active.
create or replace function public.prepare_schoolpro_bank_subscription(p_school uuid,p_catalog uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.schoolpro_schools%rowtype;c public.schoolpro_subscription_catalog%rowtype;i public.schoolpro_subscription_intents%rowtype;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Active account required'; end if;
 select * into s from public.schoolpro_schools where id=p_school for update;
 if s.id is null or s.status='suspended' then raise exception 'School unavailable'; end if;
 if s.owner_id is distinct from auth.uid() and not exists(select 1 from public.schoolpro_members where school_id=s.id and user_id=auth.uid() and role in('proprietor','administrator','bursar')) then raise exception 'School billing permission required'; end if;
 if exists(select 1 from public.schoolpro_demo_requests where school_id=s.id and activated_at is not null and free_access_ends_at>now()) then
  raise exception 'Demo access is active. Paid subscription invoices become available after Demo expires.';
 end if;
 select * into c from public.schoolpro_subscription_catalog where id=p_catalog and active=true;
 if c.id is null or c.annual_price is null or c.annual_price<=0 or c.annual_price<>round(c.annual_price,2) then raise exception 'Published annual plan price required'; end if;
 if not exists(select 1 from public.ihlink_bank_accounts where is_active) then raise exception 'Company bank accounts unavailable'; end if;
 select * into i from public.schoolpro_subscription_intents where school_id=s.id and status='pending' and invoice_kind in('subscription','upgrade') order by created_at limit 1 for update;
 if i.id is not null then
  if i.payment_method<>'bank_transfer' or i.payer_user_id is distinct from auth.uid() or i.catalog_id is distinct from c.id or i.amount is distinct from c.annual_price or i.invoice_kind<>'subscription' then
   raise exception 'Existing subscription instruction requires Finance review before changing plan or payer';
  end if;
  return to_jsonb(i);
 end if;
 insert into public.schoolpro_subscription_intents(school_id,payer_user_id,catalog_id,billing_cycle,amount,virtual_account_id,reference,status,payment_method)
 values(s.id,auth.uid(),c.id,'annual',c.annual_price,null,'SCHSUB-'||upper(replace(gen_random_uuid()::text,'-','')),'pending','bank_transfer') returning * into i;
 return to_jsonb(i);
end $$;
revoke all on function public.prepare_schoolpro_bank_subscription(uuid,uuid) from public,anon;
grant execute on function public.prepare_schoolpro_bank_subscription(uuid,uuid) to authenticated;

-- Finance approval for an upgrade invoices only the price difference and preserves the original annual renewal date.
create or replace function private.review_school_subscription_transfer(p_submission uuid,p_decision text,p_note text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare t public.direct_transfer_submissions%rowtype;i public.schoolpro_subscription_intents%rowtype;c public.schoolpro_subscription_catalog%rowtype;
 s public.schoolpro_subscriptions%rowtype;r timestamptz;receipt text;u public.schoolpro_upgrade_requests%rowtype;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) or not coalesce(private.is_admin(array['super_admin','finance']::public.user_role[]),false) then raise exception 'Company Finance approval permission required'; end if;
 if p_decision not in('approved','rejected') or length(trim(coalesce(p_note,'')))<3 then raise exception 'Review decision and verification note required'; end if;
 select * into t from public.direct_transfer_submissions where id=p_submission and platform_code='schoolpro_subscription' for update;
 if t.id is null then raise exception 'Subscription proof unavailable'; end if;
 if t.status=p_decision then return jsonb_build_object('id',t.id,'status',t.status); end if;
 if t.status not in('pending','awaiting_verification') then raise exception 'Proof already reviewed'; end if;
 select * into i from public.schoolpro_subscription_intents where id=t.invoice_id for update;
 if i.id is null or i.status<>'pending' or i.payment_method<>'bank_transfer' or i.payer_user_id is distinct from t.user_id or i.amount is distinct from t.amount or i.billing_cycle<>'annual' then raise exception 'Subscription proof does not match the pending instruction'; end if;
 if p_decision='approved' then
  if t.proof_storage_path not like t.user_id::text||'/%' or not exists(select 1 from storage.objects where bucket_id='direct-transfer-proofs' and name=t.proof_storage_path) then raise exception 'Saved customer receipt required'; end if;
  perform 1 from public.ihlink_bank_accounts where id=t.bank_account_id for update;
  if not found then raise exception 'Receiving account unavailable'; end if;
  if exists(select 1 from public.direct_transfer_submissions where id<>t.id and status in('approved','verified') and bank_account_id=t.bank_account_id and lower(trim(customer_reference))=lower(trim(t.customer_reference))) then raise exception 'Bank reference already reconciled'; end if;
  perform 1 from public.schoolpro_schools where id=i.school_id and status<>'suspended' for update;
  if not found then raise exception 'School requires review before activation'; end if;
  select * into c from public.schoolpro_subscription_catalog where id=i.catalog_id and active;
  if c.id is null then raise exception 'Subscription plan unavailable'; end if;
  select * into s from public.schoolpro_subscriptions where school_id=i.school_id for update;
  if i.invoice_kind='upgrade' then
   select * into u from public.schoolpro_upgrade_requests where id=i.upgrade_request_id and status='invoiced' for update;
   if u.id is null or u.balance_due<>i.amount or u.to_catalog_id<>c.id then raise exception 'Upgrade invoice does not match an approved request'; end if;
   if s.id is null or s.id<>u.current_subscription_id or s.status<>'active' or s.renews_at<=now() then raise exception 'Current annual subscription changed or expired; review upgrade manually'; end if;
   r:=s.renews_at;
   update public.schoolpro_subscriptions set tier=c.code,billing_cycle='annual',amount=c.annual_price,status='active',renews_at=r,updated_at=now() where id=s.id returning * into s;
   update public.schoolpro_schools set status='active',plan=c.code,updated_at=now() where id=i.school_id;
   update public.schoolpro_upgrade_requests set status='paid',updated_at=now() where id=u.id;
  else
   r:=case when s.status='active' and s.amount>0 and s.renews_at>now() then s.renews_at+interval '1 year' else now()+interval '1 year' end;
   insert into public.schoolpro_subscriptions(school_id,tier,billing_cycle,amount,status,starts_at,renews_at,managed_by_ihlink,updated_at)
   values(i.school_id,c.code,'annual',i.amount,'active',now(),r,true,now())
   on conflict(school_id) do update set tier=excluded.tier,billing_cycle='annual',amount=excluded.amount,status='active',starts_at=case when public.schoolpro_subscriptions.amount>0 and public.schoolpro_subscriptions.status='active' then public.schoolpro_subscriptions.starts_at else now() end,renews_at=r,managed_by_ihlink=true,updated_at=now()
   returning * into s;
   update public.schoolpro_schools set status='active',plan=c.code,updated_at=now() where id=i.school_id;
  end if;
  receipt:='DIRECT-'||t.id::text;
  update public.schoolpro_subscription_intents set status='paid',transaction_ref=receipt,paid_at=now(),updated_at=now() where id=i.id;
  insert into public.schoolpro_subscription_payments(school_id,subscription_id,payer_user_id,provider,reference,amount,status,transaction_ref,provider_payload,verified_at,credited_at)
  values(i.school_id,s.id,i.payer_user_id,'bank_transfer',receipt,i.amount,'credited',receipt,jsonb_build_object('submission_id',t.id,'bank_account_id',t.bank_account_id,'bank_reference',t.customer_reference,'verified_by',auth.uid(),'invoice_kind',i.invoice_kind),now(),now());
 end if;
 update public.direct_transfer_submissions set status=p_decision,admin_note=trim(p_note),verified_by=auth.uid(),verified_at=now(),updated_at=now() where id=t.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'subscription_transfer_'||p_decision,'schoolpro','direct_transfer',t.id::text,jsonb_build_object('school_id',i.school_id,'intent_id',i.id,'amount',t.amount,'invoice_kind',i.invoice_kind,'bank_reference',t.customer_reference,'finance_note',trim(p_note)));
 return jsonb_build_object('id',t.id,'status',p_decision,'school_id',i.school_id);
end $$;
revoke all on function private.review_school_subscription_transfer(uuid,text,text) from public,anon,authenticated;
