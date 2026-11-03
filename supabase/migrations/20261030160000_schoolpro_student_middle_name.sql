-- Stage B: preserve a student's full legal/display name independently of a linked profile.
alter table public.schoolpro_students
  add column if not exists middle_name text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.schoolpro_students'::regclass
      and conname = 'schoolpro_students_middle_name_length_check'
  ) then
    alter table public.schoolpro_students
      add constraint schoolpro_students_middle_name_length_check
      check (middle_name is null or char_length(btrim(middle_name)) <= 100);
  end if;
end;
$$;
