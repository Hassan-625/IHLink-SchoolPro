-- Add the two requested built-in school staff roles.
-- Apply to production only after reviewing and explicitly approving this migration.
alter type public.school_member_role add value if not exists 'discipline_master';
alter type public.school_member_role add value if not exists 'game_master';

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
      'discipline_master',
      'game_master',
      'parent'
    ]::text[])
  );
