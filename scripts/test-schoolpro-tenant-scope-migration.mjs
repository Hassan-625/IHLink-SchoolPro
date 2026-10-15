import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migrationPath='supabase/migrations/20261015200000_schoolpro_subject_assessment_and_form_master_scope.sql';
const migration=readFileSync(migrationPath,'utf8');
const required=[
  ['assignment management policy is replaced','drop policy if exists "assignment authorized manage" on public.schoolpro_assignments'],
  ['assignment writes are split by operation','create policy "assignment scoped insert"'],
  ['assignment updates have USING and WITH CHECK','create policy "assignment scoped update"'],
  ['attendance insert is limited to manager or assigned Form Master','create policy "Form Master or management inserts attendance"'],
  ['attendance update is limited to manager or assigned Form Master','create policy "Form Master or management updates attendance"'],
  ['CBT authoring requires class, subject and session','status=\'draft\' and session is not null and class_id is not null and subject_id is not null'],
  ['CBT test visibility uses scoped authorization','create policy "CBT tests scoped read"'],
  ['question-bank visibility uses class/subject scope','create policy "Question bank scoped read"'],
  ['CBT test-question writes follow the test scope','create policy "CBT test question scoped insert"'],
  ['theory marking re-checks school, test and question relationships','Question is not assigned to this test or school'],
  ['CBT question class and subject must match the test','CBT question must match the test subject'],
  ['Form Master class directory is exposed only to authenticated callers','grant execute on function public.schoolpro_class_staff_directory(uuid) to authenticated']
];
for(const [description,needle] of required) assert.ok(migration.includes(needle),description);
assert.doesNotMatch(migration,/\b(drop table|truncate|delete from)\b/i,'security migration must not delete production records or tables');
assert.match(migration,/revoke all on function private\.schoolpro_can_write_assignment_scope\(uuid,uuid,uuid,text\) from public,anon/);
assert.match(migration,/revoke all on function private\.schoolpro_can_author_cbt_scope\(uuid,uuid,uuid,text\) from public,anon/);
assert.match(migration,/new\.school_id<>question_row\.school_id|test_row\.school_id<>question_row\.school_id/,'cross-school CBT question relationships must be rejected');
console.log('PASS: SchoolPro scoped authorization migration contains the expected assignment, attendance, CBT, question-bank and cross-school relationship guards.');
