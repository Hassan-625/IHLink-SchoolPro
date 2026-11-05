-- A Form Master assignment is an active classroom responsibility, not a permanent
-- entitlement. Clear it when the member leaves the eligible teaching roles.
-- Subject allocations are intentionally retained for historical result attribution.

create or replace function private.schoolpro_clear_ineligible_form_master()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.role in ('teacher','class_teacher')
     and new.role not in ('teacher','class_teacher') then
    update public.schoolpro_classes
       set form_teacher_id = null
     where school_id = new.school_id
       and form_teacher_id = new.id;
  end if;
  return new;
end;
$$;

revoke all on function private.schoolpro_clear_ineligible_form_master()
  from public, anon, authenticated;

drop trigger if exists schoolpro_clear_ineligible_form_master
  on public.schoolpro_members;

create trigger schoolpro_clear_ineligible_form_master
after update of role on public.schoolpro_members
for each row
execute function private.schoolpro_clear_ineligible_form_master();
