# SchoolPro Authority, Workspace and Results Workflow Handover

Updated: 13 October 2026

## Authority boundaries — binding requirements

### Platform Super Admin
- Super Admin is a platform-level authority, not a school membership or school role.
- The authorized platform Super Admin can discover registered school workspaces and administer any school and its permitted records from the platform-level control surface.
- Super Admin access must not depend on having a proprietor, director, teacher, or other membership in the school being administered.
- Keep the owner's platform Super Admin identity distinct from ordinary school membership. Do not silently remove, downgrade, or rewrite memberships/roles without an explicit, audited migration plan.

### School owner / proprietor / director
- Each school workspace belongs to that school and its authorized owner/director account.
- The proprietor/director may administer their own workspace, staff, roles, students, classes, arms, subjects, and school records according to their school permissions and subscription.
- A school owner must not be shown a cross-school selector, a list of other registered schools, or another school's results, roster, records, or dashboard data.
- The platform Super Admin's account may be separate from the school proprietor account. Where separation is needed, provision a distinct school-owner account through the supported account flow; do not invent credentials or expose secrets.

### Users with multiple roles or school memberships
- A person may hold multiple legitimate school-scoped roles (for example, teacher, form master/class coordinator, and Exam Officer), and may have membership in more than one school.
- Role capability is evaluated in the context of the selected/authorized workspace, assignment, and action. Multiple roles do not imply platform-wide Super Admin privileges.
- Do not treat Super Admin as a school membership. Do not let ordinary users enumerate schools simply because they have multiple memberships.
- Every query and mutation must be scoped server-side to the authenticated user's authorized school and, where applicable, section, class, arm, subject, and assigned students. UI hiding alone is not authorization.

## Results workflow

The intended result process must respect role and assignment permissions:
1. Teacher enters assessment marks for assigned subjects/classes/arms.
2. The authorized class coordinator/form master generates and submits the result for their permitted class scope.
3. Exam Officer reviews submitted results and performs only the allowed corrections/review actions.
4. An authorized approver approves the result according to the configured school workflow.
5. Publication makes the approved result available to the intended school users (students/parents/staff) under the result-release rules.
6. Corrections/reopening and republication require authorization, preserve published history, record reasons and audit events, and must not silently erase prior results.

The application must not assume that one user has only one role. A user may perform more than one step only where their current roles, assignments, and configured workflow explicitly authorize it. Super Admin oversight is a platform authority and must not be confused with ordinary school workflow membership.

## Acceptance tests before sign-off

- Super Admin can access the platform school registry and administer a school without being enrolled as a member of that school.
- A proprietor/director sees only their own workspace and has no cross-school selector or discoverable foreign-school data.
- A normal user with multiple roles sees only authorized workspace(s), and role actions are evaluated against current school membership and assignments.
- Teacher access is limited to assigned subject/class/arm/student scope.
- Coordinator access is limited to their designated coordination scope.
- Exam Officer can access the appropriate submitted result roster for their authorized school/scope and review results.
- Unauthorized school, section, class, arm, student, result, and mutation attempts are denied server-side and do not leak data.
- Approval, publication, correction, and republication transitions are verified end-to-end, with audit history preserved.
- Do not migrate memberships, alter owner identities, modify production records, or reset credentials without a reviewed, reversible plan.

## Current implementation status at time of update

This document records the owner's requirements; it is not evidence that all controls are already implemented. Previous handover notes record some prior role, isolation, and result-workflow tests, but current production acceptance remains required. Track each check as: verified in production, implemented but unverified, not implemented, or blocked. A passing build or a live deployment alone is not functional acceptance.

## Immediate work order

1. Finish the report-card layout and generated A4 PDF validation in the current report-card branch/PR.
2. Resume the authorization/workspace isolation review against the rules above, including the prior open authorization/ownership-transfer work. Do not merge or execute an ownership transfer without inspecting its current PR state and risks.
3. Validate the end-to-end results workflow against the exact role boundaries above.
4. Continue the remaining SchoolPro handover checklist in priority order, recording evidence and outstanding blockers.