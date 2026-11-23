-- Allow a Form Master to select an existing canonical school subject for
-- only the class currently assigned to that member. Catalogue creation and
-- direct subject-assignment writes remain school-administrator-only.

create or replace function public.schoolpro_form_master_select_class_subject(
  p_school uuid,
  p_class uuid,
  p_subject uuid,
  p_session text
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid;
  v_assignment_id uuid;
  v_inserted boolean := false;
begin
  if auth.uid() is null
     or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not private.schoolpro_module_allowed(p_school, 'results') then
    raise exception 'An active account with SchoolPro results access is required';
  end if;

  if nullif(btrim(coalesce(p_session, '')), '') is null then
    raise exception 'Choose an academic session';
  end if;

  select m.id
    into v_member_id
  from public.schoolpro_members m
  where m.school_id = p_school
    and m.user_id = auth.uid()
    and m.role in ('teacher'::public.school_member_role, 'class_teacher'::public.school_member_role)
    and coalesce(m.status::text, 'active') = 'active'
    and coalesce(m.employment_status::text, 'active') = 'active'
  order by case when m.role = 'class_teacher'::public.school_member_role then 0 else 1 end
  limit 1;

  if v_member_id is null then
    raise exception 'An active Form Master appointment is required';
  end if;

  if not exists (
    select 1 from public.schoolpro_classes c
    where c.id = p_class and c.school_id = p_school
      and c.form_teacher_id = v_member_id and c.archived_at is null
  ) then
    raise exception 'You can select subjects only for a class assigned to you as Form Master';
  end if;

  if not exists (
    select 1 from public.schoolpro_subjects s
    where s.id = p_subject and s.school_id = p_school
      and s.is_catalogue_entry = true
  ) then
    raise exception 'Choose an existing canonical subject from this school catalogue';
  end if;

  insert into public.schoolpro_subject_assignments (
    school_id, class_id, subject_id, teacher_member_id, session
  )
  values (p_school, p_class, p_subject, null, btrim(p_session))
  on conflict (class_id, subject_id, session) do nothing
  returning id into v_assignment_id;

  v_inserted := v_assignment_id is not null;

  if not v_inserted then
    select a.id into v_assignment_id
    from public.schoolpro_subject_assignments a
    where a.school_id = p_school and a.class_id = p_class
      and a.subject_id = p_subject and a.session = btrim(p_session);
  end if;

  if v_assignment_id is null then
    raise exception 'The subject allocation could not be confirmed. Refresh and try again';
  end if;

  if v_inserted then
    insert into public.schoolpro_audit_logs (
      school_id, actor_id, action, entity_type, entity_id, metadata
    ) values (
      p_school, auth.uid(), 'Form Master selected class subject',
      'subject_assignment', v_assignment_id,
      jsonb_build_object('class_id', p_class, 'subject_id', p_subject, 'session', btrim(p_session))
    );
  end if;

  return v_assignment_id;
end;
$$;

revoke all on function public.schoolpro_form_master_select_class_subject(uuid,uuid,uuid,text)
  from public, anon;
grant execute on function public.schoolpro_form_master_select_class_subject(uuid,uuid,uuid,text)
  to authenticated;
