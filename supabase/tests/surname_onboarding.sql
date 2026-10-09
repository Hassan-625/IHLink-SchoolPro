begin;
do $$
declare
 v_owner uuid:=gen_random_uuid(); v_staff uuid:=gen_random_uuid(); v_parent uuid:=gen_random_uuid(); v_wrong uuid:=gen_random_uuid();
 v_school uuid:=gen_random_uuid(); v_other uuid:=gen_random_uuid(); c1 uuid:=gen_random_uuid(); c2 uuid:=gen_random_uuid(); c3 uuid:=gen_random_uuid(); h text;
begin
 insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data)values
 (v_owner,'owner-'||v_owner||'@example.invalid','{}','{}'),(v_staff,'staff-'||v_staff||'@example.invalid','{}','{}'),
 (v_parent,'parent-'||v_parent||'@example.invalid','{}','{}'),(v_wrong,'wrong-'||v_wrong||'@example.invalid','{}','{}');
 insert into public.profiles(id,email)values
 (v_owner,'owner-'||v_owner||'@example.invalid'),(v_staff,'staff-'||v_staff||'@example.invalid'),
 (v_parent,'parent-'||v_parent||'@example.invalid'),(v_wrong,'wrong-'||v_wrong||'@example.invalid')on conflict(id)do nothing;
 insert into public.schoolpro_schools(id,owner_id,name,code)values(v_school,v_owner,'Synthetic onboarding test',v_school::text),(v_other,v_owner,'Synthetic other school',v_other::text);
 insert into public.schoolpro_students(id,school_id,admission_number,first_name,last_name,class_name)values
 (c1,v_school,'TEST1','Child','One','Testing'),(c2,v_school,'TEST2','Child','Two','Testing'),(c3,v_other,'TEST3','Child','Three','Testing');
 perform public.schoolpro_set_initial_credential(v_staff,v_school,'Adu');
 select surname_hash into h from public.schoolpro_initial_credentials where user_id=v_staff;
 if h='Adu' then raise exception 'Surname stored as plaintext';end if;
 if public.schoolpro_initial_challenge(v_staff,'wrong','bad')then raise exception 'Wrong surname accepted';end if;
 if not public.schoolpro_initial_challenge(v_staff,' ADU ','challenge')then raise exception 'Short surname rejected';end if;
 if public.schoolpro_consume_account_challenge(v_staff,'challenge','short')then raise exception 'Short new password accepted';end if;
 if not public.schoolpro_consume_account_challenge(v_staff,'challenge','ChosenPassword4826!')then raise exception 'Valid activation failed';end if;
 if public.schoolpro_consume_account_challenge(v_staff,'challenge','ChosenPassword4826!')then raise exception 'Challenge replay accepted';end if;
 perform public.schoolpro_set_initial_credential(v_parent,v_school,'LongSurname');
 if not public.schoolpro_initial_challenge(v_parent,'LongSurname','parent-challenge')then raise exception 'Parent challenge failed';end if;
 if public.schoolpro_consume_account_challenge(v_parent,'parent-challenge','LongSurname')then raise exception 'Surname reused as permanent password';end if;
 update public.schoolpro_account_challenges set expires_at=now()-interval '1 minute' where user_id=v_parent;
 if public.schoolpro_consume_account_challenge(v_parent,'parent-challenge','ChosenPassword4826!')then raise exception 'Expired challenge accepted';end if;
 insert into public.schoolpro_access_invitations(school_id,email,role,student_ids,token_hash,created_by)values(v_school,'parent-'||v_parent||'@example.invalid','parent',array[c1,c3],'invalid-children',v_owner);
 if public.schoolpro_accept_access_invitation(v_parent,'invalid-children')then raise exception 'Cross-school child linked';end if;
 if exists(select 1 from public.schoolpro_guardian_links where guardian_user_id=v_parent)then raise exception 'Partial child links leaked';end if;
 insert into public.schoolpro_access_invitations(school_id,email,role,student_ids,token_hash,created_by)values(v_school,'parent-'||v_parent||'@example.invalid','parent',array[c1,c2],'valid-parent',v_owner);
 if public.schoolpro_accept_access_invitation(v_wrong,'valid-parent')then raise exception 'Wrong account accepted code';end if;
 if not public.schoolpro_accept_access_invitation(v_parent,'valid-parent')then raise exception 'Multi-child linking failed';end if;
 if (select count(*) from public.schoolpro_guardian_links where guardian_user_id=v_parent)<>2 then raise exception 'Wrong linked child count';end if;
 if public.schoolpro_accept_access_invitation(v_parent,'valid-parent')then raise exception 'Invite replay accepted';end if;
 insert into public.schoolpro_access_invitations(school_id,email,role,token_hash,created_by)values(v_school,'staff-'||v_staff||'@example.invalid','teacher','valid-staff',v_owner);
 if not public.schoolpro_accept_access_invitation(v_staff,'valid-staff')then raise exception 'Staff linking failed';end if;
 if not exists(select 1 from public.schoolpro_members where school_id=v_school and user_id=v_staff and role='teacher')then raise exception 'Staff role missing';end if;
 if has_function_privilege('authenticated','public.schoolpro_initial_challenge(uuid,text,text)','execute')or has_function_privilege('anon','public.schoolpro_accept_access_invitation(uuid,text)','execute')or has_table_privilege('authenticated','public.schoolpro_initial_credentials','select')then raise exception 'Private credentials exposed';end if;
end $$;
select 'PASS: surname hashing, short surnames, new passwords, expiry/replay, identity-bound joining, multiple children, school isolation and permissions (fixtures rolled back)' as result;
rollback;
