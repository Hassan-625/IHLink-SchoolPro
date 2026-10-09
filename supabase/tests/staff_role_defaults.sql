begin;
do $$
declare owner_id uuid:=gen_random_uuid(); staff_id uuid:=gen_random_uuid(); school_id uuid:=gen_random_uuid(); other_school uuid:=gen_random_uuid(); member_id uuid:=gen_random_uuid(); permissions text[]; role_name text;
begin
 insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
 values(owner_id,'authenticated','authenticated','owner-'||owner_id||'@example.invalid','{}','{"first_name":"Owner","middle_name":"Fixture","last_name":"Test"}',now(),now()),
 (staff_id,'authenticated','authenticated','staff-'||staff_id||'@example.invalid','{}','{"first_name":"Staff","middle_name":"Fixture","last_name":"Test"}',now(),now());
 insert into public.schoolpro_schools(id,owner_id,name,code) values(school_id,owner_id,'Role test','ROLE-'||school_id),(other_school,owner_id,'Other role test','ROLE-'||other_school);
 insert into public.schoolpro_members(id,school_id,user_id,role)values(member_id,school_id,staff_id,'head_teacher');
 perform set_config('request.jwt.claim.sub',staff_id::text,true);
 foreach role_name in array array['head_teacher','vice_principal'] loop
  update public.schoolpro_members set role=role_name::public.school_member_role where id=member_id;
  permissions:=public.schoolpro_user_permissions(school_id);
  if not ('results'=any(permissions)) or 'finance'=any(permissions) or 'staff'=any(permissions) then raise exception 'Academic role scope failed';end if;
 end loop;
 update public.schoolpro_members set role='counsellor' where id=member_id;
 permissions:=public.schoolpro_user_permissions(school_id);
 if not ('discipline'=any(permissions)) or 'results'=any(permissions) then raise exception 'Counsellor scope failed';end if;
 update public.schoolpro_members set role='receptionist' where id=member_id;
 permissions:=public.schoolpro_user_permissions(school_id);
 if not ('admissions'=any(permissions)) or 'finance'=any(permissions) then raise exception 'Receptionist scope failed';end if;
 if coalesce(cardinality(public.schoolpro_user_permissions(other_school)),0)<>0 then raise exception 'Cross-school permissions exposed';end if;
 update public.schoolpro_members set role='head_teacher' where id=member_id;
 insert into public.schoolpro_member_permissions(school_id,member_id,permission,allowed,updated_by) values(school_id,member_id,'results',false,owner_id);
 if 'results'=any(public.schoolpro_user_permissions(school_id)) then raise exception 'Explicit deny ignored';end if;
 perform set_config('request.jwt.claim.sub','',true);
 if coalesce(cardinality(public.schoolpro_user_permissions(school_id)),0)<>0 then raise exception 'Anonymous permissions exposed';end if;
end $$;
rollback;
select 'PASS: academic and support roles, cross-school isolation, anonymous rejection and explicit denies' as result;
