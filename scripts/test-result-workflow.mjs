import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const broadsheet=readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8');
const results=readFileSync('src/pages/schoolpro/SchoolProResults.tsx','utf8');
const authority=readFileSync('supabase/migrations/20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql','utf8');

assert.match(results,/const entrySubjects=teachingTargets\.length\?subjects\.filter/i,
  'Subject teachers must be restricted to their own allocated subjects.');
assert.match(results,/View only · subject teacher entry/i,
  'Non-assigned subject marks must remain read-only.');
assert.match(broadsheet,/schoolpro_class_subject_teacher_roster/i,
  'The class broadsheet must load the active subject-teacher roster through the scoped RPC.');
assert.match(broadsheet,/Submit class results to section head/i,
  'The Form Master must have a class submission hand-off.');
assert.match(broadsheet,/schoolpro_approve_section_results/i,
  'The appointed Section Head must approve the complete section.');
assert.match(broadsheet,/Return class to Form Master/i,
  'The Section Head must be able to return a class for corrections.');
assert.match(broadsheet,/schoolpro_exam_officer_approve_results/i,
  'The Exam Officer must perform final approval.');
assert.match(broadsheet,/schoolpro_publish_school_results/i,
  'The Exam Officer must publish the whole-school result set.');
assert.match(broadsheet,/Pending class \/ section correction requests/i,
  'The Exam Officer must have a pending class/section correction queue.');
assert.match(broadsheet,/schoolpro_decide_result_reopening/i,
  'Only the Exam Officer can approve or reject a correction reopening request.');
assert.match(authority,/Only the active subject teacher assigned to this class and subject can enter or update these scores/i);
assert.match(authority,/schoolpro_class_result_matrix_complete/i);
assert.match(authority,/schoolpro_result_scope_mixed_state/i);
assert.match(authority,/Only the Exam Officer can publish school results/i);
assert.match(authority,/app\.schoolpro_correction_reopen/i);
assert.match(authority,/status='section_approved'/i);
assert.match(authority,/status='exam_approved'/i);
console.log('PASS: subject-specific score entry, Form Master hand-off, complete section review, correction return, Exam Officer final approval/publication, and authorized class/section reopening source contracts.');
