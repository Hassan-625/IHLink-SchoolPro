begin;
do $$
declare
 v_owner_id uuid:=gen_random_uuid();
 v_staff_id uuid:=gen_random_uuid();
 v_school_id uuid:=gen_random_uuid();
 v_other_school_id uuid:=gen_random_uuid();
 v_member_id uuid:=gen_random_uuid();
 v_permissions text[];
 v_role_name text;
begin
 insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
 values
  (v_owner_id,'authenticated','authenticated','owner-'||v_owner_id||'@example.invalid','{}','{"first_name":"Owner","middle_name":"Fixture","last_name":"Test"}',now(),now()),
  (v_staff_id,'authenticated','authenticated','staff-'||v_staff_id||'@example.invalid','{}','{"first_name":"Staff","middle_name":"Fixture","last_name":"Test"}',now(),now());
 insert into public.profiles(id,email) values
  (v_owner_id,'owner-'||v_owner_id||'@example.invalid'),
  (v_staff_id,'staff-'||v_staff_id||'@example.invalid')
 on conflict(id) do nothing;

 insert into public.schoolpro_schools(id,owner_id,name,code)
 values
  (v_school_id,v_owner_id,'Role permission fixture','ROLE-'||v_school_id),
  (v_other_school_id,v_owner_id,'Other role permission fixture','ROLE-'||v_other_school_id);
 insert into public.schoolpro_members(id,school_id,user_id,role)
 values(v_member_id,v_school_id,v_staff_id,'head_teacher');

 perform set_config('request.jwt.claim.sub',v_staff_id::text,true);
 foreach v_role_name in array array['head_teacher','vice_principal'] loop
  update public.schoolpro_members set role=v_role_name::public.school_member_role where id=v_member_id;
  v_permissions:=public.schoolpro_user_permissions(v_school_id);
  if not ('results'=any(v_permissions)) or 'finance'=any(v_permissions) or 'staff'=any(v_permissions) then
   raise exception 'Academic role scope failed for %',v_role_name;
  end if;
 end loop;

 update public.schoolpro_members set role='counsellor' where id=v_member_id;
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('discipline'=any(v_permissions)) or 'results'=any(v_permissions) then raise exception 'Counsellor scope failed';end if;

 update public.schoolpro_members set role='discipline_master' where id=v_member_id;
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('discipline'=any(v_permissions)) or 'games'=any(v_permissions) or 'finance'=any(v_permissions) then raise exception 'Discipline Master scope failed';end if;

 update public.schoolpro_members set role='game_master' where id=v_member_id;
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('games'=any(v_permissions)) or 'discipline'=any(v_permissions) or 'finance'=any(v_permissions) then raise exception 'Game Master scope failed';end if;

 update public.schoolpro_members set role='receptionist' where id=v_member_id;
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('admissions'=any(v_permissions)) or 'finance'=any(v_permissions) then raise exception 'Receptionist scope failed';end if;

 if coalesce(cardinality(public.schoolpro_user_permissions(v_other_school_id)),0)<>0 then raise exception 'Cross-school permissions exposed';end if;

 perform set_config('request.jwt.claim.sub',v_owner_id::text,true);
 update public.schoolpro_members set role='proprietor' where id=v_member_id;
 perform set_config('request.jwt.claim.sub',v_staff_id::text,true);
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('finance'=any(v_permissions)) or not ('medical'=any(v_permissions)) or not ('payroll'=any(v_permissions)) or not ('roles'=any(v_permissions)) then raise exception 'Proprietor-wide module scope failed';end if;

 -- The proprietor-role guard requires the school owner for both promotion and demotion.
 perform set_config('request.jwt.claim.sub',v_owner_id::text,true);
 update public.schoolpro_members set role='administrator' where id=v_member_id;
 perform set_config('request.jwt.claim.sub',v_staff_id::text,true);
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('finance'=any(v_permissions)) or not ('medical'=any(v_permissions)) or not ('payroll'=any(v_permissions)) or not ('games'=any(v_permissions)) then raise exception 'Administrator-wide module scope failed';end if;

 update public.schoolpro_members set role='head_teacher' where id=v_member_id;
 insert into public.schoolpro_board_members(member_id,school_id,title,previous_role,appointed_by)
 values(v_member_id,v_school_id,'Board Member','head_teacher',v_owner_id);
 v_permissions:=public.schoolpro_user_permissions(v_school_id);
 if not ('results'=any(v_permissions)) or 'finance'=any(v_permissions) or 'medical'=any(v_permissions) or 'payroll'=any(v_permissions) or 'roles'=any(v_permissions) then
  raise exception 'Board designation must preserve the member original module scope';
 end if;

 delete from public.schoolpro_board_members b where b.member_id=v_member_id;
 insert into public.schoolpro_member_permissions(school_id,member_id,permission,allowed,updated_by)
 values(v_school_id,v_member_id,'results',false,v_owner_id);
 if 'results'=any(public.schoolpro_user_permissions(v_school_id)) then raise exception 'Explicit deny ignored';end if;

 perform set_config('request.jwt.claim.sub','',true);
 if coalesce(cardinality(public.schoolpro_user_permissions(v_school_id)),0)<>0 then raise exception 'Anonymous permissions exposed';end if;
end $$;
rollback;
select 'PASS: role-specific modules, school isolation, Board designation, administrator scope and explicit denies' as result;
