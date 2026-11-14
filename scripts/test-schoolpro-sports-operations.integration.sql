\set ON_ERROR_STOP on
begin;
create extension if not exists pgcrypto;
create role authenticated;
create role anon;
create schema auth;
create schema private;
create type public.user_role as enum ('super_admin');
create type public.school_member_role as enum ('proprietor','administrator','teacher','class_teacher','game_master');
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
create table public.schoolpro_schools(id uuid primary key,owner_id uuid);
create table public.schoolpro_members(
 id uuid primary key,school_id uuid not null,user_id uuid not null,role public.school_member_role not null,
 status text not null,employment_status text not null,position_title text
);
create table public.schoolpro_member_responsibilities(
 school_id uuid not null,member_id uuid not null,responsibility text not null,ended_at timestamptz
);
create table public.schoolpro_students(
 id uuid primary key,school_id uuid not null,status text not null,first_name text not null,
 middle_name text,last_name text not null,admission_number text,class_id uuid,class_name text
);
create table public.schoolpro_classes(id uuid primary key,school_id uuid not null,name text not null,arm text);
create table public.schoolpro_houses(id uuid primary key,school_id uuid not null,name text not null,is_active boolean default true,sort_order integer default 1);
create table public.schoolpro_competition_events(id uuid primary key,school_id uuid not null,event_type text not null,unique(school_id,id));
create table public.schoolpro_competition_entries(id uuid primary key,school_id uuid not null,event_id uuid not null,entry_name text not null,unique(school_id,id));
create or replace function private.is_active_account() returns boolean language sql stable as $$ select auth.uid() is not null $$;
create or replace function private.schoolpro_operationally_active(p_school uuid) returns boolean language sql stable as $$
 select exists(select 1 from public.schoolpro_schools where id=p_school)
$$;
create or replace function private.is_admin(p_roles public.user_role[]) returns boolean language sql stable as $$ select auth.uid()='30000000-0000-0000-0000-000000000005'::uuid $$;
create or replace function public.schoolpro_user_permissions(p_school uuid) returns text[] language sql stable security definer set search_path='' as $$
 select case when exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.status='active' and m.employment_status='active' and m.role='game_master') then array['games']::text[] else array[]::text[] end
$$;
create or replace function private.schoolpro_module_allowed(p_school uuid,p_permission text) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and p_permission=any(public.schoolpro_user_permissions(p_school))
$$;
grant usage on schema public,auth,private to authenticated,anon;
grant execute on function auth.uid() to authenticated,anon;
grant execute on function private.is_active_account() to authenticated;
grant execute on function private.schoolpro_operationally_active(uuid) to authenticated;
grant execute on function private.is_admin(public.user_role[]) to authenticated;
grant execute on function private.schoolpro_module_allowed(uuid,text) to authenticated;
grant execute on function public.schoolpro_user_permissions(uuid) to authenticated;

\ir ../supabase/migrations/20261114190000_schoolpro_sports_operations.sql

insert into public.schoolpro_schools(id) values
 ('10000000-0000-0000-0000-000000000001'),('10000000-0000-0000-0000-000000000002');
insert into public.schoolpro_members(id,school_id,user_id,role,status,employment_status) values
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','game_master','active','active'),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002','teacher','active','active'),
 ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000003','class_teacher','active','active'),
 ('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000004','teacher','active','active');
insert into public.schoolpro_students(id,school_id,status,first_name,last_name,admission_number,class_name) values
 ('40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','active','Ada','One','A001','Basic 5'),
 ('40000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','active','Ben','Two','B001','Basic 5');
insert into public.schoolpro_houses(id,school_id,name) values
 ('50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Blue'),
 ('50000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Red');
insert into public.schoolpro_competition_events(id,school_id,event_type) values
 ('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','sports'),
 ('60000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','sports'),
 ('60000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','sports');
insert into public.schoolpro_competition_entries(id,school_id,event_id,entry_name) values
 ('61000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','Blue Eagles entry'),
 ('61000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','Track Squad entry'),
 ('61000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000003','Other event entry');

