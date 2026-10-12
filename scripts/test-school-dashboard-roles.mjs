import assert from 'node:assert/strict';import vm from 'node:vm';import ts from 'typescript';import {readFileSync} from 'node:fs';
const exports={};vm.runInNewContext(ts.transpileModule(readFileSync('src/lib/schoolAccess.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{exports});
for(const role of ['vice_principal','exam_officer','nurse','librarian','it_admin','hr_officer']){
assert.equal(exports.schoolDashboard(role),'/schoolpro/admin-dashboard');
assert.equal(exports.schoolDashboardAllowed('/schoolpro/admin-dashboard',role),true);
assert.equal(exports.schoolDashboardAllowed('/schoolpro/proprietor-dashboard',role),false);
}
for(const role of ['student','parent','teacher','class_teacher','unknown']){
assert.equal(exports.schoolDashboardAllowed('/schoolpro/admin-dashboard',role),false);
}
assert.equal(exports.schoolDashboardAllowed('/schoolpro/student-dashboard','parent'),false);
assert.equal(exports.schoolDashboardAllowed('/schoolpro/parent-dashboard','student'),false);
console.log('PASS: recognized operational roles reach the workspace; students, parents and teachers do not acquire administration or ownership by navigating to a URL.');
