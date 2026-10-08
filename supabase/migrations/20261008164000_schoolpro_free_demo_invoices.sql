alter table public.schoolpro_subscription_intents add column invoice_kind text not null default 'subscription', add column demo_request_id uuid unique references public.schoolpro_demo_requests(id);
alter table public.schoolpro_subscription_intents drop constraint schoolpro_subscription_intents_amount_check, drop constraint schoolpro_subscription_intents_status_check;
alter table public.schoolpro_subscription_intents add constraint schoolpro_subscription_invoice_kind check(invoice_kind in ('subscription','demo')),
add constraint schoolpro_subscription_invoice_amount check((invoice_kind='subscription' and amount>0 and demo_request_id is null and status in ('pending','paid','cancelled','reconciliation_required')) or (invoice_kind='demo' and amount=0 and demo_request_id is not null and status='free' and paid_at is null and transaction_ref is null and virtual_account_id is null)),
add constraint schoolpro_subscription_invoice_status check(status in ('pending','paid','cancelled','reconciliation_required','free'));
create or replace function private.create_schoolpro_demo_invoice(p_demo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare d public.schoolpro_demo_requests; catalog uuid; owner uuid;
begin
 select * into d from public.schoolpro_demo_requests where id=p_demo;
 if d.school_id is null or d.user_id is null or d.status='cancelled' then return; end if;
 select s.owner_id,c.id into owner,catalog from public.schoolpro_schools s
 join public.schoolpro_onboarding_requests r on r.school_id=s.id and r.user_id=s.owner_id and r.status in ('approved','provisioning','active')
 join public.schoolpro_subscription_catalog c on c.code=coalesce(r.plan_key,'starter') and c.active
 where s.id=d.school_id and s.owner_id=d.user_id order by r.created_at desc limit 1;
 if catalog is null or owner is null then return; end if;
 insert into public.schoolpro_subscription_intents(school_id,payer_user_id,catalog_id,billing_cycle,amount,reference,status,payment_method,invoice_kind,demo_request_id)
 values(d.school_id,owner,catalog,'annual',0,'SP-DEMO-'||upper(replace(d.id::text,'-','')),'free','bank_transfer','demo',d.id)
 on conflict(demo_request_id) do nothing;
end $$;
revoke all on function private.create_schoolpro_demo_invoice(uuid) from public,anon,authenticated;
create or replace function private.sync_schoolpro_demo_invoice()
returns trigger language plpgsql security definer set search_path='' as $$
begin perform private.create_schoolpro_demo_invoice(new.id); return new; end $$;
revoke all on function private.sync_schoolpro_demo_invoice() from public,anon,authenticated;
create trigger schoolpro_demo_invoice after insert or update of school_id,status on public.schoolpro_demo_requests for each row execute function private.sync_schoolpro_demo_invoice();
create or replace function private.sync_schoolpro_onboarding_demo_invoice()
returns trigger language plpgsql security definer set search_path='' as $$
declare demo uuid;
begin
 for demo in select id from public.schoolpro_demo_requests where school_id=new.school_id and user_id=new.user_id loop perform private.create_schoolpro_demo_invoice(demo); end loop;
 return new;
end $$;
revoke all on function private.sync_schoolpro_onboarding_demo_invoice() from public,anon,authenticated;
create trigger schoolpro_onboarding_demo_invoice after update of school_id,status,plan_key on public.schoolpro_onboarding_requests for each row execute function private.sync_schoolpro_onboarding_demo_invoice();
-- Existing approved workspace demos receive their missing free document, without a payment entry.
select private.create_schoolpro_demo_invoice(id) from public.schoolpro_demo_requests where school_id is not null;
