-- Stage C0: ensure ended appointments never continue granting operational access.
-- Prerequisites: lifecycle foundation, active-membership authorization,
-- active staff/class assignment guards, and appointment termination migration.

create or replace function private.schoolpro_member_leads_class(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_members m
   join public.schoolpro_section_leaders sl
     on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
   join public.schoolpro_classes c
     on c.school_id=p_school and c.id=p_class and c.level=sl.section and c.archived_at is null
   where m.school_id=p_school and m.user_id=auth.uid()
     and m.status='active' and m.role in('head_teacher','vice_principal')
 )
$function$;

create or replace function private.schoolpro_member_leads_student_section(
 p_school uuid,p_student uuid,p_session text
) returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1
   from public.schoolpro_members m
   join public.schoolpro_section_leaders sl
     on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
   join public.schoolpro_students st on st.school_id=p_school and st.id=p_student
   join public.schoolpro_classes c on c.school_id=p_school
     and c.id=coalesce((
       select eh.class_id from public.schoolpro_enrollment_history eh
       where eh.school_id=p_school and eh.student_id=p_student
         and eh.session=trim(coalesce(p_session,''))
       order by eh.created_at desc limit 1
     ),st.class_id)
     and c.level=sl.section and c.archived_at is null
   where m.school_id=p_school and m.user_id=auth.uid()
     and m.status='active' and m.role in('head_teacher','vice_principal')
 )
$function$;

create or replace function private.schoolpro_can_read_student(p_student uuid)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_students s
   where s.id=p_student and private.schoolpro_operationally_active(s.school_id)
   and (
     private.is_admin(array['super_admin'::public.user_role])
     or s.user_id=auth.uid()
     or exists(select 1 from public.schoolpro_guardian_links g
       where g.school_id=s.school_id and g.student_id=s.id
         and g.guardian_user_id=auth.uid() and g.status='active')
     or exists(select 1 from public.schoolpro_schools sc
       where sc.id=s.school_id and sc.owner_id=auth.uid())
     or private.schoolpro_member_leads_class(s.school_id,s.class_id)
     or exists(
       select 1 from public.schoolpro_members m
       where m.school_id=s.school_id and m.user_id=auth.uid() and m.status='active'
       and (
         m.role::text not in('teacher','class_teacher','parent','student','head_teacher','vice_principal')
         or (m.role in('teacher','class_teacher') and (
           exists(select 1 from public.schoolpro_subject_assignments a
             join public.schoolpro_classes c on c.id=a.class_id and c.school_id=a.school_id
             where a.school_id=s.school_id and a.class_id=s.class_id
               and a.teacher_member_id=m.id and a.ended_at is null and c.archived_at is null)
           or exists(select 1 from public.schoolpro_classes c
             where c.id=s.class_id and c.school_id=s.school_id
               and c.form_teacher_id=m.id and c.archived_at is null)
         ))
       )
     )
   )
 )
$function$;

create or replace function private.schoolpro_can_write_result(
 p_school uuid,p_student uuid,p_subject uuid,p_session text
) returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and private.is_active_account()
   and private.schoolpro_module_allowed(p_school,'results')
   and exists(select 1 from public.schoolpro_students s where s.id=p_student and s.school_id=p_school)
   and exists(select 1 from public.schoolpro_subjects sub where sub.id=p_subject and sub.school_id=p_school)
   and (
     private.has_school_access(p_school,array['proprietor','administrator','exam_officer']::public.school_member_role[])
     or private.schoolpro_member_leads_student_section(p_school,p_student,p_session)
     or exists(
       select 1 from public.schoolpro_students st
       join public.schoolpro_members m on m.school_id=p_school and m.user_id=auth.uid()
         and m.status='active' and m.role in('teacher','class_teacher')
       left join public.schoolpro_enrollment_history e
         on e.school_id=p_school and e.student_id=st.id and e.session=trim(p_session)
       where st.id=p_student and st.school_id=p_school and st.status='active'
         and (
           exists(select 1 from public.schoolpro_classes c
             where c.id=coalesce(e.class_id,st.class_id) and c.school_id=p_school
               and c.form_teacher_id=m.id and c.archived_at is null)
           or exists(select 1 from public.schoolpro_subject_assignments a
             join public.schoolpro_classes c on c.id=a.class_id and c.school_id=a.school_id
             where a.school_id=p_school and a.class_id=coalesce(e.class_id,st.class_id)
               and a.teacher_member_id=m.id and a.subject_id=p_subject
               and trim(a.session)=trim(p_session) and a.ended_at is null and c.archived_at is null)
         )
     )
   )
$function$;

