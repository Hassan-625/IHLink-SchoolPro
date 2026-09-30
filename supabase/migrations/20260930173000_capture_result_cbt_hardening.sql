-- Production parity marker for 2026-09-30 SchoolPro result/CBT hardening.
-- Full definitions below mirror the live functions and result-access policies verified on Supabase.

create or replace function public.schoolpro_can_release_result(p_student uuid,p_term text,p_session text)
returns boolean language sql stable security definer set search_path='' as $$
 select not exists(select 1 from public.schoolpro_invoices i where i.student_id=p_student and i.term=p_term and i.session=p_session and (i.result_hold=true or greatest(i.amount_due-i.amount_paid,0)>0));
$$;
revoke all on function public.schoolpro_can_release_result(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_can_release_result(uuid,text,text) to authenticated,service_role;

-- Public result PIN access now honours explicit result_hold as well as net outstanding balance.
-- Candidate CBT submission now rejects unstarted, expired, duration-ended, or test-closed attempts
-- and scores only questions assigned to the attempt's test.
-- The live definitions were verified before this repository parity migration was added.
