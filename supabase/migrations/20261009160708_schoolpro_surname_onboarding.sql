create table public.schoolpro_initial_credentials(
 user_id uuid primary key references public.profiles(id) on delete cascade,
 school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 surname_hash text not null,
 expires_at timestamptz not null default now()+interval '7 days',
 consumed_at timestamptz
);
create table public.schoolpro_account_challenges(
 token_hash text primary key,
 user_id uuid not null references public.schoolpro_initial_credentials(user_id) on delete cascade,
 expires_at timestamptz not null default now()+interval '10 minutes'
);
create table public.schoolpro_access_invitations(
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 email text not null, role text not null check(role in ('administrator','teacher','accountant','parent')),
 student_ids uuid[] not null default '{}', relationship text not null default 'guardian',
 token_hash text unique not null, created_by uuid not null references public.profiles(id),
 expires_at timestamptz not null default now()+interval '7 days', accepted_at timestamptz
);
alter table public.schoolpro_initial_credentials enable row level security;
alter table public.schoolpro_account_challenges enable row level security;
alter table public.schoolpro_access_invitations enable row level security;
revoke all on public.schoolpro_initial_credentials,public.schoolpro_account_challenges,public.schoolpro_access_invitations from public,anon,authenticated;
grant all on public.schoolpro_initial_credentials,public.schoolpro_account_challenges,public.schoolpro_access_invitations to service_role;

create function public.schoolpro_set_initial_credential(p_user uuid,p_school uuid,p_surname text) returns void
language plpgsql security invoker set search_path='' as $$
begin
 if p_surname is null or length(trim(p_surname))<1 or length(p_surname)>100 then raise exception 'Invalid surname';end if;
 insert into public.schoolpro_initial_credentials(user_id,school_id,surname_hash)
 values(p_user,p_school,extensions.crypt(lower(trim(p_surname)),extensions.gen_salt('bf')));
end $$;
create function public.schoolpro_initial_challenge(p_user uuid,p_surname text,p_hash text) returns boolean
language plpgsql security invoker set search_path='' as $$
declare credential public.schoolpro_initial_credentials;
begin
 select * into credential from public.schoolpro_initial_credentials where user_id=p_user and expires_at>now() and consumed_at is null for update;
 if credential.user_id is null or extensions.crypt(lower(trim(coalesce(p_surname,''))),credential.surname_hash)<>credential.surname_hash then return false;end if;
 delete from public.schoolpro_account_challenges where user_id=p_user;
 insert into public.schoolpro_account_challenges(token_hash,user_id) values(p_hash,p_user);
 return true;
end $$;
create function public.schoolpro_consume_account_challenge(p_user uuid,p_hash text,p_password text) returns boolean
language plpgsql security invoker set search_path='' as $$
declare credential public.schoolpro_initial_credentials;
begin
 select * into credential from public.schoolpro_initial_credentials where user_id=p_user and expires_at>now() and consumed_at is null for update;
 if credential.user_id is null or length(p_password)<10 or extensions.crypt(lower(trim(p_password)),credential.surname_hash)=credential.surname_hash then return false;end if;
 if not exists(select 1 from public.schoolpro_account_challenges where user_id=p_user and token_hash=p_hash and expires_at>now())then return false;end if;
 delete from public.schoolpro_account_challenges where user_id=p_user;
 update public.schoolpro_initial_credentials set consumed_at=now() where user_id=p_user;
 return true;
end $$;
create function public.schoolpro_accept_access_invitation(p_user uuid,p_hash text) returns boolean
language plpgsql security invoker set search_path='' as $$
declare invitation public.schoolpro_access_invitations; uid_email text; sid uuid;
begin
 select lower(email) into uid_email from public.profiles where id=p_user and status='active';
 select * into invitation from public.schoolpro_access_invitations where token_hash=p_hash and email=uid_email and expires_at>now() and accepted_at is null for update;
 if invitation.id is null then return false;end if;
 if invitation.role='parent' then
  if cardinality(invitation.student_ids)=0 then return false;end if;
  foreach sid in array invitation.student_ids loop
   if not exists(select 1 from public.schoolpro_students where id=sid and school_id=invitation.school_id and status='active')then return false;end if;
  end loop;
  foreach sid in array invitation.student_ids loop
   insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,relationship,status,linked_by)
   values(invitation.school_id,sid,p_user,invitation.relationship,'active',invitation.created_by)
   on conflict(student_id,guardian_user_id) do update set status='active',relationship=excluded.relationship;
  end loop;
 else
  insert into public.schoolpro_members(school_id,user_id,role)values(invitation.school_id,p_user,invitation.role::public.school_member_role)on conflict(school_id,user_id)do nothing;
 end if;
 update public.schoolpro_access_invitations set accepted_at=now() where id=invitation.id;
 return true;
end $$;
revoke all on function public.schoolpro_set_initial_credential(uuid,uuid,text),public.schoolpro_initial_challenge(uuid,text,text),public.schoolpro_consume_account_challenge(uuid,text,text),public.schoolpro_accept_access_invitation(uuid,text) from public,anon,authenticated;
grant execute on function public.schoolpro_set_initial_credential(uuid,uuid,text),public.schoolpro_initial_challenge(uuid,text,text),public.schoolpro_consume_account_challenge(uuid,text,text),public.schoolpro_accept_access_invitation(uuid,text) to service_role;
