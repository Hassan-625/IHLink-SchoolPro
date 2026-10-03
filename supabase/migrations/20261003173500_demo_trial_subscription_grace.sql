-- One demo per linked school; demo activation grants four months free access. Paid annual subscriptions suspend after a 14-day post-expiry grace period.
drop trigger if exists trg_schoolpro_demo_window on public.schoolpro_demo_requests;
drop function if exists private.validate_schoolpro_demo_window();
alter table public.schoolpro_demo_requests add column if not exists school_id uuid references public.schoolpro_schools(id) on delete set null;
alter table public.schoolpro_demo_requests add column if not exists activated_at timestamptz;
alter table public.schoolpro_demo_requests add column if not exists free_access_ends_at timestamptz;
create unique index if not exists schoolpro_demo_once_per_school on public.schoolpro_demo_requests(school_id) where school_id is not null;
-- Production also contains activate_schoolpro_demo(...) and private.enforce_schoolpro_subscription_expiry();
-- cron job schoolpro-expiry-grace-daily runs daily; trials stop at four months, paid active subscriptions suspend 14 days after renews_at.
