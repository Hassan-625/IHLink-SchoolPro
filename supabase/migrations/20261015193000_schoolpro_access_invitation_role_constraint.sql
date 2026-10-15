begin;

-- Keep the invitation role constraint aligned with the staff-role selector and
-- the school_member_role enum. Previously only administrator, teacher,
-- accountant, and parent were accepted, so most valid UI roles failed with
-- SQLSTATE 23514 before the invitation could be linked.
alter table public.schoolpro_access_invitations
  drop constraint if exists schoolpro_access_invitations_role_check;

alter table public.schoolpro_access_invitations
  add constraint schoolpro_access_invitations_role_check
  check (
    role = any (array[
      'administrator',
      'teacher',
      'class_teacher',
      'head_teacher',
      'vice_principal',
      'bursar',
      'accountant',
      'registrar',
      'admissions_officer',
      'exam_officer',
      'librarian',
      'counsellor',
      'nurse',
      'hostel_manager',
      'transport_manager',
      'inventory_officer',
      'hr_officer',
      'receptionist',
      'it_admin',
      'parent'
    ]::text[])
  );

commit;
