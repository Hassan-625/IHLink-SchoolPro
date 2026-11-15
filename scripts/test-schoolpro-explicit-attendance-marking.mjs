import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const source = readFileSync('src/pages/schoolpro/SchoolProAttendance.tsx', 'utf8');

assert.ok(source.includes('status:AttendanceStatus|""'), 'Unrecorded attendance must remain explicitly unmarked in the UI state.');
assert.ok(source.includes('status:row?.status||""'), 'Existing saved statuses should load, but missing rows must not default to present.');
assert.ok(source.includes('const unmarked=students.filter(student=>!records[student.id]?.status)'), 'The save action must detect learners without an explicit attendance status.');
assert.ok(source.includes('Mark an attendance status for all learners.'), 'The operator must receive a clear incomplete-register message.');
assert.ok(source.includes('label:"Unmarked"'), 'The dashboard must expose the number of unresolved attendance entries.');
assert.ok(source.includes('counts.unmarked>0'), 'Saving must remain disabled while any learner is unmarked.');
assert.ok(source.includes('value={records[student.id]?.status||""}'), 'The status selector must display an empty selection for an unmarked learner.');
assert.ok(source.includes('<option value="">Select status…</option>'), 'The operator must explicitly choose a status before saving.');
assert.ok(!source.includes('status:records[student.id]?.status||"present"'), 'Saving must never silently convert an unmarked learner to present.');

assert.ok(source.includes('form_teacher_id?:string|null'), 'Attendance class rows must carry the assigned Form Master member id.');
assert.ok(source.includes('.eq("status","active").maybeSingle()'), 'Only an active school membership may establish the current Form Master identity.');
assert.ok(source.includes('row.form_teacher_id===activeMemberId'), 'Non-management attendance registers must be limited to classes assigned to the signed-in active Form Master membership.');
assert.ok(source.includes('profile?.role==="super_admin"'), 'Platform Super Admin retains school-wide attendance oversight.');
assert.ok(source.includes('Only the Form Master assigned to this class can record attendance.'), 'The save handler must independently reject a class outside the current Form Master assignment.');
assert.ok(source.includes('No classes are assigned to you as Form Master.'), 'An unassigned teacher must receive an explicit empty-state explanation.');

console.log('PASS: attendance requires an explicit status for every learner before saving and is limited to the assigned Form Master.');
