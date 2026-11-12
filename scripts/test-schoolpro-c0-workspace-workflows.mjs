import fs from 'node:fs';
import assert from 'node:assert/strict';

const read=(p)=>fs.readFileSync(p,'utf8');
const app=read('src/App.tsx');
const houseMasterGate=read('src/components/SchoolProHouseMasterGate.tsx');
const houseMasterAccess=read('src/hooks/useSchoolProHouseMasterAccess.ts');
const styles=read('src/index.css');
const sidebar=read('src/components/Sidebar.tsx');
const staff=read('src/pages/schoolpro/SchoolProStaffDiscipline.tsx');
const leave=read('src/pages/schoolpro/SchoolProLeave.tsx');
const student=read('src/pages/schoolpro/SchoolProDiscipline.tsx');
const classes=read('src/pages/schoolpro/SchoolProClasses.tsx');
const staffPage=read('src/pages/schoolpro/SchoolProStaff.tsx');
const parents=read('src/pages/schoolpro/SchoolProParents.tsx');
const games=read('src/pages/schoolpro/SchoolProGames.tsx');
const studentsPage=read('src/pages/schoolpro/SchoolProStudents.tsx');
const attendancePage=read('src/pages/schoolpro/SchoolProAttendance.tsx');
const admissionsPage=read('src/pages/schoolpro/SchoolProAdmissions.tsx');
const deleteMigration=read('supabase/migrations/20261107200000_schoolpro_revoke_class_member_delete.sql');
const deletionMigration=read('supabase/migrations/20261107235950_schoolpro_workspace_deletion_lifecycle.sql');
const permissionReaderMigration=read('supabase/migrations/20261107235955_schoolpro_fix_permission_reader_board_role.sql');
const workspaceDeletionPage=read('src/pages/schoolpro/SchoolProWorkspaceDeletion.tsx');
const deleteSqlTest=read('supabase/tests/schoolpro_class_member_delete_security.sql');
const migrations=[
 'supabase/migrations/20261107130000_schoolpro_class_staff_lifecycle_foundation.sql',
 'supabase/migrations/20261107143000_schoolpro_active_membership_authorization.sql',
 'supabase/migrations/20261107160000_schoolpro_active_staff_and_class_assignment_guards.sql',
 'supabase/migrations/20261107180000_schoolpro_end_appointments_on_suspension.sql',
 'supabase/migrations/20261107183000_schoolpro_ended_appointment_access_guards.sql',
 'supabase/migrations/20261107190000_schoolpro_staff_appointment_history.sql',
 'supabase/migrations/20261107200000_schoolpro_revoke_class_member_delete.sql',
 'supabase/migrations/20261107210000_schoolpro_active_membership_operational_guards.sql',
 'supabase/migrations/20261107220000_schoolpro_staff_discipline_leave_workflows.sql',
 'supabase/migrations/20261107230000_schoolpro_student_discipline_case_management.sql',
 'supabase/migrations/20261107235900_schoolpro_central_active_membership_readers.sql',
 'supabase/migrations/20261107235930_schoolpro_active_member_rpc_guards.sql',
 'supabase/migrations/20261107235945_schoolpro_remaining_active_member_consumers.sql',
 'supabase/migrations/20261107235950_schoolpro_workspace_deletion_lifecycle.sql'
].map(read).join('\n');

