# SchoolPro Stage A–B Correction Register

**Date:** 2026-11-04  
**Status:** Active correction pass — Stage C is blocked until this register is resolved.  
**Repositories:** `Hassan-625/IHLink-SchoolPro`, `Hassan-625/IHLink-Admin`  
**Production:** Render SchoolPro + existing Supabase project `lnqsroyiybutkfngbyge`.

## Operating constraints

- Continue on the existing Supabase project. No MySQL, Aiven, extra Supabase project/branch, or database migration/cutover.
- Do not create test schools, workspaces, student records, staff records, or operational demo data.
- Use disposable PostgreSQL/fixture-based tests and existing production evidence only.
- Do not repeat accepted Stage A tenant-isolation tests without a concrete regression reason.
- Do not change IHLINK Academy's current Starter subscription directly. It remains Starter until the approved upgrade and payment workflow completes.
- Keep `docs/database-migration/MASTER-MIGRATION-HANDOVER.md` current after substantive work.
- Stage C (assessment calculations/review/publication) must not begin until the Stage A–B correction PRs are merged, their migrations are applied to the existing Supabase project, and the production Render deployment is verified.

## Stage A — authentication, onboarding and tenant access

1. Preserve accepted authentication, onboarding request submission, owner login routing, tenant isolation and role-scoped access.
2. Keep owner registration, school request status, review and provisioning transitions consistent between SchoolPro and Central Admin.
3. Ensure a proprietor with a submitted, reviewing, approved or provisioning request can find that request from the owner experience and Central Admin can see/review it.
4. Keep Super Admin school administration and ownership transfer controls out of the ordinary school dashboard; transfer ownership remains Control Center-only.
5. Maintain fail-closed public admission and result-PIN Turnstile protections.
6. Preserve prior two-workspace tenant-isolation acceptance. Do not recreate workspaces for acceptance.

## Stage B — required completion/correction areas

### B1. Sessions and calendar
- Preserve historical sessions, term dates, calendar change history and session-specific selectors.
- Switching the working session must not rewrite student enrolment history.
- Confirm all academic screens use the canonical session selector and support the intended historical range.

### B2. Student identity and family records
- Preserve student middle names in all forms, lists, searches, report cards and exports.
- Parent/guardian views must show guardian name, email, phone and relationship to each student.
- New guardian invitations capture contact phone without overwriting an existing non-empty global profile phone.
- Preserve transfer-out, graduation and historical student records; do not hard-delete academic history.

### B3. Rosters and progression
- Use session-specific enrolment history for class rosters, counts and historical reports.
- Preserve repeat, promotion, transfer and graduation history.
- Default repeat threshold remains below 45% overall average, with school-configurable subject pass requirements (e.g. English and Mathematics).
- Preserve graduation certificate issuance and transcript history.

### B4. Staff roles, dashboards and assignments
- Preserve least-privilege staff/class/subject assignments.
- Form Masters manage attendance within their assigned class/section scope; Subject Teachers do not receive attendance write permission by default.
- Section leadership and incremental score-entry workflows must remain intact.
- Audit dashboard coverage for every supported role. Current explicit dashboards are proprietor, administrator, teacher, parent and student. Specialist staff should land on their authorized workspaces: Game Master → Games; Discipline Master/Counsellor → Discipline; Bursar/Accountant → Fees; Exam Officer → Results; Registrar → Students; Admissions Officer/Receptionist → Admissions; Librarian → Library; Transport Manager → Transport; Hostel Manager → Hostel; Inventory Officer → Inventory; Nurse → Medical; HR Officer → Staff; IT Admin → Roles & Permissions. Vice Principal and Head Teacher retain the role-filtered school administration dashboard. Assigned judges need the My Judging Panel link without requiring the full Games management permission.

### B5. Attendance and academic operational access
- Confirm attendance read/write access follows the role and assignment model, not generic teacher membership.
- Verify section-level attendance and student lists remain scoped to the active session and assigned section.
- Keep teacher score entry separate from attendance authority.

