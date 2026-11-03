-- Align subject-assignment write validation with the teaching-role contract.
-- The original trigger admitted proprietor/administrator but rejected class_teacher,
-- while the assignment UI intentionally offers teacher and class_teacher only.
create or replace function private.validate_subject_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  class_school uuid;
  subject_school uuid;
  member_school uuid;
  member_role public.school_member_role;
begin
  select school_id into class_school
  from public.schoolpro_classes
  where id = new.class_id;

  select school_id into subject_school
  from public.schoolpro_subjects
  where id = new.subject_id;

  if class_school is null
     or subject_school is null
     or class_school <> new.school_id
     or subject_school <> new.school_id then
    raise exception 'Class and subject must belong to the selected school';
  end if;

  if new.teacher_member_id is not null then
    select school_id, role
      into member_school, member_role
    from public.schoolpro_members
    where id = new.teacher_member_id;

    if member_school is null
       or member_school <> new.school_id
       or member_role not in ('teacher', 'class_teacher') then
      raise exception 'Assigned teacher must be an eligible teaching member of this school';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.validate_subject_assignment()
  from public, anon, authenticated;
