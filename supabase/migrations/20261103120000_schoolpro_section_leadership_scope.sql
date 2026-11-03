-- Assign head teachers and vice principals to explicit school sections.
-- Section values deliberately match schoolpro_classes.level.
create table public.schoolpro_section_leaders (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  member_id uuid not null references public.schoolpro_members(id) on delete cascade,
  section text not null check (section in ('nursery','primary','junior_secondary','senior_secondary','other')),
  assigned_by uuid not null references auth.users(id),
  assigned_at timestamptz not null default now(),
  unique (school_id, member_id, section)
);
create index schoolpro_section_leaders_lookup_idx
  on public.schoolpro_section_leaders (school_id, section, member_id);
alter table public.schoolpro_section_leaders enable row level security;
alter table public.schoolpro_section_leaders force row level security;
revoke all on public.schoolpro_section_leaders from anon, authenticated;
grant select on public.schoolpro_section_leaders to authenticated;
create policy "School leaders and assigned staff read section leadership"
on public.schoolpro_section_leaders for select to authenticated
using (
  private.is_active_account()
  and private.schoolpro_operationally_active(school_id)
  and (
    private.has_school_access(school_id, array['proprietor','administrator']::public.school_member_role[])
    or exists (
      select 1 from public.schoolpro_members m
      where m.id = member_id and m.school_id = school_id and m.user_id = auth.uid()
    )
  )
);

create or replace function private.schoolpro_member_leads_student_section(
  p_school uuid, p_student uuid, p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_members m
      join public.schoolpro_section_leaders sl
        on sl.school_id=m.school_id and sl.member_id=m.id
      join public.schoolpro_students st
        on st.school_id=p_school and st.id=p_student
      join public.schoolpro_classes c
        on c.school_id=p_school
       and c.id=coalesce((
         select eh.class_id
         from public.schoolpro_enrollment_history eh
         where eh.school_id=p_school and eh.student_id=p_student
           and eh.session=trim(coalesce(p_session,''))
         order by eh.created_at desc
         limit 1
       ), st.class_id)
       and c.level=sl.section
      where m.school_id=p_school and m.user_id=auth.uid()
        and m.role in ('head_teacher','vice_principal')
    )
$$;
revoke all on function private.schoolpro_member_leads_student_section(uuid,uuid,text) from public, anon;
grant execute on function private.schoolpro_member_leads_student_section(uuid,uuid,text) to authenticated;

create or replace function private.schoolpro_set_section_leader(
  p_school uuid, p_member uuid, p_section text, p_assigned boolean
) returns void
language plpgsql security definer set search_path=''
as $$
declare target public.schoolpro_members;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not private.has_school_access(p_school, array['proprietor','administrator']::public.school_member_role[]) then
    raise exception 'Only school leadership can manage section assignments';
  end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Choose a valid school section';
  end if;
  select * into target from public.schoolpro_members
   where id=p_member and school_id=p_school for update;
  if target.id is null or target.role not in ('head_teacher','vice_principal') then
    raise exception 'Assign a head teacher or vice principal from this school';
  end if;
  if coalesce(p_assigned,false) then
    insert into public.schoolpro_section_leaders(school_id,member_id,section,assigned_by)
    values(p_school,p_member,p_section,auth.uid())
    on conflict(school_id,member_id,section) do update set assigned_by=excluded.assigned_by, assigned_at=now();
  else
    delete from public.schoolpro_section_leaders
     where school_id=p_school and member_id=p_member and section=p_section;
  end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Section leadership assignment updated','member',p_member,
    jsonb_build_object('section',p_section,'assigned',coalesce(p_assigned,false)));
end
$$;
revoke all on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean) from public, anon;
grant execute on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean) to authenticated;
create or replace function public.schoolpro_set_section_leader(
  p_school uuid, p_member uuid, p_section text, p_assigned boolean
) returns void language sql security invoker set search_path=''
as $$ select private.schoolpro_set_section_leader(p_school,p_member,p_section,p_assigned) $$;
revoke all on function public.schoolpro_set_section_leader(uuid,uuid,text,boolean) from public, anon;
grant execute on function public.schoolpro_set_section_leader(uuid,uuid,text,boolean) to authenticated;

create or replace function private.schoolpro_can_write_result(
  p_school uuid, p_student uuid, p_subject uuid, p_session text
) returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and private.is_active_account()
    and private.schoolpro_module_allowed(p_school,'results')
    and exists(select 1 from public.schoolpro_students s where s.id=p_student and s.school_id=p_school)
    and exists(select 1 from public.schoolpro_subjects sub where sub.id=p_subject and sub.school_id=p_school)
    and (
      private.has_school_access(p_school,array['proprietor','administrator','exam_officer']::public.school_member_role[])
      or private.schoolpro_member_leads_student_section(p_school,p_student,p_session)
      or exists(
        select 1 from public.schoolpro_students st
        join public.schoolpro_members m on m.school_id=p_school and m.user_id=auth.uid()
          and m.role in('teacher','class_teacher')
        left join public.schoolpro_enrollment_history e
          on e.school_id=p_school and e.student_id=st.id and e.session=trim(p_session)
        where st.id=p_student and st.school_id=p_school and st.status='active'
          and (
            exists(select 1 from public.schoolpro_classes c
              where c.id=coalesce(e.class_id,st.class_id) and c.school_id=p_school and c.form_teacher_id=m.id)
            or exists(select 1 from public.schoolpro_subject_assignments a
              where a.school_id=p_school and a.class_id=coalesce(e.class_id,st.class_id)
                and a.teacher_member_id=m.id and a.subject_id=p_subject and trim(a.session)=trim(p_session))
          )
      )
    )
