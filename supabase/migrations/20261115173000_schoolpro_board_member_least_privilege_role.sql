-- Add a dedicated least-privilege membership role for Board appointees.
-- Board appointments remain separate governance records; this role grants
-- only dashboard/notification access through the permission resolver's default.
begin;

alter type public.school_member_role add value if not exists 'board_member';

alter table public.schoolpro_access_invitations
  drop constraint if exists schoolpro_access_invitations_role_check;

alter table public.schoolpro_access_invitations
  add constraint schoolpro_access_invitations_role_check
  check (role = any (array[
    'administrator','teacher','class_teacher','head_teacher','vice_principal',
    'bursar','accountant','registrar','admissions_officer','exam_officer',
    'librarian','counsellor','nurse','hostel_manager','transport_manager',
    'inventory_officer','hr_officer','receptionist','it_admin','board_member',
    'parent'
  ]::text[]));

commit;
