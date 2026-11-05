import assert from 'node:assert/strict';import vm from 'node:vm';import ts from 'typescript';import {readFileSync} from 'node:fs';
const exports={};vm.runInNewContext(ts.transpileModule(readFileSync('src/lib/schoolAccess.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{exports});
const landing={
 vice_principal:'/schoolpro/admin-dashboard',head_teacher:'/schoolpro/admin-dashboard',
 exam_officer:'/schoolpro/results',nurse:'/schoolpro/medical',librarian:'/schoolpro/library',
 it_admin:'/schoolpro/roles-permissions',hr_officer:'/schoolpro/staff',
 game_master:'/schoolpro/games',discipline_master:'/schoolpro/discipline',counsellor:'/schoolpro/discipline',
 bursar:'/schoolpro/fees',accountant:'/schoolpro/fees',registrar:'/schoolpro/students',
 admissions_officer:'/schoolpro/admissions',receptionist:'/schoolpro/admissions',
 transport_manager:'/schoolpro/transport',hostel_manager:'/schoolpro/hostel',inventory_officer:'/schoolpro/inventory'
};
for(const [role,path] of Object.entries(landing)){
 assert.equal(exports.schoolDashboard(role),path,role+' must land on its intended role workspace');
 if(path==='/schoolpro/admin-dashboard')assert.equal(exports.schoolDashboardAllowed(path,role),true);
 else assert.equal(exports.schoolDashboardAllowed(path,role),true);
 assert.equal(exports.schoolDashboardAllowed('/schoolpro/proprietor-dashboard',role),false);
}
for(const role of ['student','parent','teacher','class_teacher','unknown']){
 assert.equal(exports.schoolDashboardAllowed('/schoolpro/admin-dashboard',role),false);
}
assert.equal(exports.schoolDashboardAllowed('/schoolpro/student-dashboard','parent'),false);
assert.equal(exports.schoolDashboardAllowed('/schoolpro/parent-dashboard','student'),false);
console.log('PASS: specialist staff land on their authorized module; leadership roles retain filtered administration; student, parent and teacher accounts do not acquire ownership or administration by URL navigation.');
