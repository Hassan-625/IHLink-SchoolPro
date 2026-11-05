-- Split anonymous and authenticated school registration policies.
-- Anonymous sign-up may submit a request before an authenticated session exists.
-- Keep the proprietor eligibility helper exclusive to authenticated submissions.

drop policy if exists "Users create onboarding requests" on public.schoolpro_onboarding_requests;
drop policy if exists "Anonymous school onboarding requests" on public.schoolpro_onboarding_requests;
drop policy if exists "Authenticated school onboarding requests" on public.schoolpro_onboarding_requests;

create policy "Anonymous school onboarding requests"
on public.schoolpro_onboarding_requests
for insert
to anon
with check (
  status = 'submitted'
  and user_id is null
  and school_id is null
  and reviewed_by is null
  and reviewed_at is null
  and review_notes is null
);

create policy "Authenticated school onboarding requests"
on public.schoolpro_onboarding_requests
for insert
to authenticated
with check (
  status = 'submitted'
  and user_id = auth.uid()
  and school_id is null
  and reviewed_by is null
  and reviewed_at is null
  and review_notes is null
  and private.schoolpro_can_register()
);