assert.match(app,/SchoolProStaffDiscipline/);
assert.match(styles,/:where\(div,section,article\):has\(> table\)/);
assert.match(styles,/max-height: min\(70vh, 48rem\)/);
assert.match(styles,/overflow: auto/);
assert.match(app,/SchoolProLeave/);
assert.ok(app.includes('path="/schoolpro/staff-discipline"'));
assert.ok(app.includes('path="/schoolpro/leave"'));
assert.ok(app.includes('path="/schoolpro/workspace-deletion"'));
assert.ok(app.includes('<SchoolProHouseMasterGate><SchoolProHouseDashboard/></SchoolProHouseMasterGate>'));
assert.match(houseMasterGate,/useSchoolProHouseMasterAccess/);
assert.match(houseMasterGate,/access\\.allowed/);
assert.match(houseMasterAccess,/schoolpro_house_master_roster/);
assert.match(houseMasterAccess,/data\\.length>0/);
assert.match(houseMasterAccess,/teacher','class_teacher/);
assert.match(workspaceDeletionPage,/schoolpro_request_workspace_deletion/);
assert.match(workspaceDeletionPage,/schoolpro_cancel_workspace_deletion/);
assert.match(workspaceDeletionPage,/Only the school proprietor/);
assert.match(deletionMigration,/schoolpro_review_workspace_deletion/);
assert.match(deletionMigration,/schoolpro_execute_workspace_deletion/);
assert.match(deletionMigration,/target\.requested_by=auth\.uid\(\)/);
assert.match(deletionMigration,/target\.reviewed_by=auth\.uid\(\)/);
assert.match(deletionMigration,/deactivated_history_retained/);
assert.match(deletionMigration,/storage_objects_retained/);
assert.match(deletionMigration,/status='suspended'/);
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
assert.ok(student.includes('profile?.[0]'));
assert.match(classes,/flex flex-wrap items-center justify-between gap-3/);
assert.ok(classes.includes('min-w-[980px]'));
assert.ok(classes.includes('min-w-[480px]'));
assert.match(classes,/overflow-x-auto/);
assert.match(staffPage,/flex min-w-0 flex-wrap items-center gap-3/);
assert.match(staffPage,/aria-label="Staff access table, scroll horizontally to view all columns"/);
assert.ok(staffPage.includes('min-w-[920px]'));
assert.match(staffPage,/overflow-x-auto overscroll-x-contain/);
assert.match(parents,/aria-label="School workspace"/);
assert.ok(parents.includes('grid min-w-0 gap-5 xl:grid-cols-[390px_minmax(0,1fr)]'));
assert.ok(parents.includes('min-w-[680px]'));
assert.match(parents,/Parent and guardian links table, scroll horizontally to view all columns/);
assert.match(parents,/overflow-x-auto overscroll-x-contain/);
assert.match(games,/grid min-w-0 gap-5 xl:grid-cols-2/);
assert.match(games,/flex min-w-0 flex-wrap items-start justify-between gap-2/);
assert.match(games,/Competition result table, scroll horizontally to view all columns/);
assert.ok(games.includes('min-w-[760px]'));
assert.match(games,/overflow-x-auto overscroll-x-contain/);
const enrolmentCreate=studentsPage.slice(studentsPage.indexOf('async function create(e:FormEvent)'),studentsPage.indexOf('async function uploadPhoto('));
assert.ok(enrolmentCreate.includes('if(photoFile&&'));
assert.ok(enrolmentCreate.indexOf('.insert({')<enrolmentCreate.indexOf('if(photoFile){'));
assert.ok(enrolmentCreate.includes('setMessage(photoWarning?"Student enrolled."'));
assert.ok(!studentsPage.match(/id="enrol-student-photo"[^>]*required/));
assert.match(studentsPage,/Student photograph/);
assert.match(studentsPage,/enrol-student-photo/);
assert.ok(studentsPage.includes('accept="image/jpeg,image/png,image/webp"'));
assert.match(studentsPage,/no larger than 5 MB/);
assert.ok(studentsPage.includes('storage.from("school-result-templates").upload'));
assert.match(studentsPage,/photo_storage_path:path/);
assert.match(studentsPage,/Students enrolment table, scroll horizontally to view all columns/);
assert.ok(studentsPage.includes('min-w-[1040px]'));
assert.match(attendancePage,/grid min-w-0 grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4/);
assert.match(attendancePage,/Daily attendance register, scroll horizontally to view all columns/);
assert.ok(attendancePage.includes('min-w-[760px]'));
assert.match(attendancePage,/overflow-x-auto overscroll-x-contain/);
assert.match(admissionsPage,/grid min-w-0 grid-cols-1 gap-3 sm:grid-cols-2/);
assert.ok(admissionsPage.includes('min-w-[900px]'));
assert.match(admissionsPage,/max-h-\[60vh\] w-full min-w-0 overflow-auto/);
assert.match(admissionsPage,/whitespace-nowrap/);
assert.ok(leave.includes('profile?.[0]'));
assert.ok(staff.includes('profile?.[0]'));
assert.ok(sidebar.includes('/schoolpro/staff-discipline'));
assert.ok(sidebar.includes('/schoolpro/leave'));
assert.match(migrations,/m\.status='active'/);
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
assert.match(permissionReaderMigration,/bm\.role = 'administrator'/);
assert.doesNotMatch(permissionReaderMigration,/b\.role = 'administrator'/);

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
assert.match(deleteSqlTest,/pg_policy/);
assert.match(deleteSqlTest,/TRUNCATE/i);

console.log('SchoolPro C0 workflow and class/member deletion source-contract checks passed.');

