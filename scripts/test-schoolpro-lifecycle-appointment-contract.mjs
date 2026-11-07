import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const suspension=readFileSync('supabase/migrations/20261107180000_schoolpro_end_appointments_on_suspension.sql','utf8');
const readers=readFileSync('supabase/migrations/20261107183000_schoolpro_ended_appointment_access_guards.sql','utf8');
const history=readFileSync('supabase/migrations/20261107190000_schoolpro_staff_appointment_history.sql','utf8');
const staff=readFileSync('src/pages/schoolpro/SchoolProStaff.tsx','utf8');
const governance=readFileSync('src/components/SchoolGovernanceCard.tsx','utf8');

for (const table of [
  'schoolpro_house_master_assignments',
  'schoolpro_competition_judges',
  'schoolpro_board_members',
  'schoolpro_section_leaders',
  'schoolpro_subject_assignments',
]) {
  assert.ok(suspension.includes('update public.'+table),`Suspension must end active ${table} appointments.`);
}
assert.ok(suspension.includes('form_teacher_id=null'),'Suspension must clear the active Form Master pointer.');
assert.ok(suspension.includes('Form Master appointment ended'),'Former Form Master assignments must be auditable.');
assert.ok(suspension.includes("'appointments_restored',false"),'Reactivation must not silently restore previous appointments.');
for (const table of ['schoolpro_board_members','schoolpro_section_leaders','schoolpro_subject_assignments']) {
  assert.ok(!suspension.includes('delete from public.'+table),'Appointment history must not be hard-deleted: '+table);
}

assert.ok(history.includes('create table if not exists public.schoolpro_staff_appointment_history'),'Appointment history snapshots must have a dedicated retained table.');
assert.ok(history.includes('snapshot jsonb not null'),'Appointment history must preserve the prior appointment row.');
assert.ok(history.includes("event_key:='reappointed'"),'Reappointment must be recorded as a separate history event.');
assert.ok(history.includes('after insert on public.schoolpro_board_members'),'Initial board appointments must be recorded.');
assert.ok(history.includes('before update on public.schoolpro_subject_assignments'),'Ending subject appointments must snapshot the previous assignment.');
assert.ok(history.includes('revoke all on public.schoolpro_staff_appointment_history from public,anon,authenticated'),'Clients must not mutate appointment history directly.');

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
  assert.ok(readers.includes('create or replace function private.'+fn+'('),'Expected updated helper '+fn+'.');
}
assert.ok(readers.includes('sl.ended_at is null'),'Ended section leadership must not grant access.');
assert.ok(readers.includes('a.ended_at is null'),'Ended subject and House Master appointments must not grant access.');
assert.ok(readers.includes("m.status='active'"),'Membership-derived access must require an active membership.');
assert.ok(readers.includes('c.archived_at is null'),'Archived classes must not grant current operational access.');

assert.ok(staff.includes('status:"active"|"suspended"'),'Staff UI must load membership lifecycle state.');
assert.ok(staff.includes('.is("ended_at",null)'),'Staff UI must hide ended section and subject assignments.');
assert.ok(staff.includes('.is("archived_at",null)'),'Staff UI must hide archived classes from current responsibilities.');
assert.ok(staff.includes('member.status==="suspended"?"Suspended":"Active"'),'Staff UI must show the real membership status.');
assert.ok(governance.includes(".is('ended_at',null)"),'Board UI must show only current appointments.');
assert.ok(governance.includes("m.status!=='suspended'"),'Suspended staff must not be offered for new board appointments.');

console.log('PASS: SchoolPro appointment termination, immutable history and active-reader contract.');
