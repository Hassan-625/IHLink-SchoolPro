import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const page=readFileSync('src/pages/schoolpro/SchoolProResultTemplates.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261118100000_schoolpro_class_term_result_template_assignments.sql','utf8');

assert.match(migration,/unique \(school_id,class_id,term,session\)/i);
assert.match(migration,/c\.form_teacher_id=v_member/i);
assert.match(migration,/private\.schoolpro_is_exam_officer\(p_school\)/i);
assert.match(migration,/private\.schoolpro_is_school_admin\(p_school\)/i);
assert.match(migration,/p_template_config->>'storage_path'.*p_school::text/i);
assert.match(migration,/storage\.objects o[\s\S]*bucket_id='school-result-templates'/i);
assert.match(migration,/position\('\.\.' in p_template_config->>'storage_path'\)/i);
assert.match(migration,/schoolpro_result_template_assignment_audit/i);
assert.match(migration,/revoke insert,update,delete on public\.schoolpro_result_template_assignments from anon,authenticated/i);
assert.match(page,/schoolpro_result_template_assignments/);
assert.match(page,/schoolpro_set_class_result_template/);
assert.match(page,/p_class:selectedPupil\.class_id/);
assert.match(page,/p_term:term/);
assert.match(page,/p_session:session/);
assert.match(page,/p_template_config:choice\.config/);
assert.match(page,/classTemplateAssignment\?\.template_config/);
assert.match(page,/templateAssignmentFailed/,'Template lookup failures must block generation rather than silently falling back.');
assert.match(page,/Form Master must select and save the result design/);
console.log('PASS: Form Master class/term/session template assignments are school-scoped, authorized, audited and reused by result generation.');
