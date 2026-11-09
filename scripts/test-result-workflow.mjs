import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const broadsheet=readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8');
const results=readFileSync('src/pages/schoolpro/SchoolProResults.tsx','utf8');
const authority=readFileSync('supabase/migrations/20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql','utf8');
const profile=readFileSync('src/pages/schoolpro/SchoolProProfile.tsx','utf8');

assert.match(results,/const entrySubjects=teachingTargets\.length\?subjects\.filter/i,
  'Subject teachers must be restricted to their own allocated subjects.');
assert.match(results,/View only · subject teacher entry/i,
  'Non-assigned subject marks must remain read-only.');
assert.match(broadsheet,/schoolpro_class_subject_teacher_roster/i,
  'The class broadsheet must load the active subject-teacher roster through the scoped RPC.');
assert.match(broadsheet,/async function refreshCorrectionQueue\(/, 'The Exam Officer correction queue must have an explicit refresh path.');
assert.match(broadsheet,/if\(!r\.error\)await refreshCorrectionQueue\(\)/, 'New correction requests must appear in the pending queue without reloading the page.');
assert.match(broadsheet,/await refreshCorrectionQueue\(\);const affectsSelectedClass=request\.class_id===classId/, 'Approving or rejecting a reopening request must refresh the queue and determine whether the selected class is affected.');
assert.match(broadsheet,/if\(affectsSelectedClass&&request\.term===term&&request\.session===session\)await refreshWorkflowView\(\)/, 'A reopening decision affecting the selected class and period must refresh its broadsheet and workflow status.');
assert.match(broadsheet,/request\.scope==='section'&&request\.section===className\?\.level/, 'A section reopening decision must refresh the selected class when it belongs to that section.');
assert.match(broadsheet,/async function refreshWorkflowView\(/, 'Workflow transitions must refresh the current class broadsheet and workflow status.');
assert.match(broadsheet,/if\(!result\.error\)await refreshWorkflowView\(\)/, 'Form Master submission must refresh workflow status immediately.');
assert.match(broadsheet,/if\(!r\.error\)await refreshWorkflowView\(\)/, 'Successful section return, section approval, Exam Officer approval and publication must refresh workflow status immediately.');
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
assert.match(authority,/schoolpro_member_responsibilities_self_or_admin_read/i);
assert.match(authority,/grant select on public\.schoolpro_member_responsibilities to authenticated/i);
assert.match(authority,/target\.role in \('teacher','class_teacher'\)/i,
  'Teaching staff must be eligible for an explicitly appointed section-head responsibility.');
assert.match(authority,/private\.schoolpro_member_leads_student_section\(new\.school_id,new\.student_id,new\.session\)/i);
assert.match(profile,/My School Responsibilities/);
assert.match(authority,/create or replace function private\.schoolpro_can_review_class/i);
assert.match(authority,/private\.schoolpro_is_exam_officer\(p_school\)/i);
assert.match(authority,/private\.schoolpro_is_exam_officer\(c\.school_id\)/i);
assert.match(authority,/private\.schoolpro_is_school_admin\(s\.school_id\)/i);
assert.match(profile,/eq\('session',session\)/,
  'The account page must show only current-session subject allocations.');
console.log('PASS: subject-specific score entry, Form Master hand-off, complete section review, correction return, Exam Officer final approval/publication, and authorized class/section reopening source contracts.');
