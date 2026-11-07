-- Stage C0: remaining core staff readers and class/subject assignment guards.
-- Prerequisite: 20261107130000 lifecycle foundation, followed by
-- 20261107143000 active-membership authorization.
-- Does not yet cover every dependency, suspension appointment cleanup, DELETE
-- policy/grant closure, or the full regression suite.

create or replace function private.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security definer set search_path=''
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
             where a.school_id=p_school and a.class_id=c.id and a.teacher_member_id=m.id)
         )
     )
   )
$function$;

create or replace function private.schoolpro_coordinator_classes(p_school uuid)
returns uuid[]
language sql stable security definer set search_path=''
as $function$
 select coalesce(array_agg(c.id),array[]::uuid[])
 from public.schoolpro_classes c
 join public.schoolpro_members m
   on m.id=c.form_teacher_id and m.school_id=c.school_id
 where c.school_id=p_school and c.archived_at is null
   and m.user_id=auth.uid() and m.status='active'
   and m.role in('teacher','class_teacher')
   and auth.uid() is not null and private.is_active_account()
   and private.schoolpro_operationally_active(p_school)
   and private.schoolpro_module_allowed(p_school,'results')
$function$;

create or replace function private.schoolpro_teacher_allocation_visible(
 p_school uuid,p_member uuid,p_class uuid
) returns boolean
language plpgsql stable security definer set search_path=''
as $function$
declare own_member uuid;
begin
 if auth.uid() is null or not private.is_active_account() then return false; end if;
 select m.id into own_member
 from public.schoolpro_members m
 where m.school_id=p_school and m.user_id=auth.uid()
   and m.status='active' and m.role in('teacher','class_teacher');
 if own_member is null then
   -- A suspended staff member must not fall through as a non-teacher viewer.
   if exists(select 1 from public.schoolpro_members m
     where m.school_id=p_school and m.user_id=auth.uid() and m.status='suspended')
   then return false; end if;
   return true;
 end if;
 return own_member=p_member or exists(
   select 1 from public.schoolpro_classes c
   where c.id=p_class and c.school_id=p_school
     and c.archived_at is null and c.form_teacher_id=own_member
 );
end
$function$;

create or replace function private.schoolpro_set_form_master(p_class uuid,p_member uuid)
returns void language plpgsql security definer set search_path=''
as $function$
declare s uuid;
begin
 select school_id into s from public.schoolpro_classes
 where id=p_class and archived_at is null for update;
 if s is null then raise exception 'Choose an active class in this school'; end if;
 if auth.uid() is null
    or not private.schoolpro_module_allowed(s,'classes')
    or not private.has_school_access(s,array['proprietor','administrator']::public.school_member_role[])
 then raise exception 'Only school leadership can assign class coordinators'; end if;
 if p_member is not null and not exists(
   select 1 from public.schoolpro_members
   where id=p_member and school_id=s and status='active'
     and role in('teacher','class_teacher')
 ) then raise exception 'Choose active teaching staff from this school'; end if;
 update public.schoolpro_classes set form_teacher_id=p_member
 where id=p_class and school_id=s and archived_at is null;
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
 values(s,auth.uid(),'Class coordinator updated','class',p_class,jsonb_build_object('member_id',p_member));
end
$function$;

create or replace function private.schoolpro_set_section_leader(
 p_school uuid,p_member uuid,p_section text,p_assigned boolean
) returns void language plpgsql security definer set search_path=''
as $function$
declare target public.schoolpro_members;
begin
 if auth.uid() is null or not private.is_active_account()
    or not private.schoolpro_operationally_active(p_school)
    or not private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
 then raise exception 'Only school leadership can manage section assignments'; end if;
 if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other')
 then raise exception 'Choose a valid school section'; end if;
 select * into target from public.schoolpro_members
 where id=p_member and school_id=p_school for update;
 if target.id is null or target.status<>'active'
    or target.role not in ('head_teacher','vice_principal')
 then raise exception 'Choose an active head teacher or vice principal from this school'; end if;
 if coalesce(p_assigned,false) then
   insert into public.schoolpro_section_leaders(school_id,member_id,section,assigned_by)
   values(p_school,p_member,p_section,auth.uid())
   on conflict(school_id,member_id,section)
   do update set assigned_by=excluded.assigned_by,assigned_at=now();
 else
   delete from public.schoolpro_section_leaders
   where school_id=p_school and member_id=p_member and section=p_section;
 end if;
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
 values(p_school,auth.uid(),'Section leadership assignment updated','member',p_member,
   jsonb_build_object('section',p_section,'assigned',coalesce(p_assigned,false)));