// Workspace navigation and role catalogue must expose the modules already backed by production tables.
const appSource=read('src/App.tsx');
const sharedSource=read('src/pages/schoolpro/schoolShared.tsx');
const operationsSource=read('src/pages/schoolpro/SchoolProOperations.tsx');
const dashboardSource=read('src/pages/schoolpro/SchoolProLiveDashboard.tsx');
const schoolContextSource=read('src/hooks/useSchoolProContext.ts');
assert.ok(schoolContextSource.includes("profile?.role==='super_admin'?valid:"));
assert.ok(!schoolContextSource.includes("valid||localStorage.getItem('ihlink_schoolpro_admin_school')"));
assert.ok(dashboardSource.includes('ctx.schoolId&&rows.some(s=>s.id===ctx.schoolId)'));
assert.ok(dashboardSource.includes("search:id?'?school_id='+encodeURIComponent(id):''"));
assert.ok(!dashboardSource.includes('localStorage.setItem("ihlink_schoolpro_admin_school"'));
const rolesSource=read('src/pages/schoolpro/SchoolProRoles.tsx');
const auditPage=read('src/pages/schoolpro/SchoolProAuditLogs.tsx');
assert.ok(appSource.includes('path="/schoolpro/audit-logs"'));
assert.ok(appSource.includes('path="/schoolpro/admission-operations"'));
assert.equal(appSource.split('path="/schoolpro/discipline"').length-1,1);
assert.match(sharedSource,/Admissions Workspace/);
assert.ok(dashboardSource.includes('sections={schoolSections}'));
assert.match(sharedSource,/Audit Logs/);
assert.ok(operationsSource.includes("'schoolpro_audit_logs','audit-logs'"));
assert.ok(operationsSource.includes("'schoolpro_houses','house-dashboard'"));
assert.ok(operationsSource.includes("'schoolpro_competition_events','games'"));
assert.match(sharedSource,/Houses & House Allocation/);
assert.match(sharedSource,/Games & Competitions/);
assert.ok(operationsSource.includes("['Plans & Subscription','schoolpro_subscriptions','subscription']"));
assert.ok(operationsSource.includes("['Advanced Reports','schoolpro_results','reports']"));
assert.ok(operationsSource.includes("['Admission Events & Documents','schoolpro_admissions','admission-operations']"));
assert.ok(operationsSource.includes("['Houses & House Allocation','schoolpro_houses','house-dashboard']"));
assert.ok(operationsSource.includes("['Games & Competitions','schoolpro_competition_events','games']"));

const sidebarSource=read('src/components/Sidebar.tsx');
const permissionMapSource=read('src/lib/schoolPermissions.ts');
assert.match(sidebarSource,/isPlatformSchoolProSuperAdmin\?canonical/);
assert.match(sidebarSource,/canonical=isPlatformSchoolProSuperAdmin\?schoolSections/);
assert.ok(sidebarSource.includes("['/schoolpro/proprietor-dashboard','/schoolpro/admin-dashboard'].includes(location.pathname)"));
assert.match(permissionMapSource,/'admission-operations':'admissions'/);
assert.match(permissionMapSource,/'staff-discipline':'dashboard'/);
assert.ok(sidebarSource.includes("permissions.hasRolePermission('reports')"));
assert.ok(sidebarSource.includes("permissions.hasRolePermission('cbt')"));
assert.ok(sidebarSource.includes("permissions.hasRolePermission('branding')"));
const permissionGateSource=read('src/components/SchoolProPermissionGate.tsx');
assert.match(permissionGateSource,/SchoolProEntitlementGate feature=\{planFeature\}/);
assert.match(read('src/pages/schoolpro/SchoolProPermissions.tsx'),/promotions','games','notifications/);

assert.match(sharedSource,/Houses & House Allocation/);
assert.match(sharedSource,/Games & Competitions/);

assert.ok(operationsSource.includes("'schoolpro_staff_disciplinary_cases','staff-discipline'"));
assert.match(rolesSource,/Principal/);
assert.match(auditPage,/schoolpro_audit_logs/);

const staffRoleSource=read('src/lib/schoolStaffRoles.ts');
const staffFormSource=read('src/components/SchoolAccountForm.tsx');
const staffPageSource=read('src/pages/schoolpro/SchoolProStaff.tsx');
const invitationSource=read('supabase/functions/invite-school-staff/index.ts');
const principalInvitationMigration=read('supabase/migrations/20261107235958_schoolpro_principal_invitation_designation.sql');
assert.ok(staffRoleSource.includes("['principal', 'Principal']"));
assert.ok(staffFormSource.includes('schoolStaffRoles.map'));
assert.ok(staffPageSource.includes('row.position_title||'));
assert.ok(invitationSource.includes("const storedRole=role==='principal'?'administrator':role;"));
assert.ok(invitationSource.includes('position_title:positionTitle'));
const principalInvitationInserts=invitationSource.split('\n').filter(line=>line.includes("schoolpro_access_invitations').insert"));
assert.ok(principalInvitationInserts.length>=3&&principalInvitationInserts.every(line=>line.includes('role:storedRole')&&line.includes('position_title:positionTitle')));
assert.ok(principalInvitationMigration.includes('add column if not exists position_title'));
assert.ok(principalInvitationMigration.includes('invitation.position_title'));
