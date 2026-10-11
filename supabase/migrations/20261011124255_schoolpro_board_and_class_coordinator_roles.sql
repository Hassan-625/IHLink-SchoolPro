create table public.schoolpro_board_members (
 member_id uuid primary key references public.schoolpro_members(id) on delete cascade,
 school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 title text not null check(title in ('Chairperson','Director','Co-owner','Board Secretary','Board Member','Executive Director','Deputy Director')),
 previous_role public.school_member_role not null,
 appointed_by uuid not null references auth.users(id),
 appointed_at timestamptz not null default now()
);
create index schoolpro_board_school_idx on public.schoolpro_board_members(school_id);
alter table public.schoolpro_board_members enable row level security;
revoke all on public.schoolpro_board_members from anon,authenticated;
grant select on public.schoolpro_board_members to authenticated;
create policy "School leaders and own board appointment" on public.schoolpro_board_members for select to authenticated using(private.is_active_account() and (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]) or exists(select 1 from public.schoolpro_members m where m.id=member_id and m.user_id=auth.uid())));
create table public.schoolpro_leadership_settings (
 school_id uuid primary key references public.schoolpro_schools(id) on delete cascade,
 owner_title text not null default 'Proprietor' check(owner_title in ('Proprietor','Director','School Owner','Co-owner'))
);
alter table public.schoolpro_leadership_settings enable row level security;
revoke all on public.schoolpro_leadership_settings from anon,authenticated;
grant select on public.schoolpro_leadership_settings to authenticated;
create policy "School leadership settings" on public.schoolpro_leadership_settings for select to authenticated using(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create function private.schoolpro_set_board_role(p_school uuid,p_member uuid,p_title text) returns void language plpgsql security definer set search_path='' as $$
declare m public.schoolpro_members; old_role public.school_member_role;
begin
 if auth.uid() is null or not private.is_active_account() or not private.schoolpro_operationally_active(p_school) or not (private.is_admin(array['super_admin']::public.user_role[]) or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())) then raise exception 'Only the school owner can appoint school leadership';end if;
 if p_member is null then
  if p_title not in ('Proprietor','Director','School Owner','Co-owner') or p_title is null then raise exception 'Choose an owner title';end if;
  insert into public.schoolpro_leadership_settings(school_id,owner_title) values(p_school,p_title) on conflict(school_id)do update set owner_title=excluded.owner_title;
 else
  select * into m from public.schoolpro_members where id=p_member and school_id=p_school for update;
  if m.id is null or m.role='proprietor' or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=m.user_id) then raise exception 'Choose an existing staff account in this school';end if;
  if p_title is null then
   select previous_role into old_role from public.schoolpro_board_members where member_id=m.id;
   delete from public.schoolpro_board_members where member_id=m.id;
   if old_role is not null and m.role='administrator' then update public.schoolpro_members set role=old_role where id=m.id;end if;
  else
   if p_title not in ('Chairperson','Director','Co-owner','Board Secretary','Board Member','Executive Director','Deputy Director') then raise exception 'Choose a leadership title';end if;
   insert into public.schoolpro_board_members(member_id,school_id,title,previous_role,appointed_by) values(m.id,p_school,p_title,m.role,auth.uid()) on conflict(member_id)do update set title=excluded.title,appointed_by=excluded.appointed_by;
   update public.schoolpro_members set role='administrator' where id=m.id;
  end if;
 end if;
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(p_school,auth.uid(),'Leadership appointment updated','member',coalesce(p_member,p_school),jsonb_build_object('title',p_title));
end $$;
revoke all on function private.schoolpro_set_board_role(uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_set_board_role(uuid,uuid,text) to authenticated;
create function public.schoolpro_set_board_role(p_school uuid,p_member uuid,p_title text)returns void language sql set search_path='' as $$select private.schoolpro_set_board_role(p_school,p_member,p_title)$$;
revoke all on function public.schoolpro_set_board_role(uuid,uuid,text)from public,anon;
grant execute on function public.schoolpro_set_board_role(uuid,uuid,text)to authenticated;
create function private.schoolpro_clear_changed_board_role() returns trigger language plpgsql security definer set search_path='' as $$begin if new.role<>'administrator' then delete from public.schoolpro_board_members where member_id=new.id;end if;return new;end$$;
revoke all on function private.schoolpro_clear_changed_board_role()from public,anon,authenticated;
create trigger schoolpro_clear_changed_board_role after update of role on public.schoolpro_members for each row execute function private.schoolpro_clear_changed_board_role();
create function private.schoolpro_set_form_master(p_class uuid,p_member uuid)returns void language plpgsql security definer set search_path='' as $$
declare s uuid;begin
 select school_id into s from public.schoolpro_classes where id=p_class;
 if auth.uid() is null or not private.schoolpro_module_allowed(s,'classes') or not private.has_school_access(s,array['proprietor','administrator']::public.school_member_role[]) then raise exception 'Only school leadership can assign class coordinators';end if;
 if p_member is not null and not exists(select 1 from public.schoolpro_members where id=p_member and school_id=s and role in('teacher','class_teacher')) then raise exception 'Choose a teacher from this school';end if;
 update public.schoolpro_classes set form_teacher_id=p_member where id=p_class;
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(s,auth.uid(),'Class coordinator updated','class',p_class,jsonb_build_object('member_id',p_member));
end$$;
revoke all on function private.schoolpro_set_form_master(uuid,uuid)from public,anon;
grant execute on function private.schoolpro_set_form_master(uuid,uuid)to authenticated;
create function public.schoolpro_set_form_master(p_class uuid,p_member uuid)returns void language sql set search_path='' as $$select private.schoolpro_set_form_master(p_class,p_member)$$;
revoke all on function public.schoolpro_set_form_master(uuid,uuid)from public,anon;
grant execute on function public.schoolpro_set_form_master(uuid,uuid)to authenticated;

CREATE OR REPLACE FUNCTION public.schoolpro_user_permissions(p_school uuid)
 RETURNS text[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare m public.schoolpro_members; base text[]; extra text[];begin if auth.uid() is null then return array[]::text[];end if; if exists(select 1 from public.schoolpro_board_members b join public.schoolpro_members bm on bm.id=b.member_id and bm.school_id=b.school_id where b.school_id=p_school and bm.user_id=auth.uid() and bm.role='administrator') then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;select * into m from public.schoolpro_members where school_id=p_school and user_id=auth.uid() limit 1;if exists(select 1 from public.schoolpro_schools where id=p_school and owner_id=auth.uid()) or private.is_admin(array['super_admin']::public.user_role[]) then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;if m.id is null then return array[]::text[];end if;base:=case m.role when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications'] when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications'] when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications'] when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications'] when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications'] when 'bursar' then array['dashboard','finance','students','notifications'] when 'accountant' then array['dashboard','finance','students','reports','notifications'] when 'teacher' then array['discipline','dashboard','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications'] when 'class_teacher' then array['discipline','dashboard','students','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','notifications'] when 'exam_officer' then array['dashboard','results','reports','cbt','students','classes','subjects','documents','notifications'] when 'registrar' then array['dashboard','students','classes','parents','documents','notifications'] when 'admissions_officer' then array['dashboard','admissions','students','documents','notifications'] when 'librarian' then array['dashboard','library','students','notifications'] when 'nurse' then array['dashboard','medical','students','notifications'] when 'hostel_manager' then array['dashboard','hostel','students','notifications'] when 'transport_manager' then array['dashboard','transport','students','notifications'] when 'inventory_officer' then array['dashboard','inventory','notifications'] when 'hr_officer' then array['dashboard','staff','leave','payroll','notifications'] when 'it_admin' then array['dashboard','roles','branding','operations','notifications'] else array['dashboard','notifications'] end;select array_agg(permission) into extra from public.schoolpro_member_permissions where member_id=m.id and allowed=true;return (select array_agg(distinct x) from unnest(base||coalesce(extra,array[]::text[])) x where not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission=x and p.allowed=false));end$function$

