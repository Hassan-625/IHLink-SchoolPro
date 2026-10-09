create or replace function public.schoolpro_join_school_code(p_user uuid,p_school_code text)
returns uuid language plpgsql security invoker set search_path='' as $$
declare sid uuid;invite_hash text;account_email text;
begin
 select id into sid from public.schoolpro_schools where upper(code)=upper(trim(p_school_code));
 if sid is null then return null;end if;
 select lower(email) into account_email from public.profiles where id=p_user and status='active';
 if account_email is null then return null;end if;
 if exists(select 1 from public.schoolpro_schools where id=sid and owner_id=p_user) or exists(select 1 from public.schoolpro_members where school_id=sid and user_id=p_user) or exists(select 1 from public.schoolpro_students where school_id=sid and user_id=p_user and status='active') or exists(select 1 from public.schoolpro_guardian_links where school_id=sid and guardian_user_id=p_user and status='active') then return sid;end if;
 select token_hash into invite_hash from public.schoolpro_access_invitations where school_id=sid and lower(email)=account_email and accepted_at is null and expires_at>now() order by expires_at desc limit 1;
 if invite_hash is not null and public.schoolpro_accept_access_invitation(p_user,invite_hash) then return sid;end if;
 return null;
end $$;
revoke all on function public.schoolpro_join_school_code(uuid,text) from public,anon,authenticated;
grant execute on function public.schoolpro_join_school_code(uuid,text) to service_role;

