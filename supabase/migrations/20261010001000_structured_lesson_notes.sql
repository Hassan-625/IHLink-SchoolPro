alter table public.schoolpro_lesson_notes
 add column if not exists lesson_date date,
 add column if not exists term text,
 add column if not exists session text,
 add column if not exists week integer,
 add column if not exists duration_minutes integer,
 add column if not exists plan jsonb not null default '{}'::jsonb,
 add column if not exists review_comment text,
 add column if not exists reviewed_by uuid references auth.users(id),
 add column if not exists reviewed_at timestamptz,
 add column if not exists updated_at timestamptz not null default now();
create or replace function private.schoolpro_lesson_leader(p_school uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active')
 and (private.is_admin(array['super_admin']::public.user_role[])
 or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role in('administrator','head_teacher','vice_principal')));
$$;
revoke all on function private.schoolpro_lesson_leader(uuid) from public,anon;
grant execute on function private.schoolpro_lesson_leader(uuid) to authenticated;
create or replace function private.schoolpro_lesson_author_scope(p_school uuid,p_class uuid,p_subject uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.schoolpro_members m join public.profiles p on p.id=m.user_id
 where m.school_id=p_school and m.user_id=auth.uid() and p.status='active' and m.role in('teacher','class_teacher')
 and (exists(select 1 from public.schoolpro_classes c where c.id=p_class and c.school_id=p_school and c.form_teacher_id=m.id)
 or exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=p_school and a.class_id=p_class and a.teacher_member_id=m.id and (p_subject is null or a.subject_id=p_subject))));
$$;
revoke all on function private.schoolpro_lesson_author_scope(uuid,uuid,uuid) from public,anon;
grant execute on function private.schoolpro_lesson_author_scope(uuid,uuid,uuid) to authenticated;
drop policy if exists "lesson notes author access" on public.schoolpro_lesson_notes;
drop policy if exists "lesson notes leadership access" on public.schoolpro_lesson_notes;
drop policy if exists "tenant read lesson notes" on public.schoolpro_lesson_notes;
drop policy if exists "tenant manage lesson notes" on public.schoolpro_lesson_notes;
create policy "lesson notes leadership access" on public.schoolpro_lesson_notes for all to authenticated
 using(private.schoolpro_module_allowed(school_id,'lesson-notes') and private.schoolpro_lesson_leader(school_id))
 with check(private.schoolpro_module_allowed(school_id,'lesson-notes') and private.schoolpro_lesson_leader(school_id));
create policy "lesson notes author access" on public.schoolpro_lesson_notes for all to authenticated
 using(private.schoolpro_module_allowed(school_id,'lesson-notes') and created_by=auth.uid() and private.schoolpro_lesson_author_scope(school_id,class_id,subject_id))
 with check(private.schoolpro_module_allowed(school_id,'lesson-notes') and created_by=auth.uid() and private.schoolpro_lesson_author_scope(school_id,class_id,subject_id));
create or replace function private.schoolpro_validate_lesson_workflow()
returns trigger language plpgsql security definer set search_path='' as $$
declare leader boolean;
begin
 if auth.uid() is null then raise exception 'Sign in to manage lesson notes';end if;
 leader:=private.schoolpro_lesson_leader(case when tg_op='DELETE' then old.school_id else new.school_id end);
 if tg_op='DELETE' then
  if old.status in('submitted','approved') then raise exception 'Reviewed or submitted lessons must be retained';end if;
  return old;
 end if;
 if new.status not in('draft','submitted','approved','changes_requested') then raise exception 'Choose a valid lesson status';end if;
 if tg_op='INSERT' then
  new.created_by:=auth.uid();
  if new.status not in('draft','submitted') then raise exception 'Save a draft or submit it for review first';end if;
  new.review_comment:=null;new.reviewed_by:=null;new.reviewed_at:=null;
 else
  if new.school_id<>old.school_id or new.created_by is distinct from old.created_by then raise exception 'Lesson ownership cannot be changed';end if;
  if old.status='approved' then raise exception 'Approved lessons must be retained; prepare a new copy';end if;
  if not leader then
   if old.status='submitted' then raise exception 'Wait for school review before editing this lesson';end if;
   if new.status not in('draft','submitted') then raise exception 'Only school leadership can review a lesson';end if;
   if new.review_comment is distinct from old.review_comment or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at then raise exception 'School review cannot be changed';end if;
  elsif new.status in('approved','changes_requested') and new.status is distinct from old.status then
   if old.status<>'submitted' then raise exception 'Only a submitted lesson can be reviewed';end if;
   if new.status='changes_requested' and coalesce(trim(new.review_comment),'')='' then raise exception 'Explain the changes needed';end if;
   if (to_jsonb(new)-array['status','review_comment','reviewed_by','reviewed_at','updated_at']) is distinct from (to_jsonb(old)-array['status','review_comment','reviewed_by','reviewed_at','updated_at']) then raise exception 'Review the saved lesson without changing its content';end if;
   new.reviewed_by:=auth.uid();new.reviewed_at:=now();
  elsif old.status='submitted' then raise exception 'Approve the lesson or request changes';
  end if;
 end if;
 if not leader and not private.schoolpro_lesson_author_scope(new.school_id,new.class_id,new.subject_id) then raise exception 'Choose your assigned class and subject';end if;
 if new.week is not null and (new.week<1 or new.week>53) then raise exception 'Week must be between 1 and 53';end if;
 if new.duration_minutes is not null and (new.duration_minutes<1 or new.duration_minutes>480) then raise exception 'Choose a lesson duration between 1 and 480 minutes';end if;
 if jsonb_typeof(new.plan)<>'object' then raise exception 'Lesson plan must contain named fields';end if;
 if new.status='submitted' and (new.class_id is null or new.subject_id is null or new.lesson_date is null or coalesce(trim(new.term),'')='' or coalesce(trim(new.session),'')='' or coalesce(trim(new.title),'')='' or coalesce(trim(new.plan->>'objectives'),'')='' or coalesce(trim(new.content),'')='') then raise exception 'Complete the class, subject, date, period, objectives and lesson content before submission';end if;
 new.updated_at:=now();return new;
end;
$$;
revoke all on function private.schoolpro_validate_lesson_workflow() from public,anon,authenticated;
drop trigger if exists schoolpro_lesson_workflow on public.schoolpro_lesson_notes;
create trigger schoolpro_lesson_workflow before insert or update or delete on public.schoolpro_lesson_notes for each row execute function private.schoolpro_validate_lesson_workflow();
create index if not exists schoolpro_lesson_notes_school_date on public.schoolpro_lesson_notes(school_id,lesson_date,created_at desc);
