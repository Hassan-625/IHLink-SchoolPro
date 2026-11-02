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

const calendarManager=readFileSync('src/components/SchoolAcademicSessionManager.tsx','utf8');
assert.ok(calendarManager.includes('updateWorkingSession={false}'),'Editing calendar metadata must not change the globally selected working session.');
const calendarEditor=readFileSync('src/components/SchoolAcademicCalendar.tsx','utf8');
assert.ok(calendarEditor.includes('kind="session" value={form.session} updateWorkingSession={false}'),'Editing term dates must not change the globally selected working session.');

const migration=readFileSync('supabase/migrations/20261030190000_schoolpro_academic_session_lifecycle_and_calendar_history.sql','utf8');
for(const expected of ['schoolpro_academic_sessions','schoolpro_academic_calendar_history','schoolpro_reject_calendar_history_mutation','Academic calendar history is immutable','before_state','after_state','schoolpro_save_academic_session','schoolpro_archive_academic_session','Academic sessions cannot be deleted','Academic term records cannot be deleted','status in (\'upcoming\',\'active\',\'completed\',\'archived\')']){
  assert.ok(migration.includes(expected),`B1 migration must include: ${expected}`);
}
assert.ok(migration.includes('schoolpro_module_allowed(p_school, \'calendar\')'),'Session writes must enforce calendar permissions.');
assert.equal((migration.match(/private\.has_school_access\(p_school, array\[/g)||[]).length,2,'Both session save and archive RPCs must use the same school-role boundary as the existing calendar RPC.');
assert.ok(!migration.includes("schoolpro_module_allowed(p_school, 'promotions')"),'Calendar management must not require the separate promotions module.');
assert.ok(migration.includes("'registrar'::public.school_member_role")&&migration.includes("'head_teacher'::public.school_member_role")&&migration.includes("'vice_principal'::public.school_member_role"),'Calendar RPCs must preserve the established calendar-management roles.');
assert.ok(migration.includes('Academic session dates cannot overlap'),'Non-archived session date ranges must not overlap.');
assert.ok(migration.includes('create or replace function private.schoolpro_stamp_activity_period()'),'The proposed session migration must integrate session dates with activity stamping.');
assert.ok(migration.includes('from public.schoolpro_academic_sessions')&&migration.includes('start_date <= activity_date')&&migration.includes('end_date >= activity_date'),'New activity session stamps must be resolved by the configured session date range.');
assert.ok(migration.includes("and status <> 'archived'"),'Archived sessions must not be inferred for new activity records.');
assert.ok(migration.includes('Backward-compatible path until a school configures explicit session ranges.'),'Schools without explicit session records must retain legacy term-date stamping during transition.');
assert.ok(migration.includes('from public.schoolpro_result_term_settings')&&migration.includes('session = selected_session')&&migration.includes('term_start_date <= activity_date')&&migration.includes('term_end_date >= activity_date'),'Term remains independently resolved from the matching session and activity date.');
assert.ok(migration.includes("selected_session := nullif(j->>'session', '')"),'An explicitly supplied session must be preserved instead of overwritten by date inference.');
assert.equal((migration.match(/as \$\$/g)||[]).length,(migration.match(/^\$\$;/gm)||[]).length,'Every PL/pgSQL dollar-quoted body must have a matching delimiter.');
assert.ok(!/as \$(?:\\r?\\n)|^\$;$/m.test(migration),'Migration must not contain malformed single-dollar function delimiters.');
console.log('PASS: canonical session range, lifecycle date states, shared selector, and append-only calendar-history migration guards.');