### B6. Houses, Games, Sports and competitions
- Starter must include the Games & Sports module; it is a core school-management capability, not a Professional or Enterprise differentiator.
- Add “Games & Sports” to the school-registration module selection.
- Make the Games & Sports dashboard visible to school owners, principals, school administrators and Game Masters, while retaining least-privilege role checks.
- New schools receive configurable Red, Green, Blue and Yellow houses; support additional/renamed houses.
- Teaching staff can be appointed as House Masters with appointment history.
- Support balanced automatic student allocation and audited manual assignment.
- Support sports, athletics, debates, quizzes, cultural and academic competitions; staff judge panels (chief judge, judge, timekeeper, referee and moderator); rubrics, eligibility, score limits, weighted results, approvals/publication, penalties, awards and house standings.
- Assigned judges need a visible “My Judging Panel” entry point in the staff/teacher navigation; judge data remains restricted to active assignments.
- The Games screen and judge portal already exist in source. The correction is to close missing navigation/permission/plan integration, not rebuild the B6 database foundation.

### B7. Standard reports vs Enterprise Advanced Reports
- Standard report cards, student results, class broadsheets, ordinary class exports, attendance summaries, behavioural ratings and historical reports remain available on Starter, Professional and Enterprise, subject to staff role permissions.
- CBT is the Professional differentiator; Enterprise inherits CBT.
- Enterprise adds Advanced Reports: school/class/subject performance analytics, student progress trends, attendance analytics, assessment analytics, progression analytics, management summaries and enhanced Excel/PDF exports.
- Enterprise custom branding is request-and-approval based; it is not unrestricted self-service.
- Keep standard `reports` role permission separate from the `advanced_reports` subscription entitlement. Do not gate ordinary broadsheets or standard class report printing behind Enterprise.

### B8. Plans, registration and upgrade workflow
- Plan split: Starter = core school management + standard reports + Games & Sports; Professional = Starter + CBT; Enterprise = Professional + Advanced Reports + custom-branding request eligibility.
- Show each plan's included features and annual price in the public pricing page and school subscription page. The current paid activation workflow is annual-only; do not advertise monthly/termly billing until payment and activation support those cycles.
- Registration module selection must include Games & Sports.
- Use one authoritative entitlement catalogue. Current live data has two catalogues: `schoolpro_plan_catalog` for tier feature flags and `schoolpro_subscription_catalog` for billing prices; the subscription catalogue's feature arrays are empty. Although monthly/termly/annual columns contain values, the live admin activation workflow explicitly supports annual billing only; only annual prices should be advertised. The plan catalogue also has a legacy `premium` tier and separate `term_price` values. Reconcile the display to the authoritative feature catalogue and configured price catalogue; do not silently invent or overwrite prices.
- Upgrade lifecycle: school request → IHLink review → approve/reject with reason → invoice/outstanding amount → school payment → IHLink verification → atomic plan activation and audit history.
- Approval alone must not activate the higher tier. Calculate any existing-payment credit/proration from an explicit billing policy before showing a final amount.
- Central Admin needs a subscription/upgrade queue, review, payment verification, active subscription oversight and audited plan/feature pricing controls.

### B9. Missing dashboard and navigation inventory
- Existing routes include proprietor, admin, teacher, parent, student, Games management and Judge Portal.
- Current confirmed gap: `schoolpro_user_permissions` omits `games` for owner/principal/administrator/board-administrator permission arrays, although the Games page expects those roles to manage it. Game Master already has `games`.
- Current confirmed gap: registration module choices omit Games & Sports.
- Current confirmed gap: teacher navigation omits My Judging Panel even though the judge portal exists.
- Current confirmed gap: there is no distinct Game Master landing dashboard; the role falls back to the generic admin dashboard. Make Games the Game Master's landing destination while retaining the Games permission guard.
- Continue a route-to-sidebar-to-role-permission comparison for each dashboard/module and record only actual missing or inaccessible pages. Do not assume a module is missing merely because it is not a standalone dashboard.

## Confirmed source/database inconsistencies found on 2026-11-04

