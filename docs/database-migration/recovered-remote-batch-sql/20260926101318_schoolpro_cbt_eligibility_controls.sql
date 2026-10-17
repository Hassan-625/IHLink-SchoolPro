create table if not exists public.schoolpro_cbt_eligibility (
 id uuid primary key default gen_random_uuid(),
 school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 test_id uuid not null references public.schoolpro_cbt_tests(id) on delete cascade,
 student_id uuid references public.schoolpro_students(id) on delete cascade,
 class_id uuid references public.schoolpro_classes(id) on delete cascade,
 eligible boolean not null default true,
 assigned_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 constraint cbt_eligibility_target check ((student_id is not null)::int + (class_id is not null)::int = 1)
);
create unique index if not exists schoolpro_cbt_eligibility_student_uq on public.schoolpro_cbt_eligibility(test_id,student_id) where student_id is not null;
create unique index if not exists schoolpro_cbt_eligibility_class_uq on public.schoolpro_cbt_eligibility(test_id,class_id) where class_id is not null;
alter table public.schoolpro_cbt_eligibility enable row level security;
create or replace function public.schoolpro_can_manage_cbt(p_school uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid()) or exists(select 1 from schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in ('proprietor','administrator','teacher','class_teacher','exam_officer','head_teacher','vice_principal','it_admin')); $$;
create or replace function public.schoolpro_cbt_is_eligible(p_test uuid,p_student uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(
  select 1 from schoolpro_cbt_tests t join schoolpro_students s on s.id=p_student and s.school_id=t.school_id
  where t.id=p_test and s.user_id=auth.uid() and (
   not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true)
   or exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true and (e.student_id=s.id or e.class_id=s.class_id))
  ) and not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.student_id=s.id and e.eligible=false)
 ); $$;
drop policy if exists "cbt eligibility managers" on public.schoolpro_cbt_eligibility;
create policy "cbt eligibility managers" on public.schoolpro_cbt_eligibility for all to authenticated using (public.schoolpro_can_manage_cbt(school_id)) with check (public.schoolpro_can_manage_cbt(school_id));
drop policy if exists "cbt eligibility students read own" on public.schoolpro_cbt_eligibility;
create policy "cbt eligibility students read own" on public.schoolpro_cbt_eligibility for select to authenticated using (student_id in (select id from public.schoolpro_students where user_id=auth.uid()) or class_id in (select class_id from public.schoolpro_students where user_id=auth.uid()));
revoke all on function public.schoolpro_can_manage_cbt(uuid) from anon;
revoke all on function public.schoolpro_cbt_is_eligible(uuid,uuid) from anon;
grant execute on function public.schoolpro_can_manage_cbt(uuid) to authenticated;
grant execute on function public.schoolpro_cbt_is_eligible(uuid,uuid) to authenticated;