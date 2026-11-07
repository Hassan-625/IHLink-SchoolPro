import fs from 'node:fs';
import assert from 'node:assert/strict';

const read=(p)=>fs.readFileSync(p,'utf8');
const app=read('src/App.tsx');
const sidebar=read('src/components/Sidebar.tsx');
const staff=read('src/pages/schoolpro/SchoolProStaffDiscipline.tsx');
const leave=read('src/pages/schoolpro/SchoolProLeave.tsx');
const student=read('src/pages/schoolpro/SchoolProDiscipline.tsx');
const classes=read('src/pages/schoolpro/SchoolProClasses.tsx');
const staffPage=read('src/pages/schoolpro/SchoolProStaff.tsx');
const parents=read('src/pages/schoolpro/SchoolProParents.tsx');
const deleteMigration=read('supabase/migrations/20261107200000_schoolpro_revoke_class_member_delete.sql');
const deleteSqlTest=read('supabase/tests/schoolpro_class_member_delete_security.sql');
const migrations=[
 'supabase/migrations/20261107210000_schoolpro_active_membership_operational_guards.sql',
 'supabase/migrations/20261107220000_schoolpro_staff_discipline_leave_workflows.sql',
 'supabase/migrations/20261107230000_schoolpro_student_discipline_case_management.sql',
 'supabase/migrations/20261107235900_schoolpro_central_active_membership_readers.sql',
 'supabase/migrations/20261107235930_schoolpro_active_member_rpc_guards.sql',
 'supabase/migrations/20261107235945_schoolpro_remaining_active_member_consumers.sql'
].map(read).join('\n');

assert.match(app,/SchoolProStaffDiscipline/);
assert.match(app,/SchoolProLeave/);
assert.match(app,/path="\\/schoolpro\\/staff-discipline"/);
assert.match(app,/path="\\/schoolpro\\/leave"/);
assert.match(staff,/schoolpro_create_staff_disciplinary_case/);
assert.match(staff,/schoolpro_submit_staff_disciplinary_response/);
assert.match(staff,/schoolpro_review_staff_appeal/);
assert.match(staff,/schoolpro_close_staff_disciplinary_case/);
assert.match(staff,/dismissal/);
assert.match(staff,/statusFilter/);
assert.match(staff,/actionFilter/);
assert.match(staff,/Search cases/);
assert.match(staff,/Appeals awaiting review/);
assert.match(staff,/Showing \{visibleCases.length\} of/);
assert.match(staff,/No cases match these filters/);
assert.ok(staff.indexOf('const memberNames=useMemo')<staff.indexOf('const visibleCases=useMemo'),'staff member-name map must be initialised before filtered cases');
assert.match(leave,/schoolpro_report_own_absence/);
assert.match(leave,/schoolpro_update_own_leave_reason/);
assert.match(leave,/schoolpro_review_leave_request/);
assert.match(leave,/statusFilter/);
assert.match(leave,/Search requests/);
assert.match(leave,/No records match these filters/);
assert.match(leave,/Showing \{visible.length\} of/);
assert.match(leave,/typeFilter/);
assert.match(leave,/Awaiting review/);
assert.match(leave,/Absence reports/);
assert.match(leave,/Reviewed \{new Date\(r\.reviewed_at\)/);
assert.match(leave,/absence_reported_at/);
assert.match(student,/guardian_contact_status/);
assert.match(student,/follow_up_outcome/);
assert.match(student,/student_response/);
assert.match(student,/assigned_to/);
assert.match(student,/statusFilter/);
assert.match(student,/categoryFilter/);
assert.match(student,/Search cases/);
assert.match(student,/Cases with follow-up scheduled/);
assert.match(student,/Showing \{visibleRows.length\} of/);
assert.match(student,/No cases match the selected filters/);
assert.match(student,/profile\\?\\.\\[0\\]/);
assert.match(classes,/flex flex-wrap items-center justify-between gap-3/);
assert.match(classes,/min-w-\\[980px\\]/);
assert.match(classes,/min-w-\\[480px\\]/);
assert.match(classes,/overflow-x-auto/);
assert.match(staffPage,/flex min-w-0 flex-wrap items-center gap-3/);
assert.match(staffPage,/aria-label="Staff access table, scroll horizontally to view all columns"/);
assert.match(staffPage,/min-w-\\[920px\\]/);
assert.match(staffPage,/overflow-x-auto overscroll-x-contain/);
assert.match(parents,/aria-label="School workspace"/);
assert.match(parents,/grid min-w-0 gap-5 xl:grid-cols-\\[390px_minmax\\(0,1fr\\)\\]/);
assert.match(parents,/min-w-\\[680px\\]/);
assert.match(parents,/Parent and guardian links table, scroll horizontally to view all columns/);
assert.match(parents,/overflow-x-auto overscroll-x-contain/);
assert.match(leave,/profile\\?\\.\\[0\\]/);
assert.match(staff,/profile\\?\\.\\[0\\]/);
assert.match(sidebar,/\\/schoolpro\\/staff-discipline/);
assert.match(sidebar,/\\/schoolpro\\/leave/);
assert.match(migrations,/m\\.status='active'/);
assert.match(migrations,/schoolpro_staff_disciplinary_events/);
assert.match(migrations,/schoolpro_leave_events/);
assert.match(migrations,/schoolpro_discipline_events/);
assert.match(migrations,/cannot be restored through the suspension workflow/);
assert.match(migrations,/schoolpro_is_house_master/);
assert.match(migrations,/schoolpro_member_leads_class/);
assert.match(migrations,/schoolpro_member_leads_student_section/);
assert.match(migrations,/schoolpro_set_section_leader/);
assert.match(migrations,/schoolpro_set_board_role/);
assert.match(migrations,/schoolpro_cached_access_schools/);
assert.match(migrations,/schoolpro_cached_staff_schools/);
assert.match(migrations,/schoolpro_can_author_cbt/);
assert.match(migrations,/schoolpro_can_manage_cbt/);

// Guard the non-negotiable direct class/member deletion boundary.
for (const table of ['schoolpro_classes','schoolpro_members']) {
  assert.match(deleteMigration,new RegExp('revoke delete, truncate on public\\.'+table+' from anon, authenticated','i'));
  assert.doesNotMatch(deleteMigration,new RegExp('create policy[^;]+on public\\.'+table+'[^;]+for (all|delete)','i'));
}
assert.match(deleteMigration,/drop policy if exists "School leaders delete classes"/);
assert.match(deleteMigration,/drop policy if exists "School leaders delete members"/);
assert.match(deleteMigration,/drop policy if exists "Super admin full access schoolpro_classes"/);
assert.match(deleteMigration,/drop policy if exists "Super admin full access schoolpro_members"/);
assert.match(deleteSqlTest,/has_table_privilege/);
assert.match(deleteSqlTest,/pg_policies/);
assert.match(deleteSqlTest,/TRUNCATE/i);

console.log('SchoolPro C0 workflow and class/member deletion source-contract checks passed.');
