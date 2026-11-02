import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';

const source=readFileSync('src/lib/schoolSessionRoster.ts','utf8');
const compiled=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText;
const exports={};
vm.runInNewContext(compiled,{exports});
const resolve=exports.resolveSchoolSessionRoster;
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
console.log('PASS: legacy active-only fallback, empty historical session, and historical class/arm projection.');
