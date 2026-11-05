import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const students=readFileSync('src/pages/schoolpro/SchoolProStudents.tsx','utf8');
const parents=readFileSync('src/pages/schoolpro/SchoolProParents.tsx','utf8');
const parentForm=readFileSync('src/components/SchoolAccountForm.tsx','utf8');
const parentDashboard=readFileSync('src/pages/schoolpro/SchoolProParentDashboard.tsx','utf8');
const invitation=readFileSync('supabase/functions/invite-school-staff/index.ts','utf8');

assert.match(students,/guardian_email/,'Student enrolment and records must retain guardian email.');
assert.match(students,/guardian_email:form\.guardian_email\.trim\(\)\|\|null/,'Guardian email must be persisted as an optional contact field.');
assert.match(students,/student\.guardian_email&&/,'Student records must display the captured guardian email.');
assert.doesNotMatch(students,/\.from\(["']schoolpro_students["']\)\.delete\(/,'Student records must not be hard-deleted from the enrolment screen.');
assert.doesNotMatch(students,/async function remove\(/,'The student page must not expose a destructive delete handler.');
assert.match(students,/schoolpro_transfer_student_out/,'Student exit must use the audited transfer/withdrawal workflow.');

assert.match(parentForm,/guardianPhone/,'Parent account form must capture a guardian contact phone.');
assert.match(parentForm,/body:\{schoolId,\.\.\.form/,'Guardian phone must be sent through the existing invitation workflow.');
assert.match(parentForm,/Relationship<select/,'The existing relationship selector must remain available.');
assert.match(parents,/profile\?\.phone/,'Parent management must display the linked guardian profile phone.');
assert.match(parentDashboard,/schoolpro_guardian_links/,'Parent dashboard must continue to derive access from guardian links.');
assert.match(parentDashboard,/middle_name/,'Parent dashboard must preserve full student names.');

assert.match(invitation,/guardianPhone\.length>40/,'Guardian phone input must be bounded.');
assert.match(invitation,/select\('id,last_name,phone'\)/,'Existing profile phone must be read before applying a captured contact.');
assert.match(invitation,/!String\(existing\.phone\|\|''\)\.trim\(\)/,'A school must not overwrite a non-empty existing global profile phone.');
assert.match(invitation,/phoneUpdate=existing\.phone===null\?/,'Blank phone updates must be guarded against concurrent profile changes.');
assert.match(invitation,/phone:role==='parent'\?\(guardianPhone\|\|null\):null/,'New parent profiles must receive the submitted contact phone.');
assert.match(invitation,/schoolpro_accept_access_invitation/,'The existing invitation acceptance and guardian-link workflow must remain in place.');

console.log('PASS: student guardian contacts, parent relationship workflow, profile phone preservation, and non-destructive student lifecycle.');
