-- Promote one selected historical subject record through an audited,
-- school-admin-only RPC. Browser clients must not update catalogue markers.
create table if not exists public.schoolpro_subject_catalogue_promotion_audit (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  subject_id uuid not null references public.schoolpro_subjects(id) on delete restrict,
  subject_name text not null,
  subject_code text,
  promoted_by uuid not null references public.profiles(id),
  promoted_at timestamptz not null default now()
);
create index if not exists schoolpro_subject_catalogue_promotion_audit_scope_idx
  on public.schoolpro_subject_catalogue_promotion_audit(school_id,promoted_at desc);
alter table public.schoolpro_subject_catalogue_promotion_audit enable row level security;
drop policy if exists schoolpro_subject_catalogue_promotion_audit_read
  on public.schoolpro_subject_catalogue_promotion_audit;
create policy schoolpro_subject_catalogue_promotion_audit_read
  on public.schoolpro_subject_catalogue_promotion_audit for select to authenticated
  using (private.has_school_access(school_id));
revoke all on public.schoolpro_subject_catalogue_promotion_audit from public,anon,authenticated;
grant select on public.schoolpro_subject_catalogue_promotion_audit to authenticated;

create or replace function public.schoolpro_promote_legacy_subject_to_catalogue(
  p_school uuid,
  p_subject uuid
) returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_subject public.schoolpro_subjects%rowtype;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.has_school_access(p_school, ARRAY['proprietor','administrator']::public.school_member_role[]) then
    raise exception 'Only an active school administrator can resolve a historical subject';
  end if;

  select s.* into v_subject
  from public.schoolpro_subjects s
  where s.school_id=p_school and s.id=p_subject
  for update;

  if not found then
    raise exception 'The selected historical subject was not found in this school';
  end if;
  if v_subject.is_catalogue_entry then
    return v_subject.id;
  end if;

  if exists (
    select 1
    from public.schoolpro_subjects existing
    where existing.school_id=p_school
      and existing.id<>p_subject
      and existing.is_catalogue_entry
      and lower(regexp_replace(btrim(existing.name), '\s+', ' ', 'g'))
        = lower(regexp_replace(btrim(v_subject.name), '\s+', ' ', 'g'))
  ) then
    raise exception 'A canonical subject with this name already exists. Allocate that existing catalogue record instead';
  end if;

  update public.schoolpro_subjects
  set is_catalogue_entry=true
  where school_id=p_school and id=p_subject and is_catalogue_entry=false;

  if not found then
    raise exception 'The historical subject changed while it was being resolved. Refresh and try again';
  end if;

  insert into public.schoolpro_subject_catalogue_promotion_audit(
    school_id,subject_id,subject_name,subject_code,promoted_by
  ) values (p_school,v_subject.id,v_subject.name,v_subject.code,auth.uid());

  return v_subject.id;
end;
$$;
revoke all on function public.schoolpro_promote_legacy_subject_to_catalogue(uuid,uuid) from public,anon;
grant execute on function public.schoolpro_promote_legacy_subject_to_catalogue(uuid,uuid) to authenticated;
