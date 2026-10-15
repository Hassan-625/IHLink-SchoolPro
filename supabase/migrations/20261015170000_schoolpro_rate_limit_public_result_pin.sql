begin;

-- Public result-PIN verification must go through the rate-limited Edge Function.
-- Deploy supabase/functions/schoolpro-result-pin-check before applying this migration,
-- then deploy the frontend update in the same release window.
revoke all on function public.check_schoolpro_result_pin(text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.check_schoolpro_result_pin(text, text, text, text)
  to service_role;

commit;