insert into public.schoolpro_sports_teams(id,school_id,name,sport) values
 ('70000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002','Other school team','Football');
select set_config('request.jwt.claim.sub','30000000-0000-0000-0000-000000000001',false);
set role authenticated;
insert into public.schoolpro_sports_teams(id,school_id,name,sport,house_id) values
 ('70000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Blue Eagles','Football','50000000-0000-0000-0000-000000000001'),
 ('70000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','Track Squad','Athletics',null),
 ('70000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','Unrelated Squad','Football',null);
insert into public.schoolpro_sports_team_coaches(school_id,team_id,member_id,assigned_by) values
 ('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002',auth.uid());
insert into public.schoolpro_sports_team_members(school_id,team_id,student_id,assigned_by) values
 ('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',auth.uid());
insert into public.schoolpro_sports_training_sessions(school_id,team_id,title,starts_at) values
 ('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','Tuesday training',now()+interval '1 day');
insert into public.schoolpro_sports_fixtures(id,school_id,event_id,home_entry_id,away_entry_id,home_team_id,away_team_id,scheduled_at) values
 ('80000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','61000000-0000-0000-0000-000000000001','61000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000002',now()+interval '2 days');

do $$ begin
  begin
    insert into public.schoolpro_sports_fixtures(school_id,home_team_id,away_team_id,scheduled_at)
    values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000003',now()+interval '2 days');
    raise exception 'cross-school fixture team reference was accepted';
  exception when others then
    if sqlerrm='cross-school fixture team reference was accepted' then raise; end if;
  end;
  begin
    insert into public.schoolpro_sports_team_coaches(school_id,team_id,member_id)
    values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');
    raise exception 'non-teaching Game Master was accepted as a coach';
  exception when others then
    if sqlerrm='non-teaching Game Master was accepted as a coach' then raise; end if;
  end;
  begin
    insert into public.schoolpro_sports_fixtures(school_id,event_id,home_entry_id,away_entry_id,home_team_id,away_team_id,scheduled_at)
    values('10000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','61000000-0000-0000-0000-000000000001','61000000-0000-0000-0000-000000000003','70000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000002',now()+interval '2 days');
    raise exception 'fixture accepted an entry from another event';
  exception when others then
    if sqlerrm='fixture accepted an entry from another event' then raise; end if;
  end;
  begin
    insert into public.schoolpro_sports_teams(school_id,name,sport,house_id)
    values('10000000-0000-0000-0000-000000000001','Cross-school house','Football','50000000-0000-0000-0000-000000000002');
    raise exception 'cross-school house reference was accepted';
  exception when others then
    if sqlerrm='cross-school house reference was accepted' then raise; end if;
  end;
  begin
    insert into public.schoolpro_sports_team_coaches(school_id,team_id,member_id)
    values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000004');
    raise exception 'cross-school coach reference was accepted';
  exception when others then
    if sqlerrm='cross-school coach reference was accepted' then raise; end if;
  end;
  begin
    insert into public.schoolpro_sports_team_members(school_id,team_id,student_id)
    values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002');
    raise exception 'cross-school student reference was accepted';
  exception when others then
    if sqlerrm='cross-school student reference was accepted' then raise; end if;
  end;
  begin
    insert into public.schoolpro_sports_team_members(school_id,team_id,student_id)
    values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');
    raise exception 'duplicate active squad enrollment was accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.schoolpro_sports_team_members(school_id,team_id,student_id)
    values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001');
    raise exception 'incompatible squad enrollment was accepted';
  exception when others then
    if sqlerrm='incompatible squad enrollment was accepted' then raise; end if;
  end;
end $$;

