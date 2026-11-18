import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const page=readFileSync('src/pages/schoolpro/SchoolProResultTemplates.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261118100000_schoolpro_class_term_result_template_assignments.sql','utf8');
const subjects=readFileSync('src/pages/schoolpro/SchoolProSubjects.tsx','utf8');
const profiles=readFileSync('src/lib/resultTemplateProfiles.ts','utf8');
const integration=readFileSync('scripts/test-schoolpro-custom-result-template.integration.sql','utf8');
const workflow=readFileSync('.github/workflows/ci.yml','utf8');

assert.match(migration,/unique \(school_id,class_id,term,session\)/i);
assert.match(migration,/c\.form_teacher_id=v_member/i);
assert.match(migration,/private\.schoolpro_is_exam_officer\(p_school\)/i);
assert.match(migration,/private\.schoolpro_is_school_admin\(p_school\)/i);
assert.match(migration,/p_template_config->>'storage_path'.*p_school::text/i);
assert.match(migration,/storage\.objects o[\s\S]*bucket_id='school-result-templates'/i);
assert.match(migration,/position\('\.\.' in p_template_config->>'storage_path'\)/i);
assert.match(migration,/schoolpro_result_template_assignment_audit/i);
assert.match(migration,/create table public\.schoolpro_result_template_library/i);
assert.match(migration,/create table public\.schoolpro_result_template_section_mappings/i);
assert.match(migration,/section_key text not null check \(section_key in \('nursery','primary','junior_secondary','senior_secondary'\)\)/i);
assert.match(migration,/This custom template has not been mapped to the selected class section/i);
assert.match(migration,/schoolpro_set_result_template_sections/);
assert.match(migration,/v_template_config jsonb/);
assert.match(migration,/v_new_name:=left\(trim\(v_template_config->>'name'\),120\)/i);
assert.match(migration,/p_section_keys text\[\]/);
assert.match(migration,/add column template_id uuid not null/i);
assert.match(page,/schoolpro_set_result_template_sections/);
assert.match(page,/schoolpro_result_template_library/);
assert.match(page,/schoolpro_result_template_section_mappings/);
assert.match(page,/Add another custom template/);
assert.match(page,/The inbuilt sample is for testing only/);
assert.match(page,/custom result template mapped to this section must be assigned/i);
assert.match(migration,/revoke insert,update,delete on public\.schoolpro_result_template_assignments from anon,authenticated/i);
assert.match(page,/schoolpro_result_template_assignments/);
assert.match(page,/schoolpro_set_class_result_template/);
assert.match(page,/p_class:selectedPupil\.class_id/);
assert.match(page,/p_term:term/);
assert.match(page,/p_session:session/);
assert.match(page,/p_template_config:choice\.config/);
assert.match(page,/classTemplateAssignment\?\.template_config/);
assert.match(page,/templateAssignmentFailed/,'Template lookup failures must block generation rather than silently falling back.');
assert.match(page,/A custom result template mapped to this section must be assigned/);
assert.match(page,/templateLibrary\.length/);
assert.match(page,/draftMappedSections/);
assert.match(page,/schoolpro_result_template_library/);
assert.match(page,/if\(!matchingAssignment\)/,'Production generation must require an explicit class/term/session template assignment.');

assert.match(migration,/add column if not exists is_catalogue_entry boolean not null default false/i);
assert.match(migration,/schoolpro_subjects_canonical_name_uidx/i);
assert.match(migration,/create unique index[\s\S]*where is_catalogue_entry/i);
assert.match(migration,/pg_advisory_xact_lock\(hashtextextended\(new\.school_id::text,0\)\)/i);
assert.match(migration,/schoolpro_guard_canonical_subject_name/i);
assert.match(migration,/if tg_op='INSERT' then[\s\S]*pg_advisory_xact_lock/i,'The database guard must serialize all new subject inserts, not only flagged canonical rows.');
assert.match(subjects,/is_catalogue_entry:true/,'School Admin-created subjects must enter the canonical school catalogue.');
assert.match(subjects,/already exists in the school catalogue/i,'Duplicate subject creation must direct administrators to reuse the existing record.');
assert.match(migration,/create or replace function public\.schoolpro_form_master_add_class_subject/i);
assert.match(migration,/create table public\.schoolpro_class_subject_selection_audit/i);
assert.match(migration,/schoolpro_class_subject_selection_audit_read/i);
assert.match(migration,/insert into public\.schoolpro_class_subject_selection_audit/i,'A newly added class subject must be audited.');
assert.match(migration,/on conflict\(class_id,subject_id,session\) do nothing/i,'Form Master subject selection must be idempotent and preserve existing teacher assignment rows.');

