-- Stage C0: preserve and terminate operational appointments on staff suspension.
-- Prerequisites: lifecycle foundation, active-membership helper migration,
-- and active staff/class assignment guards. Reactivation deliberately does not
-- resurrect prior appointments; school leadership must reappoint explicitly.

alter table public.schoolpro_board_members
  add column if not exists ended_at timestamptz,
  add column if not exists ended_by uuid references auth.users(id),
  add column if not exists end_reason text;
alter table public.schoolpro_section_leaders
  add column if not exists ended_at timestamptz,
  add column if not exists ended_by uuid references auth.users(id),
  add column if not exists end_reason text;
alter table public.schoolpro_subject_assignments
  add column if not exists ended_at timestamptz,
  add column if not exists ended_by uuid references auth.users(id),
  add column if not exists end_reason text;
alter table public.schoolpro_house_master_assignments
  add column if not exists ended_by uuid references auth.users(id),
  add column if not exists end_reason text;
alter table public.schoolpro_competition_judges
  add column if not exists ended_by uuid references auth.users(id),
  add column if not exists end_reason text;

create index if not exists schoolpro_subject_assignments_active_member_idx
  on public.schoolpro_subject_assignments(school_id,teacher_member_id,class_id,subject_id,session)
  where ended_at is null and teacher_member_id is not null;
create index if not exists schoolpro_section_leaders_active_member_idx
  on public.schoolpro_section_leaders(school_id,member_id,section)
  where ended_at is null;

create or replace function private.schoolpro_set_member_suspension_state(
  p_school uuid, p_member uuid, p_suspended boolean, p_reason text
) returns void
language plpgsql security definer set search_path=''
as $function$
declare
  target public.schoolpro_members;
  clean_reason text := btrim(coalesce(p_reason,''));
  remaining_proprietors integer;
  ended_count integer;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.has_school_access(
       p_school,array['proprietor','administrator']::public.school_member_role[]
     ) then
    raise exception 'Only active school leadership can suspend or restore staff';
  end if;
  if length(clean_reason) not between 10 and 1000 then
    raise exception 'Provide a reason between 10 and 1000 characters';
  end if;

  select * into target from public.schoolpro_members
  where id=p_member and school_id=p_school for update;
  if target.id is null then raise exception 'Staff membership was not found in the selected school'; end if;

  if coalesce(p_suspended,false) then
    if target.status='suspended' then raise exception 'Staff membership is already suspended'; end if;
    if target.role='proprietor'::public.school_member_role then
      select count(*) into remaining_proprietors from public.schoolpro_members m
      where m.school_id=p_school and m.role='proprietor'::public.school_member_role
        and m.status='active' and m.id<>target.id;
      if remaining_proprietors=0 then raise exception 'The final active proprietor cannot be suspended'; end if;
    end if;

    update public.schoolpro_members set status='suspended',suspended_at=now(),
      suspended_by=auth.uid(),suspension_reason=clean_reason
    where id=target.id and school_id=p_school;

    update public.schoolpro_house_master_assignments
      set ended_at=now(),ended_by=auth.uid(),end_reason=clean_reason
    where school_id=p_school and member_id=target.id and ended_at is null;
    get diagnostics ended_count=row_count;
    if ended_count>0 then
      insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
      values(p_school,auth.uid(),'House Master appointments ended','member',target.id::text,
        jsonb_build_object('count',ended_count,'reason',clean_reason));
    end if;

    update public.schoolpro_competition_judges
      set ended_at=now(),ended_by=auth.uid(),end_reason=clean_reason
    where school_id=p_school and member_id=target.id and ended_at is null;
    get diagnostics ended_count=row_count;
    if ended_count>0 then
      insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
      values(p_school,auth.uid(),'Competition judging appointments ended','member',target.id::text,
        jsonb_build_object('count',ended_count,'reason',clean_reason));
    end if;

    update public.schoolpro_board_members
      set ended_at=now(),ended_by=auth.uid(),end_reason=clean_reason
    where school_id=p_school and member_id=target.id and ended_at is null;
    get diagnostics ended_count=row_count;
    if ended_count>0 then
      insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
      values(p_school,auth.uid(),'Board appointments ended','member',target.id::text,
        jsonb_build_object('count',ended_count,'reason',clean_reason));
    end if;

    update public.schoolpro_section_leaders
      set ended_at=now(),ended_by=auth.uid(),end_reason=clean_reason
    where school_id=p_school and member_id=target.id and ended_at is null;
    get diagnostics ended_count=row_count;
    if ended_count>0 then
      insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
      values(p_school,auth.uid(),'Section leadership appointments ended','member',target.id::text,
        jsonb_build_object('count',ended_count,'reason',clean_reason));
    end if;

    update public.schoolpro_subject_assignments
      set ended_at=now(),ended_by=auth.uid(),end_reason=clean_reason,updated_at=now()
    where school_id=p_school and teacher_member_id=target.id and ended_at is null;
    get diagnostics ended_count=row_count;
    if ended_count>0 then
      insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
      values(p_school,auth.uid(),'Subject teaching appointments ended','member',target.id::text,
        jsonb_build_object('count',ended_count,'reason',clean_reason));
    end if;

    -- Form Master is a single current pointer on the class row. Preserve the
    -- former assignment in the audit log before clearing the operational pointer.
    with ended_classes as (
      update public.schoolpro_classes
      set form_teacher_id=null,updated_at=now()
      where school_id=p_school and form_teacher_id=target.id and archived_at is null
      returning id,name,level
    )
    insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
    select p_school,auth.uid(),'Form Master appointment ended','class',id::text,
      jsonb_build_object('member_id',target.id,'class_name',name,'class_level',level,'reason',clean_reason)
    from ended_classes;
  else
    if target.status<>'suspended' then raise exception 'Staff membership is not suspended'; end if;
    update public.schoolpro_members set status='active',suspended_at=null,
      suspended_by=null,suspension_reason=null
    where id=target.id and school_id=p_school;
    -- Intentionally do not restore historic appointments automatically.
  end if;

  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),
    case when p_suspended then 'Staff membership suspended' else 'Staff membership restored' end,
    'member',target.id::text,
    jsonb_build_object('reason',clean_reason,'role',target.role::text,
      'user_id',target.user_id,'previous_status',target.status,
      'appointments_restored',false));
end
$function$;

-- Historical appointment rows remain queryable; only active-reader functions
-- should expose ended_at IS NULL rows. Keep grants unchanged for private helpers.