create or replace function private.schoolpro_can_review_class(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and private.is_active_account()
   and private.schoolpro_operationally_active(p_school)
   and private.schoolpro_module_allowed(p_school,'results')
   and private.schoolpro_module_allowed(p_school,'reports')
   and exists(select 1 from public.schoolpro_classes
     where id=p_class and school_id=p_school and archived_at is null)
   and (private.schoolpro_can_issue_transcript(p_school)
     or p_class=any(private.schoolpro_coordinator_classes(p_school)))
$function$;

create or replace function private.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security definer set search_path=''
as $function$
 select m.id,m.user_id,m.role::text,
   coalesce(nullif(trim(concat_ws(' ',p.first_name,p.last_name)),''),'Staff member')
 from public.schoolpro_members m join public.profiles p on p.id=m.user_id
 where m.school_id=p_school and m.status='active'
   and auth.uid() is not null and private.is_active_account()
   and private.schoolpro_operationally_active(p_school) and private.has_school_access(p_school)
   and (
     private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
     or m.user_id=auth.uid()
     or exists(select 1 from public.schoolpro_classes c
       where c.school_id=p_school and c.archived_at is null
         and private.schoolpro_can_read_class(c.id)
         and (c.form_teacher_id=m.id or exists(
           select 1 from public.schoolpro_subject_assignments a
           where a.school_id=p_school and a.class_id=c.id
             and a.teacher_member_id=m.id and a.ended_at is null)))
   )
$function$;

create or replace function private.schoolpro_house_master_roster(p_school uuid)
returns table(house_id uuid,house_name text,house_color text,student_id uuid,
 admission_number text,first_name text,middle_name text,last_name text,
 class_name text,class_arm text,assigned_at timestamptz)
language sql stable security definer set search_path=''
as $function$
 select h.id,h.name,h.color,st.id,st.admission_number,st.first_name,st.middle_name,
   st.last_name,coalesce(c.name,st.class_name),c.arm,sh.assigned_at
 from public.schoolpro_house_master_assignments a
 join public.schoolpro_members m on m.id=a.member_id and m.school_id=a.school_id
 join public.schoolpro_houses h on h.id=a.house_id and h.school_id=a.school_id and h.is_active
 left join public.schoolpro_student_house_history sh
   on sh.school_id=a.school_id and sh.house_id=a.house_id and sh.effective_to is null
 left join public.schoolpro_students st
   on st.id=sh.student_id and st.school_id=sh.school_id and st.status='active'
 left join public.schoolpro_classes c on c.id=st.class_id and c.school_id=st.school_id
 where p_school is not null and auth.uid() is not null and private.is_active_account()
   and a.school_id=p_school and a.ended_at is null and m.status='active'
   and m.user_id=auth.uid()
   and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
$function$;

create or replace function private.schoolpro_is_house_master(p_school uuid,p_house uuid default null)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_house_master_assignments a
   join public.schoolpro_members m on m.id=a.member_id and m.school_id=a.school_id
   where a.school_id=p_school and a.ended_at is null and m.status='active'
     and m.user_id=auth.uid()
     and (p_house is null or a.house_id=p_house)
     and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
 )
$function$;

create or replace function private.schoolpro_lesson_author_scope(
 p_school uuid,p_class uuid,p_subject uuid
) returns boolean language sql stable security definer set search_path=''
as $function$
 select exists(
   select 1 from public.schoolpro_members m join public.profiles p on p.id=m.user_id
   where m.school_id=p_school and m.user_id=auth.uid()
     and m.status='active' and p.status='active'
     and m.role in('teacher','class_teacher')
     and (
       exists(select 1 from public.schoolpro_classes c
         where c.id=p_class and c.school_id=p_school and c.form_teacher_id=m.id and c.archived_at is null)
       or exists(select 1 from public.schoolpro_subject_assignments a
         join public.schoolpro_classes c on c.id=a.class_id and c.school_id=a.school_id
         where a.school_id=p_school and a.class_id=p_class and a.teacher_member_id=m.id
           and (p_subject is null or a.subject_id=p_subject)
           and a.ended_at is null and c.archived_at is null)
     )
 )
$function$;

create or replace function private.schoolpro_lesson_leader(p_school uuid)
returns boolean language sql stable security definer set search_path=''
as $function$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active')
 and (
   private.is_admin(array['super_admin']::public.user_role[])
   or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
   or exists(select 1 from public.schoolpro_members m
     where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
       and m.role in('administrator','head_teacher','vice_principal'))
 )
$function$;

