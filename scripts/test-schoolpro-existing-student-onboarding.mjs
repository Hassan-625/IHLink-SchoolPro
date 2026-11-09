import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const page=readFileSync('src/pages/schoolpro/SchoolProStudents.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261109110000_schoolpro_existing_student_onboarding.sql','utf8');

assert.match(page,/value="existing">Existing student \(already enrolled at this school\)/,'Enrollment must distinguish an existing student from a new admission and transfer-in.');
assert.match(page,/admission_type:form\.admission_type/,'The selected admission type must be persisted on the student record.');
assert.match(page,/admission_type==="existing"/,'Existing student onboarding must have its own explanatory and roster treatment.');
assert.match(page,/schoolpro_assign_student_house/,'The operator must be able to preserve an existing house assignment during onboarding.');
assert.match(page,/Existing student · onboarded from current school/,'The roster must identify students onboarded as existing students.');
assert.match(page,/schoolpro_houses/,'Existing house options must be loaded from the active school workspace.');
assert.match(migration,/check \(admission_type in \('new', 'existing', 'transfer_in'\)\)/,'The database must accept all three distinct student entry pathways.');
assert.doesNotMatch(migration,/update public\.schoolpro_students/i,'The migration must not rewrite production student records.');

console.log('PASS: existing-student onboarding is distinct, school-scoped, house-aware, and non-destructive.');
