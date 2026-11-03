-- Production graduation-certificate issuance.
-- Keeps the synthetic testing-certificate worker and finalizer isolated.

create or replace function private.validate_schoolpro_graduation_certificate_issue()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_student public.schoolpro_students;
  v_template public.schoolpro_document_templates;
begin
  if new.document_type <> 'certificate' then
    return new;
  end if;

  -- Once a certificate has left draft, the existing lifecycle controls own it.
  if tg_op = 'UPDATE' and old.status <> 'draft' then
    return new;
  end if;

  if tg_op = 'INSERT' and new.status <> 'draft' then
    raise exception 'A certificate must begin as a draft';
  end if;

  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if new.student_id is null or new.template_id is null then
    raise exception 'A student and certificate template are required';
  end if;

  select * into v_student
  from public.schoolpro_students
  where id = new.student_id and school_id = new.school_id
  for share;

  if v_student.id is null or v_student.status <> 'graduated' then
    raise exception 'Only graduated students are eligible for a certificate';
  end if;

  select * into v_template
  from public.schoolpro_document_templates
  where id = new.template_id
    and school_id = new.school_id
    and document_type = 'certificate'
    and is_active = true;

  if v_template.id is null then
    raise exception 'Choose an active certificate template belonging to this school';
  end if;

  if trim(coalesce(new.payload->>'session','')) = '' then
    raise exception 'The graduation session is required';
  end if;

  if not exists (
    select 1
    from public.schoolpro_promotions p
    where p.school_id = new.school_id
      and p.student_id = new.student_id
      and p.session = trim(new.payload->>'session')
      and p.decision = 'graduated'
      and p.status = 'applied'
  ) then
    raise exception 'An applied graduation decision is required for the selected session';
  end if;

  if not (
    private.is_admin(array['super_admin']::public.user_role[])
    or public.schoolpro_member_can_manage(new.school_id)
    or exists (
      select 1 from public.schoolpro_members m
      where m.school_id = new.school_id
        and m.user_id = auth.uid()
        and m.role::text in ('registrar','head_teacher','vice_principal')
    )
  ) then
    raise exception 'Not authorized to issue graduation certificates';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_schoolpro_graduation_certificate_issue() from public, anon, authenticated;

drop trigger if exists trg_schoolpro_graduation_certificate_issue
  on public.schoolpro_document_issues;
create trigger trg_schoolpro_graduation_certificate_issue
before insert or update of school_id, template_id, student_id, document_type, payload, status
on public.schoolpro_document_issues
for each row execute function private.validate_schoolpro_graduation_certificate_issue();

-- Recheck eligibility at the irreversible draft -> issued transition.
-- Preserve generic document issuance and the existing immutable issue-event log.
create or replace function public.finalize_schoolpro_document_issue(
  p_issue uuid,
  p_output_path text
)
returns void
language plpgsql
security definer
set search_path=''
as $$
declare
  i public.schoolpro_document_issues;
  s public.schoolpro_students;
  t public.schoolpro_document_templates;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into i
  from public.schoolpro_document_issues
  where id = p_issue
  for update;

  if i.id is null then raise exception 'Document not found'; end if;
  if i.status <> 'draft' then raise exception 'Only draft documents can be issued'; end if;
  if trim(coalesce(p_output_path,'')) = ''
     or p_output_path not like i.school_id::text || '/generated/%' then
    raise exception 'Invalid output path';
  end if;

  if not (
    private.is_admin(array['super_admin']::public.user_role[])
    or public.schoolpro_member_can_manage(i.school_id)
    or exists (
      select 1 from public.schoolpro_members m
      where m.school_id = i.school_id
        and m.user_id = auth.uid()
        and m.role::text in ('registrar','head_teacher','vice_principal')
    )
  ) then
    raise exception 'Not authorized';
  end if;

  if i.document_type = 'certificate' then
    select * into s
    from public.schoolpro_students
    where id = i.student_id and school_id = i.school_id
    for share;

    if s.id is null or s.status <> 'graduated' then
      raise exception 'Only graduated students are eligible for a certificate';
    end if;

    select * into t
    from public.schoolpro_document_templates
    where id = i.template_id
      and school_id = i.school_id
      and document_type = 'certificate'
      and is_active = true;

    if t.id is null then
      raise exception 'The certificate template is no longer active';
    end if;

    if trim(coalesce(i.payload->>'session','')) = ''
       or not exists (
         select 1 from public.schoolpro_promotions p
         where p.school_id = i.school_id
           and p.student_id = i.student_id
           and p.session = trim(i.payload->>'session')
           and p.decision = 'graduated'
           and p.status = 'applied'
       ) then
      raise exception 'An applied graduation decision is required for the selected session';
    end if;
  end if;

  perform set_config('ihlink.document_lifecycle_rpc','on',true);
  update public.schoolpro_document_issues
  set status='issued',
      output_storage_path=p_output_path,
      issued_at=now(),
      issued_by=auth.uid()
  where id=i.id;

  insert into public.schoolpro_document_issue_events(
    school_id, issue_id, event_type, actor_id, snapshot
  )
  select school_id, id, 'issued', auth.uid(), to_jsonb(x)
  from public.schoolpro_document_issues x
  where id=i.id;
end;
$$;

revoke all on function public.finalize_schoolpro_document_issue(uuid,text) from public, anon;
grant execute on function public.finalize_schoolpro_document_issue(uuid,text) to authenticated, service_role;