end
$function$;

create or replace function private.validate_schoolpro_assignment_target()
returns trigger language plpgsql security definer set search_path=''
as $function$
declare v_member uuid;
begin
 new.session:=trim(new.session);
 if new.session='' then raise exception 'Academic session is required'; end if;
 if not exists(select 1 from public.schoolpro_classes c
   where c.id=new.class_id and c.school_id=new.school_id and c.archived_at is null)
 then raise exception 'Class is archived or does not belong to assignment school'; end if;
 if not exists(select 1 from public.schoolpro_subjects s
   where s.id=new.subject_id and s.school_id=new.school_id)
 then raise exception 'Subject does not belong to assignment school'; end if;
 if auth.uid() is not null and not private.has_school_access(new.school_id,
   array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,
         'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role])
 then
   select m.id into v_member from public.schoolpro_members m
   where m.school_id=new.school_id and m.user_id=auth.uid()
     and m.status='active' and m.role in('teacher','class_teacher') limit 1;
   if v_member is null or not exists(
     select 1 from public.schoolpro_subject_assignments sa
     join public.schoolpro_classes c on c.id=sa.class_id and c.school_id=sa.school_id
     where sa.school_id=new.school_id and sa.class_id=new.class_id
       and sa.subject_id=new.subject_id and sa.teacher_member_id=v_member
       and trim(sa.session)=new.session and c.archived_at is null
   ) then raise exception 'Teacher is not actively assigned to this active class, subject and session'; end if;
 end if;
 return new;
end
$function$;

create or replace function private.validate_schoolpro_subject_assignment()
returns trigger language plpgsql security definer set search_path=''
as $function$
begin
 if nullif(trim(new.session),'') is null then raise exception 'Academic session is required'; end if;
 new.session:=trim(new.session);
 if not exists(select 1 from public.schoolpro_classes c
   where c.id=new.class_id and c.school_id=new.school_id and c.archived_at is null)
 then raise exception 'Class is archived or does not belong to this school'; end if;
 if not exists(select 1 from public.schoolpro_subjects s
   where s.id=new.subject_id and s.school_id=new.school_id)
 then raise exception 'Subject does not belong to this school'; end if;
 if not exists(select 1 from public.schoolpro_members m
   where m.id=new.teacher_member_id and m.school_id=new.school_id
     and m.status='active'
     and m.role in('teacher','class_teacher','head_teacher','vice_principal','administrator','proprietor'))
 then raise exception 'Assigned staff membership must be active and eligible in this school'; end if;
 return new;
end
$function$;

create or replace function private.validate_subject_assignment()
returns trigger language plpgsql security definer set search_path=''
as $function$
declare class_school uuid; subject_school uuid; member_school uuid;
        member_role public.school_member_role; member_status text;
begin
 select school_id into class_school from public.schoolpro_classes
 where id=new.class_id and archived_at is null;
 select school_id into subject_school from public.schoolpro_subjects where id=new.subject_id;
 if class_school is null or subject_school is null
    or class_school<>new.school_id or subject_school<>new.school_id
 then raise exception 'Active class and subject must belong to the selected school'; end if;
 if new.teacher_member_id is not null then
   select school_id,role,status into member_school,member_role,member_status
   from public.schoolpro_members where id=new.teacher_member_id;
   if member_school is null or member_school<>new.school_id
      or member_status<>'active' or member_role not in('teacher','class_teacher')
   then raise exception 'Assigned teacher must be active eligible teaching staff of this school'; end if;
 end if;
 return new;
end
$function$;

-- Keep existing EXECUTE grants unchanged: these routines are used by deployed
-- RLS policies/triggers and the migration does not broaden their exposure.
