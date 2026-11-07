-- Final C0 pass for direct staff-member consumers and assignment triggers.
begin;

create or replace function private.schoolpro_coordinator_classes(p_school uuid)
returns uuid[]
language sql stable security definer
set search_path = ''
as $function$
  select coalesce(array_agg(c.id),array[]::uuid[])
  from public.schoolpro_classes c
  join public.schoolpro_members m
    on m.id=c.form_teacher_id and m.school_id=c.school_id
  where c.school_id=p_school and c.archived_at is null
    and m.user_id=auth.uid() and m.role in('teacher','class_teacher')
    and m.status='active'
    and auth.uid() is not null and private.is_active_account()
    and private.schoolpro_operationally_active(p_school)
    and private.schoolpro_module_allowed(p_school,'results')
$function$;

create or replace function private.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security definer
set search_path = ''
as $function$
  select m.id,m.user_id,m.role::text,
    coalesce(nullif(trim(concat_ws(' ',p.first_name,p.last_name)),''),'Staff member')
  from public.schoolpro_members m
  join public.profiles p on p.id=m.user_id
  where m.school_id=p_school and m.status='active'
    and auth.uid() is not null and private.is_active_account()
    and private.schoolpro_operationally_active(p_school)
    and private.has_school_access(p_school)
    and (
      private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
      or m.user_id=auth.uid()
      or exists(
        select 1 from public.schoolpro_classes c
        where c.school_id=p_school and c.archived_at is null
          and private.schoolpro_can_read_class(c.id)
          and (
            c.form_teacher_id=m.id
            or exists(select 1 from public.schoolpro_subject_assignments a
              where a.school_id=p_school and a.class_id=c.id
                and a.teacher_member_id=m.id and a.ended_at is null)
          )
      )
    )
$function$;

create or replace function private.schoolpro_teacher_allocation_visible(
  p_school uuid,p_member uuid,p_class uuid
) returns boolean
language plpgsql stable security definer
set search_path = ''
as $function$
declare own_member uuid; own_role public.school_member_role;
begin
  if auth.uid() is null or not private.is_active_account()
    or not private.schoolpro_operationally_active(p_school) then return false; end if;

  select m.id,m.role into own_member,own_role
  from public.schoolpro_members m
  where m.school_id=p_school and m.user_id=auth.uid()
    and m.role in('teacher','class_teacher');

  if own_member is null then
    -- A suspended teacher must not fall through the non-teacher visibility path.
    if exists(select 1 from public.schoolpro_members m
      where m.school_id=p_school and m.user_id=auth.uid()
        and m.role in('teacher','class_teacher') and m.status<>'active') then
      return false;
    end if;
    return private.has_school_access(p_school);
  end if;

  if not exists(select 1 from public.schoolpro_members m
    where m.id=own_member and m.status='active') then return false; end if;

  return own_member=p_member or exists(
    select 1 from public.schoolpro_classes c
    where c.id=p_class and c.school_id=p_school and c.archived_at is null
      and c.form_teacher_id=own_member
  );
end;
$function$;

create or replace function private.schoolpro_set_form_master(p_class uuid,p_member uuid)
returns void
language plpgsql security definer
set search_path = ''
as $function$
declare s uuid;
begin
  select school_id into s from public.schoolpro_classes
  where id=p_class and archived_at is null for update;
  if s is null then raise exception 'Active class not found'; end if;
  if auth.uid() is null or not private.schoolpro_module_allowed(s,'classes')
    or not private.has_school_access(s,array['proprietor','administrator']::public.school_member_role[]) then
    raise exception 'Only active school leadership can assign class coordinators';
  end if;
  if p_member is not null and not exists(
    select 1 from public.schoolpro_members
    where id=p_member and school_id=s and status='active'
      and role in('teacher','class_teacher')
  ) then raise exception 'Choose an active teacher from this school'; end if;
  update public.schoolpro_classes set form_teacher_id=p_member
  where id=p_class and school_id=s and archived_at is null;
  insert into public.schoolpro_audit_logs(
    school_id,actor_id,action,entity_type,entity_id,metadata
  ) values(s,auth.uid(),'Class coordinator updated','class',p_class,
    jsonb_build_object('member_id',p_member));
end;
$function$;

create or replace function private.validate_schoolpro_subject_assignment()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
begin
  if nullif(trim(new.session),'') is null then
    raise exception 'Academic session is required';
  end if;
  new.session:=trim(new.session);
  if not exists(select 1 from public.schoolpro_classes c
    where c.id=new.class_id and c.school_id=new.school_id and c.archived_at is null) then
    raise exception 'Class must be active and belong to this school';
  end if;
  if not exists(select 1 from public.schoolpro_subjects s
    where s.id=new.subject_id and s.school_id=new.school_id) then
    raise exception 'Subject does not belong to this school';
  end if;
  if not exists(select 1 from public.schoolpro_members m
    where m.id=new.teacher_member_id and m.school_id=new.school_id
      and m.status='active'
      and m.role in('teacher','class_teacher','head_teacher','vice_principal','administrator','proprietor')) then
    raise exception 'Assigned teacher/member must be active and eligible in this school';
  end if;
  return new;
end;
$function$;

create or replace function private.validate_subject_assignment()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
declare class_school uuid; subject_school uuid; member_school uuid;
  member_role public.school_member_role; member_status text;
begin
  select school_id into class_school from public.schoolpro_classes
  where id=new.class_id and archived_at is null;
  select school_id into subject_school from public.schoolpro_subjects
  where id=new.subject_id;
  if class_school is null or subject_school is null
    or class_school<>new.school_id or subject_school<>new.school_id then
    raise exception 'Active class and subject must belong to the selected school';
  end if;
  if new.teacher_member_id is not null then
    select school_id,role,status into member_school,member_role,member_status
    from public.schoolpro_members where id=new.teacher_member_id;
    if member_school is null or member_school<>new.school_id
      or member_status<>'active'
      or member_role not in('teacher','class_teacher') then
      raise exception 'Assigned teacher must be an active eligible teaching member of this school';
    end if;
  end if;
  return new;
end;
$function$;

commit;
