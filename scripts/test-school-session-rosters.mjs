import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';

const source=readFileSync('src/lib/schoolSessionRoster.ts','utf8');
const bulkActions=readFileSync('src/components/SchoolBulkAcademicActions.tsx','utf8');
const classFilters=readFileSync('src/lib/schoolClassFilters.ts','utf8');
const compiled=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText;
const exports={};
vm.runInNewContext(compiled,{exports});
const resolve=exports.resolveSchoolSessionRoster;
const classFilterExports={};
vm.runInNewContext(ts.transpileModule(classFilters,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{exports:classFilterExports});
const studentClass=classFilterExports.studentClass;
const students=[
 {id:'active-current',class_id:'class-new',class_name:'Primary 2',status:'active'},
 {id:'inactive-current',class_id:'class-old',class_name:'Primary 1',status:'inactive'},
 {id:'graduated-current',class_id:'class-final',class_name:'Basic 5',status:'graduated'},
];
const legacy=resolve(students,[],false);
assert.deepEqual(Array.from(legacy.map(s=>s.id)),['active-current']);
assert.deepEqual(Array.from(resolve(students,[],true)),[]);
const historical=resolve(students,[
 {student_id:'active-current',class_id:'class-old',class_name:'Primary 1',arm:'A',section:'Primary',status:'completed'},
 {student_id:'graduated-current',class_id:'class-final',class_name:'Basic 5',arm:'B',section:'Primary',status:'graduated'},
],true);
assert.equal(historical.length,2);
assert.equal(historical[0].class_id,'class-old');
assert.equal(historical[0].class_name,'Primary 1 A');
assert.equal(historical[0].current_class_id,'class-new');
assert.equal(historical[0].session_status,'completed');

assert.equal(historical[1].session_status,'graduated');
const classes=[
 {id:'class-new',name:'Primary 2',arm:'A',level:'primary'},
 {id:'class-old',name:'Primary 1',arm:'A',level:'primary'},
 {id:'class-final',name:'Basic 5',arm:'B',level:'primary'},
];
assert.equal(studentClass(historical[0],classes)?.id,'class-old','Historical class count must use the selected-session class, not the student's current class.');
assert.equal(historical.filter(student=>studentClass(student,classes)?.id==='class-old').length,1,'Historical class roster count must include the student after a current-class change.');
assert.equal(studentClass(historical[1],classes)?.id,'class-final','Graduated students must remain visible in their historical class roster.');

assert.match(bulkActions,/schoolSessionStudents\(schoolId,session,pupils\.data\|\|\[\]\)/,'Bulk year-end actions must use the canonical session roster resolver, including the legacy fallback.');
assert.match(bulkActions,/student_id:student\.id,class_id:student\.class_id/,'Bulk actions must pass resolved session-specific student IDs and class assignments.');
console.log('PASS: legacy active-only fallback, empty historical session, historical class/arm projection, historical class counts, graduated roster visibility, and bulk-action roster consistency.');
