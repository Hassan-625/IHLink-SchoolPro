begin;

-- Store guardian contact numbers per school/student relationship instead of
-- assuming a global account phone is always populated or appropriate.
alter table public.schoolpro_guardian_links
  add column if not exists phone text;

alter table public.schoolpro_access_invitations
  add column if not exists guardian_phone text;

create or replace function public.schoolpro_accept_access_invitation(p_user uuid, p_hash text)
returns boolean
language plpgsql
set search_path to ''
as $function$
declare
  invitation public.schoolpro_access_invitations;
  uid_email text;
  sid uuid;
begin
  select lower(email) into uid_email
  from public.profiles
  where id = p_user and status = 'active';

  select * into invitation
  from public.schoolpro_access_invitations
  where token_hash = p_hash
    and email = uid_email
    and expires_at > now()
    and accepted_at is null
  for update;

  if invitation.id is null then
    return false;
  end if;

  if invitation.role = 'parent' then
    if cardinality(invitation.student_ids) = 0 then
      return false;
    end if;

    foreach sid in array invitation.student_ids loop
      if not exists (
        select 1 from public.schoolpro_students
        where id = sid
          and school_id = invitation.school_id
          and status = 'active'
      ) then
        return false;
      end if;
    end loop;

    foreach sid in array invitation.student_ids loop
      insert into public.schoolpro_guardian_links
        (school_id, student_id, guardian_user_id, relationship, phone, status, linked_by)
      values
        (invitation.school_id, sid, p_user, invitation.relationship,
         nullif(trim(invitation.guardian_phone), ''), 'active', invitation.created_by)
      on conflict (student_id, guardian_user_id)
      do update set
        status = 'active',
        relationship = excluded.relationship,
        phone = coalesce(excluded.phone, public.schoolpro_guardian_links.phone);
    end loop;
  else
    insert into public.schoolpro_members (school_id, user_id, role)
    values (invitation.school_id, p_user, invitation.role::public.school_member_role)
    on conflict (school_id, user_id) do nothing;
  end if;

  update public.schoolpro_access_invitations
  set accepted_at = now()
  where id = invitation.id;

  return true;
end;
$function$;

commit;
