import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const authority=readFileSync('supabase/migrations/20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql','utf8');
const page=readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8');
const results=readFileSync('src/pages/schoolpro/SchoolProResults.tsx','utf8');
const selectedPublish=readFileSync('supabase/migrations/20261108116000_schoolpro_selected_publication_class_scope.sql','utf8');

assert.match(authority,/private\.schoolpro_result_scope_mixed_state/i,
  'Section and Exam Officer approval must validate the complete scoped result matrix.');
assert.match(authority,/create or replace function public\.schoolpro_approve_section_results/i);
assert.match(authority,/create or replace function public\.schoolpro_exam_officer_approve_results/i);
assert.match(authority,/create or replace function public\.schoolpro_publish_school_results/i);
assert.match(authority,/status='section_approved'/i);
assert.match(authority,/status='exam_approved'/i);
assert.match(authority,/Only the Exam Officer can publish school results/i);
assert.match(page,/schoolpro_approve_section_results/i);
assert.match(page,/schoolpro_exam_officer_approve_results/i);
assert.match(page,/schoolpro_publish_school_results/i);
assert.match(page,/schoolpro_return_class_results_for_correction/i);
assert.match(page,/schoolpro_class_result_workflow_summary/i);
assert.doesNotMatch(page,/review_schoolpro_results|review_schoolpro_class_results|review_schoolpro_result/i,
  'The broadsheet must not expose legacy partial or individual approval.');
assert.doesNotMatch(page,/Approve selected results|Approve class results for Exam Officer/i);
assert.doesNotMatch(results,/review_schoolpro_result/i,
  'The Results page must not approve an individual result.');
assert.match(results,/Awaiting Form Master submission/i);
assert.match(authority,/retire_legacy_result_rpcs/i,
  'Legacy per-result, partial-class and old publication RPCs must be revoked.');

assert.match(selectedPublish,/drop function if exists public\.publish_schoolpro_selected_results\(uuid,text,text,uuid\[\],boolean\)/,
  'The old unscoped publication overload must be removed.');
assert.match(selectedPublish,/p_class uuid default null/,
  'Any retained selected publication helper must carry an explicit class scope.');
assert.match(selectedPublish,/Every selected student must belong to this class roster/,
  'Selected publication must reject students outside the chosen class.');
assert.match(selectedPublish,/s\.class_id=p_class/);
assert.match(selectedPublish,/h\.class_id=p_class/);
assert.match(selectedPublish,/cardinality\(p_students\)>5000/);
assert.match(selectedPublish,/count\(distinct x\.id\).*cardinality\(p_students\)/s);

console.log('PASS: result approval is section-atomic, Exam Officer final approval/publication is school-wide, and legacy partial approval routes are revoked.');
