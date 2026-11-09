-- Allow schools onboarding students who were already enrolled before first using SchoolPro.
-- This is distinct from a new admission and from a transfer-in admission.
alter table public.schoolpro_students
  drop constraint if exists schoolpro_students_admission_type_check;

alter table public.schoolpro_students
  add constraint schoolpro_students_admission_type_check
  check (admission_type in ('new', 'existing', 'transfer_in'));
