-- Forward-only repair for cross-tenant relational integrity in operational records.
-- This migration intentionally does not change RLS policies or migration history.
-- Apply only after review and successful validation in a non-production environment.

create or replace function private.schoolpro_validate_operational_tenant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  ref_school uuid;
begin
  if tg_table_name = 'schoolpro_lesson_notes' then
    if new.subject_id is not null then
      select school_id into ref_school
      from public.schoolpro_subjects where id = new.subject_id for share;
      if ref_school is distinct from new.school_id then
        raise exception 'Subject belongs to another school';
      end if;
    end if;

    if new.class_id is not null then
      select school_id into ref_school
      from public.schoolpro_classes where id = new.class_id for share;
      if ref_school is distinct from new.school_id then
        raise exception 'Class belongs to another school';
      end if;
    end if;

  elsif tg_table_name = 'schoolpro_result_approvals' then
    select school_id into ref_school
    from public.schoolpro_results where id = new.result_id for share;
    if ref_school is distinct from new.school_id then
      raise exception 'Result belongs to another school';
    end if;

  elsif tg_table_name = 'schoolpro_promotions' then
    select school_id into ref_school
    from public.schoolpro_students where id = new.student_id for share;
    if ref_school is distinct from new.school_id then
      raise exception 'Student belongs to another school';
    end if;

    if new.from_class_id is not null then
      select school_id into ref_school
      from public.schoolpro_classes where id = new.from_class_id for share;
      if ref_school is distinct from new.school_id then
        raise exception 'Source class belongs to another school';
      end if;
    end if;

    if new.to_class_id is not null then
      select school_id into ref_school
      from public.schoolpro_classes where id = new.to_class_id for share;
      if ref_school is distinct from new.school_id then
        raise exception 'Destination class belongs to another school';
      end if;
    end if;

  -- Prevent later school reassignment of referenced parent rows from silently
  -- invalidating child tenant relationships already accepted by the guards above.
  elsif tg_table_name = 'schoolpro_subjects' then
    if exists (
      select 1 from public.schoolpro_lesson_notes ln
      where ln.subject_id = new.id and ln.school_id is distinct from new.school_id
    ) then
      raise exception 'Subject school change would invalidate lesson-note tenant scope';
    end if;

  elsif tg_table_name = 'schoolpro_classes' then
    if exists (
      select 1 from public.schoolpro_lesson_notes ln
      where ln.class_id = new.id and ln.school_id is distinct from new.school_id
    ) or exists (
      select 1 from public.schoolpro_promotions p
      where (p.from_class_id = new.id or p.to_class_id = new.id)
        and p.school_id is distinct from new.school_id
    ) or exists (
      select 1 from public.schoolpro_students s
      where s.class_id = new.id and s.school_id is distinct from new.school_id
    ) then
      raise exception 'Class school change would invalidate operational tenant scope';
    end if;

  elsif tg_table_name = 'schoolpro_students' then
    if exists (
      select 1 from public.schoolpro_promotions p
      where p.student_id = new.id and p.school_id is distinct from new.school_id
    ) then
      raise exception 'Student school change would invalidate promotion tenant scope';
    end if;

  elsif tg_table_name = 'schoolpro_results' then
    if exists (
      select 1 from public.schoolpro_result_approvals a
      where a.result_id = new.id and a.school_id is distinct from new.school_id
    ) then
      raise exception 'Result school change would invalidate approval tenant scope';
    end if;

  elsif tg_table_name = 'schoolpro_members' then
    if exists (
      select 1 from public.schoolpro_member_permissions mp
      where mp.member_id = new.id and mp.school_id is distinct from new.school_id
    ) then
      raise exception 'Member school change would invalidate permission tenant scope';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.schoolpro_validate_operational_tenant()
  from public, anon, authenticated;

drop trigger if exists validate_schoolpro_lesson_notes_tenant
  on public.schoolpro_lesson_notes;
create trigger validate_schoolpro_lesson_notes_tenant
before insert or update on public.schoolpro_lesson_notes
for each row execute function private.schoolpro_validate_operational_tenant();

drop trigger if exists validate_schoolpro_result_approvals_tenant
  on public.schoolpro_result_approvals;
create trigger validate_schoolpro_result_approvals_tenant
before insert or update on public.schoolpro_result_approvals
for each row execute function private.schoolpro_validate_operational_tenant();

drop trigger if exists validate_schoolpro_promotions_tenant
  on public.schoolpro_promotions;
create trigger validate_schoolpro_promotions_tenant
before insert or update on public.schoolpro_promotions
for each row execute function private.schoolpro_validate_operational_tenant();


drop trigger if exists validate_schoolpro_subjects_tenant on public.schoolpro_subjects;
create trigger validate_schoolpro_subjects_tenant before update of school_id on public.schoolpro_subjects
for each row execute function private.schoolpro_validate_operational_tenant();

drop trigger if exists validate_schoolpro_classes_tenant on public.schoolpro_classes;
create trigger validate_schoolpro_classes_tenant before update of school_id on public.schoolpro_classes
for each row execute function private.schoolpro_validate_operational_tenant();

drop trigger if exists validate_schoolpro_students_tenant on public.schoolpro_students;
create trigger validate_schoolpro_students_tenant before update of school_id on public.schoolpro_students
for each row execute function private.schoolpro_validate_operational_tenant();

drop trigger if exists validate_schoolpro_results_tenant on public.schoolpro_results;
create trigger validate_schoolpro_results_tenant before update of school_id on public.schoolpro_results
for each row execute function private.schoolpro_validate_operational_tenant();

drop trigger if exists validate_schoolpro_members_tenant on public.schoolpro_members;
create trigger validate_schoolpro_members_tenant before update of school_id on public.schoolpro_members
for each row execute function private.schoolpro_validate_operational_tenant();

-- The school and member foreign keys are individually valid but do not prove
-- that the referenced member belongs to the same school as the permission row.
create or replace function private.validate_schoolpro_member_permission_tenant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  member_school uuid;
begin
  select school_id into member_school
  from public.schoolpro_members where id = new.member_id for share;

  if member_school is null or member_school is distinct from new.school_id then
    raise exception 'Permission member belongs to another school';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_schoolpro_member_permission_tenant()
  from public, anon, authenticated;

drop trigger if exists validate_schoolpro_member_permission_tenant
  on public.schoolpro_member_permissions;
create trigger validate_schoolpro_member_permission_tenant
before insert or update of school_id, member_id
on public.schoolpro_member_permissions
for each row execute function private.validate_schoolpro_member_permission_tenant();