create or replace function private.schoolpro_validate_house_master()
returns trigger language plpgsql set search_path=''
as $function$
begin
 if not exists(select 1 from public.schoolpro_houses h
   where h.id=new.house_id and h.school_id=new.school_id and h.is_active)
 then raise exception 'House must be active and belong to the selected school'; end if;
 if not exists(select 1 from public.schoolpro_members m
   where m.id=new.member_id and m.school_id=new.school_id and m.status='active'
     and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role))
 then raise exception 'House Master must be active teaching staff in the same school'; end if;
 return new;
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
 if p_section not in('nursery','primary','junior_secondary','senior_secondary','other')
 then raise exception 'Choose a valid school section'; end if;
 select * into target from public.schoolpro_members
 where id=p_member and school_id=p_school for update;
 if target.id is null or target.status<>'active'
    or target.role not in('head_teacher','vice_principal')
 then raise exception 'Choose an active head teacher or vice principal from this school'; end if;
 if coalesce(p_assigned,false) then
   insert into public.schoolpro_section_leaders(school_id,member_id,section,assigned_by)
   values(p_school,p_member,p_section,auth.uid())
   on conflict(school_id,member_id,section)
   do update set assigned_by=excluded.assigned_by,assigned_at=now(),
     ended_at=null,ended_by=null,end_reason=null;
 else
   update public.schoolpro_section_leaders
   set ended_at=coalesce(ended_at,now()),ended_by=auth.uid(),end_reason='Appointment withdrawn'
   where school_id=p_school and member_id=p_member and section=p_section and ended_at is null;
 end if;
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
 values(p_school,auth.uid(),'Section leadership assignment updated','member',p_member,
   jsonb_build_object('section',p_section,'assigned',coalesce(p_assigned,false)));
end
$function$;

create or replace function private.schoolpro_set_board_role(p_school uuid,p_member uuid,p_title text)
returns void language plpgsql security definer set search_path=''
as $function$
declare m public.schoolpro_members; old_role public.school_member_role;
begin
 if auth.uid() is null or not private.is_active_account()
   or not private.schoolpro_operationally_active(p_school)
   or not (private.is_admin(array['super_admin']::public.user_role[])
     or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid()))
 then raise exception 'Only the school owner can appoint school leadership'; end if;
 if p_member is null then
   if p_title not in('Proprietor','Director','School Owner','Co-owner') or p_title is null
   then raise exception 'Choose an owner title'; end if;
   insert into public.schoolpro_leadership_settings(school_id,owner_title)
   values(p_school,p_title) on conflict(school_id) do update set owner_title=excluded.owner_title;
 else
   select * into m from public.schoolpro_members
   where id=p_member and school_id=p_school and status='active' for update;
   if m.id is null or m.role='proprietor'
      or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=m.user_id)
   then raise exception 'Choose active staff in this school'; end if;
   if p_title is null then
     select previous_role into old_role from public.schoolpro_board_members
     where member_id=m.id and school_id=p_school and ended_at is null;
     update public.schoolpro_board_members
       set ended_at=now(),ended_by=auth.uid(),end_reason='Appointment withdrawn'
     where member_id=m.id and school_id=p_school and ended_at is null;
     if old_role is not null and m.role='administrator'
     then update public.schoolpro_members set role=old_role where id=m.id and school_id=p_school; end if;
   else
     if p_title not in('Chairperson','Director','Co-owner','Board Secretary','Board Member','Executive Director','Deputy Director')
     then raise exception 'Choose a leadership title'; end if;
     insert into public.schoolpro_board_members(member_id,school_id,title,previous_role,appointed_by)
     values(m.id,p_school,p_title,m.role,auth.uid())
     on conflict(member_id) do update set title=excluded.title,appointed_by=excluded.appointed_by,
       previous_role=excluded.previous_role,appointed_at=now(),
       ended_at=null,ended_by=null,end_reason=null;
     update public.schoolpro_members set role='administrator'
       where id=m.id and school_id=p_school;
   end if;
 end if;
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
 values(p_school,auth.uid(),'Leadership appointment updated','member',coalesce(p_member,p_school),
   jsonb_build_object('title',p_title));
end
$function$;

-- Extend the active assignment validators from the prior C0 migration so ended
-- appointments cannot be revived by a stale subject assignment row.
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
       and trim(sa.session)=new.session and sa.ended_at is null and c.archived_at is null
   ) then raise exception 'Teacher has no active assignment for this active class, subject and session'; end if;
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
   where m.id=new.teacher_member_id and m.school_id=new.school_id and m.status='active'
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
   if member_school is null or member_school<>new.school_id or member_status<>'active'
     or member_role not in('teacher','class_teacher')
   then raise exception 'Assigned teacher must be active eligible teaching staff of this school'; end if;
 end if;
 return new;
end
$function$;

-- Preserve all existing function EXECUTE grants. These helpers are consumed by
-- RLS policies and triggers; changing grants here could silently break policy checks.
