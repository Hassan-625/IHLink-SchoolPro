-- Status only: device passcodes, encryption keys and biometrics stay on the device.
-- These preferences never authorize sign-in, purchases or school access.
create table public.app_device_security_preferences (
 user_id uuid not null references auth.users(id) on delete cascade,
 product text not null check (product in ('datasub','schoolpro')),
 device_id uuid not null,
 platform text not null check (platform in ('android','web','ios')),
 passcode_enabled boolean not null default false,
 biometric_enabled boolean not null default false,
 updated_at timestamptz not null default now(),
 primary key (user_id,product,device_id),
 check (not biometric_enabled or passcode_enabled)
);
alter table public.app_device_security_preferences enable row level security;
revoke all on public.app_device_security_preferences from public,anon,authenticated;
grant select,insert,update on public.app_device_security_preferences to authenticated;
grant all on public.app_device_security_preferences to service_role;
create policy device_security_read_own on public.app_device_security_preferences for select to authenticated using ((select auth.uid())=user_id);
create policy device_security_insert_own on public.app_device_security_preferences for insert to authenticated with check ((select auth.uid())=user_id);
create policy device_security_update_own on public.app_device_security_preferences for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
