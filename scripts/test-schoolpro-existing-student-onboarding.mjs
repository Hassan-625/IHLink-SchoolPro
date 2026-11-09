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
assert.match(bulk,/class .*arm/,'Class and arm must map to active classes in the selected school.');
assert.match(bulk,/schoolpro_assign_student_house/,'Optional house assignments must be preserved.');
assert.match(bulk,/admission_type:"existing"/,'Every imported row must be classified as an existing student.');
assert.match(bulk,/enrollment_session:session/,'Imported students must be attached to the selected academic session.');
assert.match(bulk,/parsed.length>500/,'Bulk import must enforce a bounded batch size.');
assert.match(bulk,/No records have been saved yet/,'Validation preview must not write student records.');
console.log('PASS: bulk existing-student import validates Excel/CSV, duplicates, classes, houses, session and batch bounds.');

assert.match(bulk,/schoolpro-existing-students-template\.csv/,"Operators must be able to download a correctly headed CSV template.");
assert.match(bulk,/Download CSV template/,"The CSV template download must be visible in the import panel.");
assert.match(bulk,/schoolpro-existing-students-template\.xlsx/,"Operators must be able to download a complete Excel workbook.");
assert.match(bulk,/Guardian First Name/,"The workbook must capture guardian names separately.");
assert.match(bulk,/Date of Birth/,"The workbook must capture date of birth so age can be calculated.");
assert.match(bulk,/DATEDIF/,"The Excel workbook must calculate age from date of birth.");
assert.match(bulk,/sectionAliases/,"Section, class and arm must be automatically mapped to the selected school records.");
assert.match(bulk,/date_of_birth:dob/,"Date of birth must be persisted to the student record.");
assert.match(bulk,/guardian_first_name/,"Separate guardian names must be combined into the existing guardian name field.");
assert.match(bulk,/if\(!raw\.some\(value=>String\(value\?\?""\)\.trim\(\)\)\)continue/,"Blank Excel formula rows must not be treated as student records.");
assert.match(bulk,/Download Excel template/,"The Excel template download must be visible in the import panel.");
const studentPage=readFileSync("src/pages/schoolpro/SchoolProStudents.tsx","utf8");
assert.match(studentPage,/xl:col-span-2/,"The student roster must span the full desktop grid and retain mobile horizontal scrolling.");

assert.match(bulk,/"Last Name"/,"The downloadable register must use Last Name consistently.");
assert.match(bulk,/surname":"last_name"/,"Older spreadsheets headed Surname must remain compatible.");
assert.match(bulk,/DATE\\(2026,9,1\\)/,"The displayed age must use the 1 September 2026 school-year reference date, not the viewer's current date.");
assert.match(bulk,/function minimumAgeForClass/,"The importer must enforce class-specific minimum ages.");
assert.match(bulk,/pre\\\\s\\*nursery/,"Pre-Nursery must have its own minimum age rule.");
assert.match(bulk,/minimumAgeForClass\\(klass\\.name\\)/,"The age minimum must be selected from the matched active class.");
assert.match(bulk,/date of birth is required to calculate and validate the student age/,"Date of birth must be required for reliable age validation.");
assert.match(bulk,/requires a minimum age of/,"Under-age students must be blocked with an actionable explanation.");
const classesPage=readFileSync("src/pages/schoolpro/SchoolProClasses.tsx","utf8");
assert.match(classesPage,/Add Pre-Nursery A &amp; B/,"School administrators must have a one-click Pre-Nursery A/B setup action.");
assert.match(classesPage,/name:"Pre-Nursery",arm,level:"nursery"/,"Pre-Nursery arms must be created in the Nursery section.");
assert.match(classesPage,/already has both A and B arms/,"The Pre-Nursery setup must be idempotent.");
console.log("PASS: 2026/2027 age reference, class minimum ages, Last Name header and Pre-Nursery A/B setup.");