update public.schoolpro_sports_fixtures set scheduled_at=scheduled_at+interval '1 hour',venue='Main field'
where id='80000000-0000-0000-0000-000000000001';
update public.schoolpro_sports_fixtures set status='in_progress'
where id='80000000-0000-0000-0000-000000000001';
select public.schoolpro_record_sports_fixture_result('10000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000001',2,1,'First score',true);
do $$ begin
  begin
    update public.schoolpro_sports_fixtures set status='completed'
    where id='80000000-0000-0000-0000-000000000001';
    raise exception 'direct fixture completion bypassed audited RPC';
  exception when others then
    if sqlerrm='direct fixture completion bypassed audited RPC' then raise; end if;
  end;
  begin
    update public.schoolpro_sports_fixtures set home_score=3
    where id='80000000-0000-0000-0000-000000000001';
    raise exception 'direct fixture result update bypassed audited RPC';
  exception when others then
    if sqlerrm='direct fixture result update bypassed audited RPC' then raise; end if;
  end;
end $$;
select public.schoolpro_record_sports_fixture_result('10000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000001',3,1,'Corrected score',true);
do $$ begin
 if (select count(*) from public.schoolpro_sports_fixture_result_history where fixture_id='80000000-0000-0000-0000-000000000001')<>2 then raise exception 'result amendment history missing'; end if;
 if (select count(*) from public.schoolpro_sports_fixture_audit where fixture_id='80000000-0000-0000-0000-000000000001')<1 then raise exception 'fixture reschedule/status audit missing'; end if;
end $$;

reset role;
select set_config('request.jwt.claim.sub','30000000-0000-0000-0000-000000000002',false);
set role authenticated;
do $$ begin
 if (select count(*) from public.schoolpro_sports_teams where school_id='10000000-0000-0000-0000-000000000001')<>2 then raise exception 'coach should see assigned team and fixture opponent metadata only'; end if;
 if (select count(*) from public.schoolpro_sports_team_members where school_id='10000000-0000-0000-0000-000000000001')<>1 then raise exception 'coach can see only assigned team roster'; end if;
 if (select count(*) from public.schoolpro_sports_coach_roster('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001'))<>1 then raise exception 'coach scoped roster unavailable'; end if;
 if (select count(*) from public.schoolpro_sports_training_sessions where school_id='10000000-0000-0000-0000-000000000001')<>1 then raise exception 'coach training session scope incorrect'; end if;
 if (select count(*) from public.schoolpro_sports_fixtures where school_id='10000000-0000-0000-0000-000000000001')<>1 then raise exception 'coach fixture scope incorrect'; end if;
 begin
   insert into public.schoolpro_sports_training_sessions(school_id,team_id,title,starts_at)
   values('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','Unauthorized session',now()+interval '3 days');
   raise exception 'coach was able to manage sports sessions';
 exception when insufficient_privilege then null;
 end;
end $$;

reset role;
select set_config('request.jwt.claim.sub','30000000-0000-0000-0000-000000000003',false);
set role authenticated;
do $$ begin
 if (select count(*) from public.schoolpro_sports_teams where school_id='10000000-0000-0000-0000-000000000001')<>0 then raise exception 'unassigned teacher can see sports teams'; end if;
 if (select count(*) from public.schoolpro_sports_coach_roster('10000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001'))<>0 then raise exception 'unassigned teacher can access coach roster'; end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub','30000000-0000-0000-0000-000000000001',false);
set role authenticated;
update public.schoolpro_sports_teams set is_active=false where id='70000000-0000-0000-0000-000000000001';
do $$ begin
 if (select count(*) from public.schoolpro_sports_team_coaches where team_id='70000000-0000-0000-0000-000000000001' and ended_at is null)<>0 then raise exception 'archiving team did not end active coach appointments'; end if;
 if (select count(*) from public.schoolpro_sports_team_members where team_id='70000000-0000-0000-0000-000000000001' and ended_at is null)<>0 then raise exception 'archiving team did not close active squad memberships'; end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub','30000000-0000-0000-0000-000000000005',false);
set role authenticated;
do $$ begin
 begin
  update public.schoolpro_sports_teams set school_id='10000000-0000-0000-0000-000000000002'
  where id='70000000-0000-0000-0000-000000000004';
  raise exception 'platform Super Admin reassigned a sports team across tenants';
 exception when others then
  if sqlerrm='platform Super Admin reassigned a sports team across tenants' then raise; end if;
 end;
end $$;
reset role;
rollback;
