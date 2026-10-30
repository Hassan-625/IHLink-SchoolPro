import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';

const compile=(path)=>ts.transpileModule(readFileSync(path,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText;
const exports={};
vm.runInNewContext(compile('src/lib/academicSessions.ts'),{exports});
const sessions=exports.academicSessionOptions(2026);
assert.equal(sessions[0],'2001/2002');
assert.equal(sessions.at(-1),'2026/2027');
assert.equal(sessions.length,26);
assert.ok(sessions.includes('2025/2026'));
assert.equal(new Set(sessions).size,sessions.length);
assert.deepEqual(Array.from(exports.academicSessionOptions(2027).slice(-2)),['2026/2027','2027/2028']);
assert.equal(exports.academicSessionStatus('2026-09-01','2027-07-30','2026-08-31'),'upcoming');
assert.equal(exports.academicSessionStatus('2026-09-01','2027-07-30','2026-09-01'),'active');
assert.equal(exports.academicSessionStatus('2026-09-01','2027-07-30','2027-07-31'),'completed');
assert.equal(exports.academicSessionStatus('2026-09-01','2027-07-30','2026-09-01',true),'archived');

const sessionBar=readFileSync('src/components/SchoolSessionBar.tsx','utf8');
assert.ok(sessionBar.includes('AcademicPeriodSelect'),'Working session bar must use the canonical selector.');
assert.ok(!sessionBar.includes('Array.from({length:31}'),'Working session bar must not maintain a separate rolling range.');
assert.ok(sessionBar.includes('does not promote students'),'Changing the working session must not imply student progression.');

const migration=readFileSync('supabase/migrations/20261030190000_schoolpro_academic_session_lifecycle_and_calendar_history.sql','utf8');
for(const expected of ['schoolpro_academic_sessions','schoolpro_academic_calendar_history','before_state','after_state','schoolpro_save_academic_session','schoolpro_archive_academic_session','Academic sessions cannot be deleted','Academic term records cannot be deleted','status in (\'upcoming\',\'active\',\'completed\',\'archived\')']){
  assert.ok(migration.includes(expected),`B1 migration must include: ${expected}`);
}
assert.ok(migration.includes('schoolpro_module_allowed(p_school, \'calendar\')'),'Session writes must enforce calendar permissions.');
assert.ok(migration.includes('Academic session dates cannot overlap'),'Non-archived session date ranges must not overlap.');
console.log('PASS: canonical session range, lifecycle date states, shared selector, and append-only calendar-history migration guards.');
