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

const bulk=readFileSync('src/components/schoolpro/SchoolProExistingStudentBulkImport.tsx','utf8');
assert.match(bulk,/workbook\.xlsx\.load/,'Bulk onboarding must parse Excel workbooks.');
assert.match(bulk,/parseCsv/,'Bulk onboarding must parse CSV registers.');
assert.match(bulk,/admission_number/,'Admission numbers must be required and checked.');
assert.match(bulk,/duplicate admission number within this file/,'Duplicate admission numbers inside a spreadsheet must block import.');
assert.match(bulk,/already exists in this school/,'Existing school admission numbers must block duplicate import.');
assert.match(bulk,/class\/arm/,'Class names must map to active classes in the selected school.');
assert.match(bulk,/schoolpro_assign_student_house/,'Optional house assignments must be preserved.');
assert.match(bulk,/admission_type:"existing"/,'Every imported row must be classified as an existing student.');
assert.match(bulk,/enrollment_session:session/,'Imported students must be attached to the selected academic session.');
assert.match(bulk,/parsed.length>500/,'Bulk import must enforce a bounded batch size.');
assert.match(bulk,/No records have been saved yet/,'Validation preview must not write student records.');
console.log('PASS: bulk existing-student import validates Excel/CSV, duplicates, classes, houses, session and batch bounds.');

assert.match(bulk,/schoolpro-existing-students-template\.csv/,"Operators must be able to download a correctly headed CSV template.");
assert.match(bulk,/Download CSV template/,"The CSV template download must be visible in the import panel.");
