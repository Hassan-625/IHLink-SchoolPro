create table public.schoolpro_guardian_links (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  guardian_user_id uuid not null references public.profiles(id) on delete cascade,
  relationship text not null default 'guardian' check (relationship in ('mother','father','guardian','sponsor')),
  status text not null default 'active' check (status in ('active','suspended')),
  linked_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique(student_id,guardian_user_id)
);
create index schoolpro_guardian_user_idx on public.schoolpro_guardian_links(guardian_user_id,school_id) where status='active';
alter table public.schoolpro_guardian_links enable row level security;

create policy "Guardians read own links" on public.schoolpro_guardian_links for select to authenticated using (guardian_user_id=(select auth.uid()) or private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders create guardian links" on public.schoolpro_guardian_links for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]) and linked_by=(select auth.uid()));
create policy "School leaders update guardian links" on public.schoolpro_guardian_links for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders delete guardian links" on public.schoolpro_guardian_links for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
grant select,insert,update,delete on public.schoolpro_guardian_links to authenticated;

create policy "Guardians read linked schools" on public.schoolpro_schools for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.school_id=id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read linked students" on public.schoolpro_students for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.student_id=id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read linked invoices" on public.schoolpro_invoices for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.student_id=student_id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read linked payments" on public.schoolpro_fee_payments for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.student_id=student_id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read linked attendance" on public.schoolpro_attendance for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.student_id=student_id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read linked subjects" on public.schoolpro_subjects for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.school_id=school_id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read linked assessment schemes" on public.schoolpro_assessment_schemes for select to authenticated using (exists(select 1 from public.schoolpro_guardian_links g where g.school_id=school_id and g.guardian_user_id=(select auth.uid()) and g.status='active'));
create policy "Guardians read published linked results" on public.schoolpro_results for select to authenticated using (
  status='published' and exists(select 1 from public.schoolpro_guardian_links g where g.student_id=student_id and g.guardian_user_id=(select auth.uid()) and g.status='active')
  and (not coalesce((select f.block_results_when_owing from public.schoolpro_finance_settings f where f.school_id=school_id),false)
    or coalesce((select sum(greatest(i.amount_due-i.amount_paid,0)) from public.schoolpro_invoices i where i.student_id=student_id and i.term=term and i.session=session and i.status<>'waived'),0)
      <= coalesce((select f.allowed_outstanding from public.schoolpro_finance_settings f where f.school_id=school_id),0))
);

create or replace function public.link_schoolpro_guardian(target_student uuid,guardian_email text,guardian_relationship text default 'guardian')
returns uuid language plpgsql set search_path='' as $$
declare s public.schoolpro_students%rowtype; guardian uuid; link_id uuid;
begin
  select * into s from public.schoolpro_students where id=target_student;
  if s.id is null then raise exception 'Student not found'; end if;
  if not private.has_school_access(s.school_id,array['proprietor','administrator']::public.school_member_role[]) then raise exception 'Permission denied'; end if;
  select id into guardian from public.profiles where lower(email)=lower(trim(guardian_email)) and status='active';
  if guardian is null then raise exception 'The parent must first create an IHLink account with this email'; end if;
  if guardian_relationship not in ('mother','father','guardian','sponsor') then raise exception 'Invalid relationship'; end if;
  insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,relationship,linked_by)
  values(s.school_id,s.id,guardian,guardian_relationship,(select auth.uid()))
  on conflict(student_id,guardian_user_id) do update set relationship=excluded.relationship,status='active',linked_by=(select auth.uid())
  returning id into link_id;
  return link_id;
end $$;
revoke all on function public.link_schoolpro_guardian(uuid,text,text) from public,anon;
grant execute on function public.link_schoolpro_guardian(uuid,text,text) to authenticated;

create or replace function public.schoolpro_result_access(target_student uuid,target_term text,target_session text)
returns table(allowed boolean,outstanding numeric,reason text) language sql stable set search_path='' as $$
 select not coalesce(fs.block_results_when_owing,false) or coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)<=coalesce(fs.allowed_outstanding,0),coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0),case when coalesce(fs.block_results_when_owing,false) and coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)>coalesce(fs.allowed_outstanding,0) then 'Result access is paused because this student has an outstanding fee balance.' else null end
 from public.schoolpro_students s left join public.schoolpro_finance_settings fs on fs.school_id=s.school_id left join public.schoolpro_invoices i on i.student_id=s.id and i.term=target_term and i.session=target_session and i.status<>'waived'
 where s.id=target_student and (private.has_school_access(s.school_id) or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=s.id and g.guardian_user_id=(select auth.uid()) and g.status='active'))
 group by fs.block_results_when_owing,fs.allowed_outstanding;
$$;
