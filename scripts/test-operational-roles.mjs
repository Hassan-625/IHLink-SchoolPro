import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
const exports={};vm.runInNewContext(ts.transpileModule(readFileSync('src/lib/schoolOperationalRoles.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2021}}).outputText,{exports});const allowed=exports.canManageSchoolOperation;
for(const kind of ['library','transport','hostel','inventory','promotions','calendar','payroll','medical','leave']){assert(allowed(kind,'Proprietor'));assert(allowed(kind,'Super Administrator'));assert(!allowed(kind,'teacher'));assert(!allowed(kind,'student'));assert(!allowed(kind,'parent'));}
assert(allowed('medical','nurse'));assert(!allowed('payroll','nurse'));assert(allowed('payroll','accountant'));assert(!allowed('medical','accountant'));assert(allowed('leave','hr_officer'));assert(allowed('library','librarian'));assert(!allowed('transport','librarian'));assert(allowed('transport','transport_manager'));assert(allowed('hostel','hostel_manager'));
console.log('PASS: owner display roles and specialised operational management; customer roles cannot manage. Database permissions remain authoritative.');
