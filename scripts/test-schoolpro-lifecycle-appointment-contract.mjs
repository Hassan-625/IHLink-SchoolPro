import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const suspension=readFileSync('supabase/migrations/20261107180000_schoolpro_end_appointments_on_suspension.sql','utf8');
const readers=readFileSync('supabase/migrations/20261107183000_schoolpro_ended_appointment_access_guards.sql','utf8');
const staff=readFileSync('src/pages/schoolpro/SchoolProStaff.tsx','utf8');
const governance=readFileSync('src/components/SchoolGovernanceCard.tsx','utf8');

for (const table of [
  'schoolpro_house_master_assignments',
  'schoolpro_competition_judges',
  'schoolpro_board_members',
  'schoolpro_section_leaders',
  'schoolpro_subject_assignments',
]) {
  assert.match(suspension,new RegExp('update public\\\\.'+table+'\\\\s+set ended_at'),`Suspension must end active ${table} appointments.`);
}
assert.match(suspension,/form_teacher_id=null/,'Suspension must clear the active Form Master pointer.');
assert.match(suspension,/Form Master appointment ended/,'Former Form Master assignments must be auditable.');
assert.match(suspension,/appointments_restored',false/,'Reactivation must not silently restore previous appointments.');
assert.doesNotMatch(suspension,/delete from public\\.schoolpro_(board_members|section_leaders|subject_assignments)/,'Appointment history must not be hard-deleted.');

for (const fn of [
  'schoolpro_member_leads_class',
  'schoolpro_member_leads_student_section',
  'schoolpro_can_read_student',
  'schoolpro_can_write_result',
  'schoolpro_lesson_author_scope',
  'schoolpro_lesson_leader',
  'schoolpro_house_master_roster',
  'schoolpro_is_house_master',
]) {
  assert.match(readers,new RegExp('function private\\\\.'+fn+'\\\\('),`Expected updated helper ${fn}.`);
}
assert.match(readers,/sl\\.ended_at is null/,'Ended section leadership must not grant access.');
assert.match(readers,/a\\.ended_at is null/,'Ended subject and House Master appointments must not grant access.');
assert.match(readers,/m\\.status='active'/,'Membership-derived access must require an active membership.');
assert.match(readers,/c\\.archived_at is null/,'Archived classes must not grant current operational access.');

assert.match(staff,/status:"active"\\|"suspended"/,'Staff UI must load membership lifecycle state.');
assert.match(staff,/is\\("ended_at",null\\)/,'Staff UI must hide ended section and subject assignments.');
assert.match(staff,/is\\("archived_at",null\\)/,'Staff UI must hide archived classes from current responsibilities.');
assert.match(staff,/member\\.status==="suspended"\\?"Suspended":"Active"/,'Staff UI must show the real membership status.');
assert.match(governance,/is\\('ended_at',null\\)/,'Board UI must show only current appointments.');
assert.match(governance,/m\\.status!=='suspended'/,'Suspended staff must not be offered for new board appointments.');

console.log('PASS: SchoolPro appointment termination and active-reader contract.');
