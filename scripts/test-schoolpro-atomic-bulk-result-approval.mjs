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


const scopeHelper=authority.slice(
  authority.indexOf('function private.schoolpro_result_scope_mixed_state'),
  authority.indexOf('$;',authority.indexOf('function private.schoolpro_result_scope_mixed_state'))+3
);
assert.match(scopeHelper,/target_classes as/i,
  'Whole-school completeness must derive its scope from every non-archived school class.');
assert.match(scopeHelper,/schoolpro_subject_assignments/i,
  'The expected result matrix must be based on active subject allocations.');
assert.match(scopeHelper,/a\.ended_at is null/i,
  'Ended subject allocations must not create expected result obligations.');
assert.match(scopeHelper,/schoolpro_enrollment_history/i,
  'Historical session enrolment must determine the student roster.');
assert.match(scopeHelper,/s\.status='active' and s\.class_id=c\.id/i,
  'Students without session history may use only their current active class.');
assert.match(scopeHelper,/private\.schoolpro_result_assessment_complete\(r\.id\)/i,
  'Every expected result must pass the configured assessment completeness check.');
assert.match(scopeHelper,/r\.id is null or w\.class_id is distinct from e\.class_id/i,
  'A missing result or a result attached to the wrong class must block the workflow.');
assert.match(scopeHelper,/p_stage='exam'.*exam_approved/s,
  'Final approval and publication require Exam Officer state for every expected result.');

const publishStart=authority.indexOf('function public.schoolpro_publish_school_results');
const publishEnd=authority.indexOf('$;',publishStart);
assert.ok(publishStart>=0&&publishEnd>publishStart,'Whole-school publication RPC must exist.');
const publish=authority.slice(publishStart,publishEnd);
assert.ok(publish.indexOf('private.schoolpro_lock_result_scope')<publish.indexOf('private.schoolpro_result_scope_mixed_state'),
  'Publication must lock the complete school-period scope before validating it.');
assert.match(publish,/private\.schoolpro_is_exam_officer\(p_school\)/i,
  'Only an Exam Officer may publish school results.');
assert.match(publish,/w\.status not in \('exam_approved','published'\)/i,
  'Any submitted class workflow not finally approved must block publication.');
assert.match(publish,/r\.status not in \('approved','published'\)/i,
  'Any result not section-approved must block publication.');
assert.match(publish,/r\.status='approved'.*w\.status='exam_approved'/s,
  'Only results with both approved result state and final Exam Officer workflow state may be published.');
assert.match(publish,/set status='published',locked=true/i,
  'Publication must lock every released result.');
assert.match(publish,/Whole-school results published/i,
  'Publication must leave an audit event.');
assert.match(authority,/revoke all on function public\.schoolpro_publish_school_results\(uuid,text,text\) from public,anon/i,
  'Anonymous and public callers must not execute the publication RPC.');
assert.match(authority,/grant execute on function public\.schoolpro_publish_school_results\(uuid,text,text\) to authenticated/i,
  'Authenticated calls must pass the RPC authorization checks.');


console.log('PASS: section-atomic approval, Exam Officer final approval, whole-school completeness matrix and locked publication boundaries.');
