-- Atomic profile corrections: profile/contact changes and audit entries commit together.
create or replace function public.schoolpro_correct_student_profile(
 p_school_id uuid, p_student_id uuid, p_next jsonb
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare old_row jsonb; new_row jsonb; changed text[];
begin
 if auth.uid() is null or not private.has_school_access(p_school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'registrar'::public.school_member_role]) then
   raise exception 'Not authorized to correct student profile';
 end if;
 select jsonb_build_object('first_name',first_name,'middle_name',middle_name,'last_name',last_name,'guardian_name',guardian_name,'guardian_phone',guardian_phone)
 into old_row from public.schoolpro_students where id=p_student_id and school_id=p_school_id for update;
 if old_row is null then raise exception 'Student not found in this school'; end if;
 if coalesce(trim(p_next->>'first_name'),'')='' or coalesce(trim(p_next->>'last_name'),'')='' then raise exception 'First name and surname are required'; end if;
 new_row:=jsonb_build_object('first_name',trim(p_next->>'first_name'),'middle_name',nullif(trim(coalesce(p_next->>'middle_name','')),''),'last_name',trim(p_next->>'last_name'),'guardian_name',nullif(trim(coalesce(p_next->>'guardian_name','')),''),'guardian_phone',nullif(trim(coalesce(p_next->>'guardian_phone','')),''));
 select coalesce(array_agg(key order by key),array[]::text[]) into changed from jsonb_each(new_row) n(key,value) where old_row->key is distinct from n.value;
 if cardinality(changed)=0 then return jsonb_build_object('changed',false); end if;
 update public.schoolpro_students set first_name=new_row->>'first_name',middle_name=new_row->>'middle_name',last_name=new_row->>'last_name',guardian_name=new_row->>'guardian_name',guardian_phone=new_row->>'guardian_phone' where id=p_student_id and school_id=p_school_id;
 insert into public.schoolpro_student_profile_audit(school_id,student_id,changed_by,changed_fields,before_values,after_values)
 values(p_school_id,p_student_id,auth.uid(),changed,old_row,new_row);
 return jsonb_build_object('changed',true,'fields',changed);
end $$;
-- Audit entries must only be created by the atomic correction function, never forged directly by clients.
drop policy if exists schoolpro_student_profile_audit_insert on public.schoolpro_student_profile_audit;
revoke insert on public.schoolpro_student_profile_audit from authenticated, anon, public;
revoke all on function public.schoolpro_correct_student_profile(uuid,uuid,jsonb) from public, anon;
grant execute on function public.schoolpro_correct_student_profile(uuid,uuid,jsonb) to authenticated;

create or replace function public.schoolpro_correct_member_profile_atomic(
 p_school_id uuid,p_target_user_id uuid,p_actor_id uuid,p_first_name text,p_middle_name text,p_last_name text,p_phone text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare school_owner uuid; actor_role text; global_role text; global_status text; before_profile jsonb; after_profile jsonb; guardian_before jsonb; fields text[];
begin
 if auth.role() <> 'service_role' then raise exception 'Service role required'; end if;
 select owner_id into school_owner from public.schoolpro_schools where id=p_school_id;
 if school_owner is null then raise exception 'School not found'; end if;
 select role into actor_role from public.schoolpro_members where school_id=p_school_id and user_id=p_actor_id;
 select role,status into global_role,global_status from public.profiles where id=p_actor_id;
 if not (school_owner=p_actor_id or actor_role in ('proprietor','administrator') or (global_role='super_admin' and global_status='active')) then raise exception 'Not authorized for this school'; end if;
 if not exists(select 1 from public.schoolpro_members where school_id=p_school_id and user_id=p_target_user_id)
    and not exists(select 1 from public.schoolpro_guardian_links where school_id=p_school_id and guardian_user_id=p_target_user_id) then
   raise exception 'Target account is not linked to this school';
 end if;
 if coalesce(trim(p_first_name),'')='' or coalesce(trim(p_last_name),'')='' then raise exception 'First name and surname are required'; end if;
 select jsonb_build_object('first_name',first_name,'middle_name',middle_name,'last_name',last_name,'email',email,'phone',phone)
 into before_profile from public.profiles where id=p_target_user_id for update;
 if before_profile is null then raise exception 'Profile not found'; end if;
 select jsonb_build_object('phone',phone) into guardian_before from public.schoolpro_guardian_links where school_id=p_school_id and guardian_user_id=p_target_user_id order by id limit 1 for update;
 after_profile:=jsonb_build_object('first_name',trim(p_first_name),'middle_name',nullif(trim(coalesce(p_middle_name,'')),''),'last_name',trim(p_last_name),'email',before_profile->'email','phone',nullif(trim(coalesce(p_phone,'')),''));
 select coalesce(array_agg(k order by k),array[]::text[]) into fields from jsonb_each(after_profile) n(k,v) where before_profile->k is distinct from n.v;
 if cardinality(fields)>0 then
   update public.profiles set first_name=after_profile->>'first_name',middle_name=after_profile->>'middle_name',last_name=after_profile->>'last_name',phone=after_profile->>'phone' where id=p_target_user_id;
   update public.schoolpro_guardian_links set phone=after_profile->>'phone' where school_id=p_school_id and guardian_user_id=p_target_user_id;
   insert into public.schoolpro_profile_change_audit(school_id,target_user_id,changed_by,changed_fields,before_values,after_values)
   values(p_school_id,p_target_user_id,p_actor_id,fields,before_profile,after_profile);
 end if;
 return jsonb_build_object('changed',cardinality(fields)>0,'fields',fields);
end $$;
revoke all on function public.schoolpro_correct_member_profile_atomic(uuid,uuid,uuid,text,text,text,text) from public, anon, authenticated;
grant execute on function public.schoolpro_correct_member_profile_atomic(uuid,uuid,uuid,text,text,text,text) to service_role;
