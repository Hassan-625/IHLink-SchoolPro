import fs from 'node:fs';
import assert from 'node:assert/strict';

const read=(p)=>fs.readFileSync(p,'utf8');
const app=read('src/App.tsx');
const sidebar=read('src/components/Sidebar.tsx');
const staff=read('src/pages/schoolpro/SchoolProStaffDiscipline.tsx');
const leave=read('src/pages/schoolpro/SchoolProLeave.tsx');
const student=read('src/pages/schoolpro/SchoolProDiscipline.tsx');
const migrations=[
 'supabase/migrations/20261107210000_schoolpro_active_membership_operational_guards.sql',
 'supabase/migrations/20261107220000_schoolpro_staff_discipline_leave_workflows.sql',
 'supabase/migrations/20261107230000_schoolpro_student_discipline_case_management.sql',
 'supabase/migrations/20261108000000_schoolpro_central_active_membership_readers.sql'
].map(read).join('\n');

assert.match(app,/SchoolProStaffDiscipline/);
assert.match(app,/SchoolProLeave/);
assert.match(app,/path="\/schoolpro\/staff-discipline"/);
assert.match(app,/path="\/schoolpro\/leave"/);
assert.match(staff,/schoolpro_create_staff_disciplinary_case/);
assert.match(staff,/schoolpro_submit_staff_disciplinary_response/);
assert.match(staff,/schoolpro_review_staff_appeal/);
assert.match(staff,/schoolpro_close_staff_disciplinary_case/);
assert.match(staff,/dismissal/);
assert.match(leave,/schoolpro_report_own_absence/);
assert.match(leave,/schoolpro_update_own_leave_reason/);
assert.match(leave,/schoolpro_review_leave_request/);
assert.match(student,/guardian_contact_status/);
assert.match(student,/follow_up_outcome/);
assert.match(student,/student_response/);
assert.match(sidebar,/\/schoolpro\/staff-discipline/);
assert.match(sidebar,/\/schoolpro\/leave/);
assert.match(migrations,/m\.status='active'/);
assert.match(migrations,/schoolpro_staff_disciplinary_events/);
assert.match(migrations,/schoolpro_leave_events/);
assert.match(migrations,/schoolpro_discipline_events/);
assert.match(migrations,/cannot be restored through the suspension workflow/);

console.log('SchoolPro C0 workflow source-contract checks passed.');