$$;
revoke all on function private.schoolpro_can_write_result(uuid,uuid,uuid,text) from public, anon;
grant execute on function private.schoolpro_can_write_result(uuid,uuid,uuid,text) to authenticated;

create or replace function private.enforce_result_workflow()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if old.status = 'published' and (
    new.ca_score <> old.ca_score or new.exam_score <> old.exam_score
    or new.assessment_scores is distinct from old.assessment_scores
    or new.assessment_scheme_id is distinct from old.assessment_scheme_id
  ) then
    raise exception 'Published results are locked';
  end if;
  if new.status is distinct from old.status and not (
    private.is_admin(array['super_admin']::public.user_role[])
    or private.has_school_access(new.school_id,array['proprietor','administrator','exam_officer']::public.school_member_role[])
    or private.schoolpro_member_leads_student_section(new.school_id,new.student_id,new.session)
  ) then
    raise exception 'Only authorized school or section leaders can approve or publish results';
  end if;
  if new.status = 'approved' and old.status <> 'approved' then
    new.approved_by := auth.uid(); new.approved_at := now();
  end if;
  if new.status = 'published' and old.status <> 'published' then
    new.published_at := now();
  end if;
  return new;
end;
$$;


-- Replace the broad leadership read path: head teachers and vice principals
-- must read only their assigned section, while existing teacher/family rules stay intact.
create or replace function private.schoolpro_member_leads_class(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_section_leaders sl on sl.school_id=m.school_id and sl.member_id=m.id
    join public.schoolpro_classes c on c.school_id=p_school and c.id=p_class and c.level=sl.section
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.role in('head_teacher','vice_principal')
  )
$$;
revoke all on function private.schoolpro_member_leads_class(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_member_leads_class(uuid,uuid) to authenticated;

create or replace function private.schoolpro_can_read_student(p_student uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_students s
   where s.id=p_student and private.schoolpro_operationally_active(s.school_id)
   and (
     private.is_admin(array['super_admin'::public.user_role])
     or s.user_id=auth.uid()
     or exists(select 1 from public.schoolpro_guardian_links g
       where g.school_id=s.school_id and g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')
     or exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=auth.uid())
     or private.schoolpro_member_leads_class(s.school_id,s.class_id)
     or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=auth.uid() and (
       m.role::text not in('teacher','class_teacher','parent','student','head_teacher','vice_principal')
       or (m.role in('teacher','class_teacher') and (
         exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=s.school_id and a.class_id=s.class_id and a.teacher_member_id=m.id)
         or exists(select 1 from public.schoolpro_classes c where c.id=s.class_id and c.school_id=s.school_id and c.form_teacher_id=m.id)
       ))
     ))
   )
 )
$$;
revoke all on function private.schoolpro_can_read_student(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_student(uuid) to authenticated;

create or replace function private.schoolpro_can_read_class(p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_classes c where c.id=p_class and (
     private.has_school_access(c.school_id,array['proprietor','administrator']::public.school_member_role[])
     or private.schoolpro_member_leads_class(c.school_id,c.id)
     or exists(select 1 from public.schoolpro_members m where m.school_id=c.school_id and m.user_id=auth.uid() and (
       m.role::text not in('teacher','class_teacher','parent','student','head_teacher','vice_principal')
       or c.form_teacher_id=m.id
       or exists(select 1 from public.schoolpro_subject_assignments a
         where a.class_id=c.id and a.school_id=c.school_id and a.teacher_member_id=m.id)
     ))
     or exists(select 1 from public.schoolpro_students s where s.class_id=c.id and s.school_id=c.school_id
       and (s.user_id=auth.uid() or exists(select 1 from public.schoolpro_guardian_links g
         where g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')))
   )
 )
$$;
revoke all on function private.schoolpro_can_read_class(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_class(uuid) to authenticated;

alter policy "Result access gate" on public.schoolpro_results
using (
  (private.schoolpro_can_read_student(student_id)
   or private.schoolpro_member_leads_student_section(school_id,student_id,session))
  and coalesce((select a.allowed from private.schoolpro_result_access(student_id,term,session) a),false)
);

create or replace function private.schoolpro_prune_section_leadership_role()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if new.role not in ('head_teacher','vice_principal') then
    delete from public.schoolpro_section_leaders
    where school_id=new.school_id and member_id=new.id;
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_prune_section_leadership_role() from public,anon,authenticated;
drop trigger if exists schoolpro_prune_section_leadership_role on public.schoolpro_members;
create trigger schoolpro_prune_section_leadership_role
after update of role on public.schoolpro_members
for each row execute function private.schoolpro_prune_section_leadership_role();
