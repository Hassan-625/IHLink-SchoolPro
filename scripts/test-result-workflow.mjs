import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const broadsheet=readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8');
const results=readFileSync('src/pages/schoolpro/SchoolProResults.tsx','utf8');
const authority=readFileSync('supabase/migrations/20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql','utf8');
const correctionRouting=readFileSync('supabase/migrations/20261114222000_schoolpro_result_correction_section_review.sql','utf8');
const profile=readFileSync('src/pages/schoolpro/SchoolProProfile.tsx','utf8');

assert.match(results,/appointed Section Head reviews this request first when required/i,
  'Correction request UI must explain the Section Head review stage before Exam Officer authorization.');
assert.match(results,/submitted to the review workflow\. It will pass through the required Section Head review when applicable, followed by final Exam Officer authorization/i,
  'Correction request confirmation must describe the staged review route without implying direct Exam Officer-only routing.');
assert.match(results,/const entrySubjects=teachingTargets\.length\?subjects\.filter/i,
  'Subject teachers must be restricted to their own allocated subjects.');
assert.match(results,/Assessment readiness/,'Results page must expose a read-only assessment readiness panel.');
assert.match(results,/form_teacher_id/,'Readiness must detect missing class Form Master appointments.');
assert.match(results,/unassignedSubjectCount/,'Readiness must distinguish allocated subjects without an assigned teacher.');
assert.match(results,/hasScheme/,'Readiness must check for an assessment scheme compatible with each class level.');
assert.match(results,/View only · subject teacher entry/i,
  'Non-assigned subject marks must remain read-only.');
assert.match(broadsheet,/activePrincipalSections/, 'Active Principal appointments must be loaded for each section.');
assert.match(broadsheet,/const isPrincipal=memberRole==='administrator'&&memberPositionTitle\.trim\(\)\.toLowerCase\(\)==='principal'/, 'Only the appointed Principal retains section review controls when a Principal is active in that section.');
assert.match(broadsheet,/!principalSections\.includes\(className\.level\)\|\|isPrincipal/, 'Vice Principals and other appointees must not see section approval controls when the Principal is appointed.');
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
assert.match(broadsheet,/schoolpro_review_result_reopening/i,
  'The Section Head must forward or reject a teacher/Form Master correction request before Exam Officer review.');
assert.match(broadsheet,/pending_section_review/);
assert.match(broadsheet,/pending_exam_officer/);
assert.match(broadsheet,/Forward to Exam Officer/i);
assert.match(broadsheet,/canReviewCorrectionRequest/);
assert.match(broadsheet,/schoolpro_review_result_reopening/i,
  'The Section Head must forward or reject teacher/Form Master requests before Exam Officer review.');
assert.match(broadsheet,/pending_section_review/);
assert.match(broadsheet,/pending_exam_officer/);
assert.match(broadsheet,/Forward to Exam Officer/i);
assert.match(broadsheet,/canReviewSectionQueue/);
assert.match(correctionRouting,/status='pending_section_review'/i);
assert.match(correctionRouting,/status='pending_exam_officer'/i);
assert.match(correctionRouting,/The requester and Section Head reviewer cannot authorize the same correction request/i);
assert.match(broadsheet,/schoolpro_decide_result_reopening/i,
  'Only the Exam Officer can approve or reject a correction reopening request.');
assert.match(authority,/Only the active subject teacher assigned to this class and subject can enter or update these scores/i);
assert.match(authority,/schoolpro_class_result_matrix_complete/i);
assert.match(authority,/schoolpro_result_scope_mixed_state/i);
assert.match(authority,/create or replace function private\.schoolpro_lock_result_scope/i,
  'Workflow transitions must serialize the roster, active subject allocations, result rows and workflow rows.');
assert.ok((authority.match(/perform private\.schoolpro_lock_result_scope\(p_school,p_term,p_session/gi)||[]).length>=5,
  'Form Master submission, Section Head approval, Exam Officer approval and publication must lock their exact result scope before completeness checks.');
assert.match(authority,/perform private\.schoolpro_lock_result_scope\(p_school,p_term,p_session,'class',p_class,null\);\s*if not private\.schoolpro_class_result_matrix_complete/i,
  'Form Master completeness must be checked after locking the class result scope.');
assert.match(authority,/Only the Exam Officer can publish school results/i);
assert.match(authority,/app\.schoolpro_correction_reopen/i);
assert.match(authority,/status='section_approved'/i);
assert.match(authority,/status='exam_approved'/i);
assert.match(authority,/schoolpro_member_responsibilities_self_or_admin_read/i);
assert.match(authority,/grant select on public\.schoolpro_member_responsibilities to authenticated/i);
assert.match(authority,/target\.role = 'teacher'/i,
  'Ordinary Subject Teachers must be excluded while other active staff may be appointed.');
assert.match(authority,/private\.schoolpro_member_leads_student_section\(new\.school_id,new\.student_id,new\.session\)/i);
assert.match(authority,/c\.archived_at is null/i,'Section readers must exclude archived classes.');
assert.match(profile,/My School Responsibilities/);
assert.match(authority,/create or replace function private\.schoolpro_can_review_class/i);
assert.match(authority,/private\.schoolpro_is_exam_officer\(p_school\)/i);
assert.match(authority,/private\.schoolpro_is_exam_officer\(c\.school_id\)/i);
assert.match(authority,/private\.schoolpro_is_school_admin\(s\.school_id\)/i);
assert.match(profile,/eq\('session',session\)/,
  'The account page must show only current-session subject allocations.');
assert.match(broadsheet,/const canPublishAll=memberRole==='exam_officer'\|\|additionalResponsibilities\.includes\('exam_officer'\)/,
  'Final approval, publication and correction reopening UI must require an active Exam Officer role or responsibility.');
assert.doesNotMatch(broadsheet,/const canPublishAll=.*super administrator|const canPublishAll=.*super_admin/i,
  'Super Admin must not receive Exam Officer publication authority from the global platform role.');
assert.match(broadsheet,/const canManageSchoolView=.*super administrator/,
  'Super Admin retains school administration/view access independently of Exam Officer authority.');
console.log('PASS: subject-specific score entry, Form Master hand-off, complete section review, correction return, Exam Officer final approval/publication, and authorized class/section reopening source contracts.');