assert.match(migration,/c\.form_teacher_id=v_member/i,'A Form Master may add catalogue subjects only to their assigned class.');
assert.match(migration,/s\.is_catalogue_entry/i,'Form Masters may select only canonical school-catalogue subjects.');
assert.match(migration,/grant execute on function public\.schoolpro_form_master_add_class_subject\(uuid,uuid,uuid,text\) to authenticated/i);
assert.match(page,/schoolpro_subject_assignments/,'Workbook mapping must use existing class subject assignments.');
assert.match(page,/schoolpro_form_master_add_class_subject/,'Form Masters select existing school catalogue subjects rather than creating duplicates.');
assert.match(page,/p_subject_row_mappings:subjectRowMappings/);
assert.match(page,/subject_row_mappings/);
assert.match(page,/resolveSubjectRowsById/,'Subject-to-row mapping must use stable subject IDs, not display-name matching.');
assert.doesNotMatch(page,/resolveSubjectRows\(/,'Name-based subject matching must not be used for production workbook generation.');
assert.match(profiles,/Every allocated class subject must have exactly one saved workbook row mapping/);
assert.match(profiles,/Two subjects cannot be mapped to the same workbook row/);
assert.match(migration,/previous_subject_row_mappings jsonb/i);
assert.match(migration,/new_subject_row_mappings jsonb/i);
assert.match(page,/forceFullCalc:true/);
assert.match(page,/calcMode:'auto'/);
assert.match(page,/const writeMappedCell=\(address:string,value:any\)=>\{const cell=sheet\.getCell\(mappedAnchor\(address\)\)\.master;if\(!cell\.formula\)cell\.value=value;\}/);
assert.match(migration,/Every subject allocated to this class and session must be mapped exactly once/i);
assert.match(migration,/Two subjects cannot be mapped to the same workbook row/i);


assert.match(page,/setGeneratedPreview\(preview\)/,'The selected student result must be populated into a reviewable workbook preview before finalization.');
assert.match(page,/Verification is not issued before this review/i);
assert.match(page,/async function confirmGeneratedResult/);
assert.match(page,/schoolpro-issue-result-verification/);
assert.ok(page.indexOf('setGeneratedPreview(preview)')<page.indexOf('schoolpro-issue-result-verification'),'Verification must be deferred until the user confirms the populated preview.');
assert.match(page,/invalidScoreRows/,'Missing, non-numeric and out-of-range assessment scores must block preview generation.');
assert.match(page,/formulaProblems/,'Broken/external/unsupported formula markers must be flagged before preview.');
assert.match(page,/unsupportedWorkbookFormula/,'Workbook formulas must be checked against the supported Excel formula profile.');
assert.match(profiles,/unrecognized\/custom formula function/,'Unknown or custom workbook functions must be blocked instead of trusting cached values.');
assert.match(profiles,/supportedWorkbookFormulaFunctions/,'Only the supported Excel formula function profile is accepted.');
assert.match(profiles,/unsupportedWorkbookFormula/,'Unknown custom functions and external/broken references are flagged.');
assert.match(profiles,/xlsx\|xlsm\|xlsb\|xls/,'External workbook references are distinguished from structured table references.');

assert.match(page,/Choose a writable cell; formulas are preserved/,'Mapped input fields must not target formula cells.');
assert.match(page,/Formula · /,'The preview must display formulas explicitly instead of stale cached values.');
assert.match(page,/Confirm preview and create workbook/);


assert.match(page,/Score input for/,'Assessment score cells mapped to formula cells must block generation.');
assert.match(page,/Subject-name input for/,'Subject name cells mapped to formula cells must block generation.');
assert.match(page,/mediaCells/,'Image and QR anchors must not overwrite formula cells.');
assert.match(page,/selectedDesignKey,subjectRowMappings/,'Changing an unsaved mapping invalidates an earlier populated preview.');
assert.match(page,/!scheme\?\.components\?\.length/,'Score validation must reject rows with no configured assessment scheme.');
assert.match(page,/maximum<=0/,'Score validation must reject invalid component maxima.');


assert.match(integration,/\\ir \.\.\/supabase\/migrations\/20261118100000_schoolpro_class_term_result_template_assignments\.sql/,'The disposable PostgreSQL fixture must execute the exact migration from this PR.');
assert.match(integration,/has_table_privilege\('authenticated','public\.schoolpro_result_template_assignments','INSERT'\)/i);
assert.match(integration,/can directly forge subject or template audit rows/i);
assert.match(integration,/unflagged duplicate subject insert bypassed the database guard/i);
assert.match(migration,/v_new_name:=left\(trim\(v_template_config->>'name'\),120\)/i,'Class assignments must snapshot the trusted library name, not a caller-supplied label.');
assert.match(integration,/Spoofed caller name/i,'The disposable database test must reject caller-supplied template-name spoofing.');
assert.match(integration,/non-Form-Master member assigned the class result workbook/i,'The assignment RPC must reject non-Form-Master, non-admin actors.');
assert.match(integration,/Form Master selected a subject outside their assigned class/i);
assert.match(integration,/Form Master selection overwrote an existing teacher allocation/i);
assert.match(integration,/subject_row_mappings=v_map/i);
assert.match(integration,/Two subjects cannot be mapped to the same workbook row/i);
assert.match(workflow,/custom-result-template-mapping-integration/,'CI must run the exact migration and subject/mapping authorization tests against disposable PostgreSQL.');

console.log('PASS: custom workbook library, canonical subject catalogue, Form Master selection, audited subject-ID mapping, populated pre-verification preview, score/formula validation and disposable PostgreSQL coverage.');