1. The live Games screen exists at `/schoolpro/games` and is linked in the shared school administration navigation, but the live role-permission function does not grant `games` to school owners, principals, board administrators or ordinary school administrators. The UI's `canManage` logic expects those roles to manage the module, so database permission is the blocker.
2. The Game Master role already receives `games`, but its login landing route is the generic `/schoolpro/admin-dashboard`, not the Games screen.
3. Registration's `availableModules` list does not include Games & Sports, despite the B6 database and UI foundation.
4. Teacher navigation has no My Judging Panel link, although `/schoolpro/judge` and the assigned-judge portal exist.
5. The public pricing page reads `features` from `schoolpro_subscription_catalog`, whose live feature arrays are empty. The authoritative tier entitlement flags are in `schoolpro_plan_catalog`. Pricing currently shows annual prices only even though the subscription catalogue contains monthly, termly and annual prices.
6. The live plan feature guard maps the generic `reports` permission to `advanced_reports`, and the `/schoolpro/broadsheet` route is explicitly wrapped in the Enterprise entitlement gate. This contradicts the agreed rule that standard broadsheets and ordinary reports remain available on Starter and Professional. Separate standard report role permission from Enterprise advanced analytics.
7. The live plan catalogue contains Starter, Professional, Enterprise and legacy Premium. Its `term_price` values are separate from the billing prices in `schoolpro_subscription_catalog`. Keep Premium as legacy/internal until its migration/display policy is resolved; do not show a fourth public plan without an explicit decision.

## Implementation sequence

1. Close B6 Starter entitlement, owner/admin permissions, Game Master landing, registration selection and judge navigation.
2. Correct standard-report entitlement so Starter/Professional retain ordinary broadsheets and printing; keep Enterprise Advanced Reports separately guarded.
3. Reconcile public pricing display with the two existing catalogues and add feature comparisons for all three public plans.
4. Implement the upgrade request/review/payment/verification/activation workflow across SchoolPro and IHLink Admin.
5. Complete the remaining Stage A–B dashboard/role/navigation matrix and targeted regression tests.
6. Update the master handover with exact migration, CI, PR, Supabase and Render outcomes.
7. Only after all correction gates pass, proceed to Stage C.

## Release gate

No Stage C implementation until:
- correction migrations are merged and recorded in the existing Supabase project;
- role/route/navigation and plan-entitlement regression tests pass;
- standard reports work on Starter/Professional and advanced analytics remain Enterprise-only;
- Games & Sports is visible and usable on Starter for authorized school roles;
- Central Admin and school-side subscription workflow is implemented and validated;
- PRs are merged and the Render production deployment is confirmed.


## Additional subscription workflow findings from the Central Admin repository

- Central Admin already contains `AdminSchoolProOnboarding`: it reviews/rejects onboarding requests, provisions a workspace, issues an unpaid annual invoice, and can approve a calendar-reviewed demo.
- Central Admin already contains `AdminSchoolProSubscriptions`: it lists schools/subscriptions and allows a Super Admin to activate or change a tier through a direct Control Center override RPC with a reason. This is an administrative override, not the requested school-initiated upgrade approval workflow.
- The live SchoolPro subscription table inventory includes `schoolpro_subscription_catalog`, `schoolpro_subscription_intents`, `schoolpro_subscription_payments`, `schoolpro_subscription_plans` and `schoolpro_subscriptions`; no dedicated SchoolPro upgrade-request table was found.
- The remaining upgrade workflow must add a school-initiated request with target plan/cycle, current subscription snapshot, price/credit calculation, review status and audit history; Central Admin must approve/reject with reason, issue the outstanding payment request, verify the received payment, and only then activate the higher tier. The existing manual activation action must remain a separately audited emergency/administrative override.
- The current custom branding admin page can edit branding records directly. Enterprise custom branding must instead be request-and-approval based for the school, with IHLink provisioning/approval controls and entitlement enforcement. Do not grant Starter/Professional self-service branding.


8. The generic admin dashboard also queried student, class and invoice data for every operational role, regardless of the role's permission set. That can cause specialist roles without `students` or `finance` access to receive a dashboard load error, and it risks exposing finance summaries to roles that should not see them. The correction branch now uses the live role-permission hook to query and render only permitted student/class/finance data, and clears previous workspace data while a new workspace's permissions resolve.


9. Specialist role landing routes are now being aligned to their own authorized operational workspace rather than sending every role to the generic admin dashboard. The assigned-judge link also needs its own navigation mapping: active judges should be able to open the judge portal without receiving the Games Master management permission.


10. The first standard-report correction removed the Enterprise check from the database permission function and kept the dedicated `/schoolpro/reports` page behind the explicit Enterprise Advanced Reports gate. A second frontend check in `permissionPlanFeature()` still mapped the generic `reports` permission to `advanced_reports`, which continued to hide standard broadsheets/reports in Starter and Professional. The frontend permission-to-plan map is now aligned with the database: only CBT and custom branding map to plan entitlements; Advanced Reports remains protected by its dedicated route-level entitlement gate.
