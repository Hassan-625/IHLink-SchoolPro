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

## Role-to-module permissions matrix — required design

Apply the least-privilege rules below in the staff portal and enforce them in server-side queries and mutations. These are school-scoped permissions and must also respect section, class/arm, subject, student assignment and subscription entitlements. A person can hold multiple roles; capabilities are the union of their currently assigned permissions only within each authorized scope.

| Module / action | Subject teacher | Form master / class coordinator | Section head / head teacher / headmaster / headmistress / Principal / Vice Principal |
|---|---|---|---|
| Student records and class roster | Only students in assigned subject/class/arm where needed for teaching | Full operational access to students in their assigned class(es) | View/manage within assigned section(s) |
| Teachers and staff assignments | View relevant assigned teaching context | View teachers serving their class; no general staff administration | View teachers and form masters in assigned section; perform section oversight permitted by role |
| Assessment marks | Enter/manage marks only for assigned subjects and classes | View/monitor assessments for their class; compile class results; no editing another teacher's subject marks unless separately authorized | View/review assessments and results across assigned section; no implicit right to change marks |
| CBT delivery | Create/manage/access CBT for their assigned subject(s) and classes, subject to permissions | View/manage class-level CBT activity for their class where needed | View/monitor CBT across assigned section |
| Question bank | Access and manage questions for their assigned subject(s), subject to permissions | Access the question bank relevant to subjects/classes they coordinate, for class oversight | View/monitor relevant question-bank activity in assigned section; editing requires explicit permission |
| Assignments | Create/manage subject assignments for assigned subjects/classes; view submissions relevant to that subject | Manage and monitor assignments for their assigned class, including cross-subject class oversight where configured | View/monitor assignments across assigned section |
| Daily attendance | No general attendance-taking permission by default; may view only if separately granted for a defined duty | Take and manage daily attendance for assigned class(es) | View/monitor attendance across assigned section; correction/admin rights require explicit permission |
| Library | No library administration by default | No library administration by default | May view/monitor section-relevant library usage only if granted; library operations remain with the school librarian |
| Promotion / class progression | No promotion permission by default | Initiate/recommend/execute promotion for their assigned class only where the configured school workflow permits | Review/approve/coordinate promotion for their assigned section and authorized levels |
| Result compilation and routing | Submit assessment marks; no class compilation unless separately assigned | Compile each assigned class result and submit it to the assigned section head | Review and compile results for assigned section; forward section compilation to Exam Officer |
| School-wide result review/publication | No | No, unless separately and explicitly assigned another authorized role | Section review only; Exam Officer owns authorized school-wide coordination/publication |
| Attendance, assignments, CBT and promotion across other sections | No | No | No, unless explicitly assigned to those sections |

### Module-specific constraints
- **Subject teachers:** Their subject is the primary boundary for marks, CBT and assignments. They must not automatically gain class-wide attendance, library, promotion, or other-subject administration because they are a teacher.
- **Form masters:** They have broad operational control for their own class(es), including student records, class roster, daily attendance, class assignments and CBT monitoring, and visibility of relevant teachers, assessments and results needed to coordinate the class. They can use the question bank relevant to the class's subjects. They do not administer the school library and do not promote students outside their assigned class scope.
- **Section leadership:** They oversee the assigned section and can view the section's classes, students, staff, form masters, assessments, results, attendance, assignments, CBT and promotion activity. Their view and actions must not cross into another section without an explicit additional assignment.
- **Librarian:** Library circulation, catalogue and library administration belong to the designated school librarian role, not ordinary teachers or form masters. Other roles may receive read-only or oversight access only when explicitly configured.
- **Promotion:** Promotion proceeds level by level under the school's configured academic structure. Form masters act only on their assigned class(es); section leaders review or authorize promotion within their assigned section/levels. Teachers do not receive promotion capability by default.
- **Explicit grants:** Any exception (for example, a teacher additionally appointed as a form master, or a section leader also assigned Exam Officer duties) must be represented as an explicit, auditable role/assignment and must not arise from the title alone.
- **Staff portal:** After login, users should see only the modules and records relevant to their roles and active workspace. Navigation hiding is a usability layer; every endpoint, query, export and mutation must enforce the same policy server-side.

## Role and module acceptance tests
- Subject teacher can manage CBT, question-bank items and assignments only for assigned subjects/classes, and cannot take daily attendance or promote students by default.
- Form master can take daily attendance and manage the operational modules for their own class, can view the teachers and relevant assessments/results for that class, and cannot administer library functions or promote another class.
- Section leader can view the staff, classes, students, attendance, assignments, CBT, question-bank activity, assessments, results and promotion activity for assigned section(s) only.
- Librarian can administer library functions; teacher/form-master accounts cannot mutate library records unless separately and explicitly granted.
- Promotion follows the school's class/level progression and only authorized form masters/section leaders can perform their permitted stage.
- For each role, test both allowed and denied actions through the UI and direct API/database policy paths, including attempts to access another class, subject, arm, section or school.

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

## Current continuation checkpoint — 15 October 2026

### Main handover track (do not skip or reset)
Continue the acceptance-gated sequence below. Subscription work is a parallel supporting track and does not change the order of the core application work.

- **A — Authentication, authorization and tenant isolation:** partially verified. Keep authenticated two-school isolation tests blocked until signed-in test access is available; do not claim the section is accepted without those checks.
- **B — Academic sessions, student population and class rosters:** next data-integrity gate after A. Verify session creation/selection, student population, class/arm roster loading and authorized staff visibility.
- **C — Assessments, class/subject averages, result review and publication:** only proceed after A and B acceptance. Verify the full role-scoped workflow and partial publication behavior.
- **D — Result Design Studio and custom Excel workbooks:** follow C. Preserve the four independent section templates (Nursery, Primary, Junior Secondary, Senior Secondary), school-uploaded template mapping, persistence, generated output, and tenant isolation.
- The known report-card print/CSS issue was explicitly deferred by the user. Do not let it block the next handover item; return to it later as agreed.

### Parallel subscription track — PR #104
- Draft PR: https://github.com/Hassan-625/IHLink-SchoolPro/pull/104
- Branch: `fix/schoolpro-annual-subscription-demo-upgrades-clean`
- Latest CI and payment-page validation passed at commit `022c5559e612b51224b4ba73e06ffaa1a608f3c9`. Subsequent Control Center navigation change is committed separately; rerun CI on the latest head before considering the branch validated.
- Requirements: Demo is free and lasts one year from approval; selected commercial plan remains distinct from active Demo entitlement; no paid price/payable invoice is displayed while Demo is active; paid subscriptions are annual; a 14-day grace period follows paid expiry; invoice remains visible in the dashboard and Control Center without email configuration; email can be enabled later; proprietor may request an annual upgrade; Super Admin reviews and issues a balance invoice; Finance manually verifies uploaded receipt; BillStack is for DataSub only.
- Proposed upgrade balance currently uses target annual catalog price minus the current stored paid annual subscription amount; downgrade handling and any time-based proration are not implemented. Confirm whether this simple price-difference credit is the intended commercial rule before production use.
- Migration and workflow still need SQL validation and functional tests. CI currently validates the frontend but does not establish that the migration is safe to apply to the production database.
- No production migration applied; no production subscription records modified; no merge or deployment performed.

### Next action on return
1. Re-check PR #104 CI against the latest commit and review the migration/RLS/function dependencies before any merge request.
2. Record the result of the subscription checks without changing the main A → B → C → D order.
3. Resume the core handover at the last verified acceptance gate, starting with A's remaining auth/tenant-isolation validation, then B.
