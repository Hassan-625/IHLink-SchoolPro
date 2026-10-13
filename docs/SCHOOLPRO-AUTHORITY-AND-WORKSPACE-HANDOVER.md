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

## Section leadership and results workflow — required design

### Section leadership roles and visibility
- Each school section must have its own assigned section leadership. The exact titles depend on school structure: Nursery Head Teacher; Primary Head Teacher and/or Headmaster/Headmistress; and for secondary levels, Principal and Vice Principal as configured by the school.
- The school must be able to assign one or more authorized leaders to a section (for example, Head Teacher plus Headmistress/Headmaster). Do not assume one generic school-wide coordinator covers all sections.
- A section leader's staff-portal context must be limited to the section(s) explicitly assigned to them. They can see the classes/arms, students, teachers, form masters, assessment records and results in those sections, plus the related operational modules needed for oversight—attendance, assignments, CBT, and other section-scoped records—subject to subscription entitlements and configured permissions.
- Section leaders must not see or manage other sections merely because they hold a leadership title. All section, class, arm, student, teacher, assessment and result boundaries must be enforced server-side, not just hidden in the UI.
- The portal should make the assigned section(s) clear and list only the relevant classes/arms and personnel. A leader assigned to Primary must not see Nursery, JSS or SSS data unless separately assigned and authorized.

### Required result-routing sequence
1. **Subject teachers** enter assessment marks only for their assigned subjects and classes/arms.
2. **Form masters/class coordinators** review and compile the results for each of their own assigned classes, using the teachers' submitted assessments and the students/results for that class. They submit the completed class result to the relevant **section head**, not directly to the Exam Officer.
3. **Section head / section leadership** reviews and compiles the submitted class results across the classes in their assigned section. They need section-scoped visibility of the section's classes, students, teachers, form masters, assessments and results to identify omissions and review the section's submissions. They then forward the section compilation to the **Exam Officer**.
4. **Exam Officer** reviews the section submissions, compiles/coordinates the overall examination result set across the school sections they are authorized to manage, and performs the permitted final review and publication actions. The Exam Officer must be able to publish results according to school rules.
5. **Publication may be partial by class/section.** The Exam Officer must be able to publish results for classes that have completed review even if another class or section has not submitted. Missing or unsubmitted classes must not block publication of already-approved classes. Later, when a pending class submits and completes the review chain, its results can be published separately without republishing or corrupting already-published results.
6. **Corrections after submission/publication** follow an authorized, auditable route: teacher requests a correction through the relevant section head; the section head reviews/forwards it to the Exam Officer; the Exam Officer performs or authorizes reopening of the appropriate scoped records. Preserve the prior published version, record the reason and actor, and audit every reopen, correction, approval and republication.

A person may perform multiple steps only if their current school-scoped roles, section/class assignments, and the configured workflow explicitly permit it. The Exam Officer's publish capability does not collapse the required form-master → section-head → Exam-Officer review chain. Platform Super Admin remains a platform-level authority and must not be conflated with school section leadership.

## Results-flow acceptance tests
- A subject teacher can enter marks only for assigned subjects/classes/arms and cannot submit another teacher's unassigned work.
- A form master sees the students, assigned teachers/assessments and results for their own class scope; can compile and submit that class result to its assigned section head; cannot bypass the section head by routing directly to the Exam Officer.
- Each configured section leader (including Head Teacher, Headmaster/Headmistress, Principal/Vice Principal where assigned) sees all and only the assigned section's classes/arms, students, teachers, form masters, assessments and results in the staff portal.
- Section leaders can review the submitted class results in their section, identify classes not yet submitted, compile/review the section result set and forward it to the Exam Officer.
- A section leader cannot enumerate or open another section's classes, roster, assessments, CBT, assignments, attendance or results unless explicitly assigned to that section.
- The Exam Officer can see section submissions within their authorized school scope, review and compile results, and publish completed classes even when another class/section remains pending.
- A late-submitting class can complete the same workflow and be published independently; previously published classes remain intact.
- Correction requests flow teacher → section head → Exam Officer, with reason, actor, timestamp and preserved prior publication history.
- Unauthorized school, section, class, arm, student, result and mutation attempts are denied server-side without leaking data.
- Verify the full route with real role-specific sessions and direct API/RLS checks, not only UI visibility or a passing build.

## Acceptance tests before sign-off

- Super Admin can access the platform school registry and administer a school without being enrolled as a member of that school.
- A proprietor/director sees only their own workspace and has no cross-school selector or discoverable foreign-school data.
- A normal user with multiple roles sees only authorized workspace(s), and role actions are evaluated against current school membership and assignments.
- All section-leadership and result-routing acceptance tests above pass in an end-to-end run.
- Approval, publication, correction and republication transitions are verified with audit history preserved.
- Do not migrate memberships, alter owner identities, modify production records, or reset credentials without a reviewed, reversible plan.

## Current implementation status at time of update

This document records the owner's requirements; it is not evidence that all controls are already implemented. Previous handover notes record some prior role, isolation, and result-workflow tests, but current production acceptance remains required. Track each check as: verified in production, implemented but unverified, not implemented, or blocked. A passing build or a live deployment alone is not functional acceptance.

## Immediate work order

1. Finish the report-card layout and generated A4 PDF validation in the current report-card branch/PR.
2. Resume the authorization/workspace isolation review against the rules above, including the prior open authorization/ownership-transfer work. Do not merge or execute an ownership transfer without inspecting its current PR state and risks.
3. Validate the end-to-end results workflow against the exact role boundaries above.
4. Continue the remaining SchoolPro handover checklist in priority order, recording evidence and outstanding blockers.