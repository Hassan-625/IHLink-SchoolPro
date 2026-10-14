# SchoolPro Master Handover & Continuation Guide

**Version:** 1.0  
**Compiled:** 14 October 2026  
**Purpose:** Shared working reference for the user and assistant. Update this same guide after every verified action.

## 1. Operating rules

- Preserve the original handover sequence. New defects and requirements are additions to the existing plan, not replacements for it.
- Track each item as **PASS — evidenced**, **IMPLEMENTED — verification pending**, **OUTSTANDING**, **DEFERRED — preserve**, or **BLOCKED**.
- A chat statement or green CI run is not proof of production behavior. Record what was tested, in which environment, with which role, and the evidence link.
- Render is the user's SchoolPro deployment target. Do not treat a Vercel preview/check as proof of a Render deployment.
- Do not merge or deploy without a clear evidence summary and the user's approval.
- Use read-only inspection first for production database, roles, storage policies, and RPCs. Do not change production data or policies without a verified remediation plan and approval.
- Preserve marks, enrolments, published historical results, transcripts and certificates. Do not delete marks/enrolments as a shortcut to reset a school year.
- The recorded rollover requirement is to unpublish 2025/2026 results without deleting marks/enrolments, start 2026/2027 fresh, and preserve published 2000/2001–2024/2025 history.
- Never expose Supabase service-role keys or other secrets.

## 2. Exact resume point from the previous chat

Repository: [Hassan-625/IHLink-SchoolPro](https://github.com/Hassan-625/IHLink-SchoolPro)  
Branch reported and confirmed present: `fix/result-design-section-selection`  
Latest relevant commit: [a4d74263dd924fade81f66e278fdc002bbaf5724](https://github.com/Hassan-625/IHLink-SchoolPro/commit/a4d74263dd924fade81f66e278fdc002bbaf5724) — `test: fix document scope regression test syntax`.

Other relevant commits:
- [16cf608f9c4f150e8078c6fe9f38e21bdbc710cc](https://github.com/Hassan-625/IHLink-SchoolPro/commit/16cf608f9c4f150e8078c6fe9f38e21bdbc710cc) — section normalization correction.
- [c9cd4f2aa77c1acefb24e1a7158696ebeab1c3d9](https://github.com/Hassan-625/IHLink-SchoolPro/commit/c9cd4f2aa77c1acefb24e1a7158696ebeab1c3d9) — unique workbook and mapping regression coverage.
- [3c4138a0dfab575ad00e4aa084dcda1b338b056d](https://github.com/Hassan-625/IHLink-SchoolPro/commit/3c4138a0dfab575ad00e4aa084dcda1b338b056d) — removed obsolete fallback assertions.
- [561855ca7014c5387490ac4450da1613e3ba4e0b](https://github.com/Hassan-625/IHLink-SchoolPro/commit/561855ca7014c5387490ac4450da1613e3ba4e0b) — reported synthetic report-card print verification.

**Live state checked in this continuation:** branch exists; on commit `a4d74263...`, SchoolPro CI run #664 passed and payment-page validation run #424 passed. The combined commit status also reported Vercel success. The latter is not Render deployment evidence. The supplied previous chat said changes had not been merged or deployed to Render. No merge or deployment has been performed in this continuation.

**Next action in the original sequence:** test whether all four result designs remain independent when saved, reloaded and used to generate workbooks. Automated checks currently exercise the resolver and fixtures; authenticated end-to-end acceptance is still outstanding. Do not skip straight to merge/deploy.

## 3. Master workstream register

### A. Core application, authentication and role access
- Preserve the standalone SchoolPro application, session handling, school workspace context, role permissions, routes, branding, portals and backend integration.
- Super Admin must have appropriate global administration capability, while ordinary school users remain scoped to their own school.
- Verify access in the actual app, including Super Admin workspace selection and relevant staff roles.
- **Status:** historical progress reported; live verification required after relevant changes.

### B. Academic records, student population and class loading
- Verify session, term, school, class, arm, active enrolment, subject assignments and results load for Super Admin and authorized staff, including Exam Officer.
- Test empty and populated states, paging, errors and refresh/navigation.
- A prior Results portal session/roster fix was reported at commit [29856dff17ea8a3bc8bb31b7900967b7df9d316b](https://github.com/Hassan-625/IHLink-SchoolPro/commit/29856dff17ea8a3bc8bb31b7900967b7df9d316b), with live verification reported in earlier chat. Revalidate after later changes.
- **Status:** previously reported pass for that defect; do not infer that every related route is certified.

### C. Assessments, Class Subject Averages and approval workflow
- Verify assessment entry, score edits, grading, averages, positions, broadsheets, result review and publication.
- Preserve the required sequence: teacher submits → form master checks → section head compiles/reviews the assigned section → Exam Officer reviews and publishes class-by-class.
- Enforce section-scoped permissions, partial publication and late-submission handling.
- **Known anomaly:** Basic 5 A, First Term 2025/2026 reportedly had 40 active students and 400 published results; 37 records appeared linked to Basic 4 A subject IDs and 3 to Basic 5 A subject IDs. Trace the underlying subject/student/session relationships and calculation joins before any production data change.
- Template tests do not resolve this academic-integrity issue.
- **Status:** outstanding until source linkage and calculated results are verified.

### D. Result Design Studio and custom workbook templates
Schools must be able to upload their own supported Excel workbook, map fields to their preferred school standard, save/reload mappings, replace templates, and use the chosen design to generate real student results. Their selected design should replace the applicable default. Support the four sections independently:
1. Nursery
2. Primary
3. Junior Secondary
4. Senior Secondary

Acceptance must prove:
- Each section has a distinct workbook path, student-field mapping and assessment-column mapping.
- Saved values survive navigation and reload.
- Replacing one section's workbook/mappings does not affect another section.
- An unconfigured/unknown section falls back to the same school's default and document type.
- Generated XLSX output uses the selected section's saved mappings, not merely the preview.
- Generated result data is correct for the selected student, term and session.
- First Term has no previous-term columns; Second Term includes First Term history and cumulative average; Third Term includes both previous terms and cumulative average.
- Inspect the actual generated file and formulas/formatting.

**Reported progress:** section labels such as Basic 1, Basic 6, JSS 2 and SSS 1 are normalized before template selection. Four-section resolver regression coverage and latest CI were reported passing. The test `scripts/test-result-section-data.mjs` uses distinct fixtures and verifies resolver mappings, school identity retention, independent saves, and roster paging. It does not by itself prove the authenticated browser flow from database save/reload through generated workbook.
**Status:** active; end-to-end acceptance outstanding.

### E. Document Studio and cross-school security
- Review database RLS/policies, template-to-school relationships, storage upload/read policies, default-template RPC, finalization RPC, issuance authorization, signed-output access and audit records together.
- Test at least two schools and the intended roles. Neither school may read/update the other's templates, mapping, issued document, storage object or output.
- Ensure template-management roles and file-upload roles are intentionally aligned; do not broaden permissions blindly.
- Confirm issued documents cannot be overwritten and revoked documents cannot be rendered.
- **Reported progress:** document-rendering regression checks reject a cross-school template before source storage access, validate school-scoped assets, and cover portrait/landscape PDF design snapshots. The relevant test passed in CI. These are automated regression tests, not full production authorization certification.
- **Status:** partially verified; role-matrix and authenticated acceptance outstanding.

### F. Historical data, academic-year rollover and progression
- Preserve historical results, transcripts, certificates and audit trails.
- Verify transfer, promotion, graduation and new-year enrolment workflows without losing historical identifiers or marks.
- Apply the agreed rollover rule: 2025/2026 results may be unpublished without deleting marks/enrolments; 2026/2027 starts fresh; published 2000/2001–2024/2025 history remains preserved.
- **Status:** outstanding verification; data preservation is mandatory.

### G. Other operational modules and portals
Maintain module-by-module acceptance for admissions, attendance, assignments, lessons, library, clinic, transport, hostel, payroll, leave, CBT/question bank, stores, documents/certificates, and parent/student/staff portals. Use controlled IHLink Academy test data where required. Verify each workflow, not only whether a page loads.
- Earlier chats included staff attendance/dashboard and enrolment-loading symptoms. Recheck current behavior rather than assuming the later fixes cover every route.
- **Status:** outstanding / verify module by module.

### H. Fees, subscriptions and payment reconciliation
- Verify school fee collection, allocations, receipts, arrears, bursar/proprietor controls, unpaid-fee result locks, subscription invoices, plan limits and reconciliation.
- Keep school fee income separate from IHLink subscription revenue.
- **Pricing discrepancy to resolve before production edits:** earlier context reported plans at ₦50,000 / ₦100,000 / ₦150,000; a later requirement specified Starter ₦30,000/month, Professional ₦50,000/month and Enterprise ₦100,000/month, editable in Command Center. Determine the approved current configuration from the live product/decision record rather than guessing.
- **Status:** outstanding reconciliation.

### I. Release, APK, Render deployment and support readiness
- Verify approved source commit, release artifact provenance, APK installation/launch, environment configuration, migrations, Render service health, and critical live workflows.
- SchoolPro 1.0.4 APK was mentioned in earlier context; verify whether it is current and corresponds to approved source before calling it final.
- Maintain deployment, rollback, support, backup/recovery, DNS/email/hosting and operational guides.
- **Status:** final certification outstanding.

### J. Platform-wide security, performance and resilience
- Verify RLS, tenant isolation, sensitive document access, audit logging, backups/restore, failure handling, performance and known limitations.
- Earlier ecosystem readiness notes said some HTTPS, support/legal, RLS/build/migration checks had been completed; live payment settlement, transactional email, provider redundancy, backup/recovery and a leaked-password protection limitation remained open. Confirm current state and keep ecosystem issues separate from SchoolPro-specific defects.
- A previous platform note referenced Vite Supabase URL/public-key configuration, `VITE_APP_PLATFORM`, routing URLs and build/publish configuration across 13 Render frontends. Treat as ecosystem deployment work, not as permission to change SchoolPro configuration blindly.
- Never expose service-role keys; earlier guidance was to use the intended Supabase Edge Function for BillStack webhook handling.
- **Status:** partially verified; revalidate current state.

## 4. Explicit deferrals — do not silently close
- **Persistent A4 print overflow/live print verification:** previously deferred. A later synthetic PDF test reportedly passed, but synthetic output does not by itself close the original live issue. Return to it at the agreed point in the handover.
- **Academic-calendar detour:** previously deferred; preserve for later.
- **Historical subject/enrolment mapping:** deferred in one checkpoint but connected to the Basic 5 A subject-ID anomaly. Keep it visible and reconcile its priority with the original sequence; do not change production records without an approved, evidence-based plan.
- Add any further deferrals from the original full handover when reconciled. Never invent a deferral or drop one.

## 5. Report-card print acceptance
- First Term: no previous-term columns.
- Second Term: First Term history and cumulative average.
- Third Term: both previous terms and cumulative average.
- Verify subject table, attendance, skills and remarks.
- Verify A4 portrait, margins, page breaks, overflow and one-student-per-page using synthetic fixtures and authenticated acceptance data.
- The prior chat reported a 12-page synthetic PDF, A4 portrait, one page per synthetic report, with CI at commit `561855ca...`. This is synthetic-test evidence only, not live print certification.

## 6. Result Design Studio acceptance checklist
- [ ] Confirm current branch/head SHA, PR state and latest required CI before changing anything.
- [ ] Save a unique workbook and mappings for each of the four sections.
- [ ] Leave the page and reload; verify the selected workbook and mappings persist.
- [ ] Replace one section's workbook and prove the other three remain unchanged.
- [ ] Generate a workbook for an authenticated test student in each section.
- [ ] Inspect populated fields, assessment cells, subject rows, formulas and formatting in each generated file.
- [ ] Verify term history for First/Second/Third Term.
- [ ] Test unknown-section fallback to the same school's default.
- [ ] Test two schools and verify isolation across database records, storage, issued docs and outputs.
- [ ] Verify role matrix for edit, upload, replacement, default selection, finalization and output download.
- [ ] Verify audit events, errors and no false-success states.
- [ ] Record CI URLs, commit, role, environment, output artifact and timestamp.

## 7. Merge/deploy gates
1. Confirm actual GitHub branch/PR/CI state.
2. Functional acceptance passes for all four section templates and generated outputs.
3. Authorization, storage policies, RPC checks and cross-school isolation pass.
4. The Basic 5 A subject-ID anomaly has a documented resolution plan; no unintended data mutation occurred.
5. CI is green, review findings are resolved, and rollback/recovery is available.
6. Obtain the user's approval before merge or deployment.
7. After deployment, verify Render service health and critical live workflows; record the deployed commit and deployment ID.

## 8. Continuation protocol
- Start each continuation by reading this guide and checking actual GitHub/Render state.
- Continue the next unblocked action in the original sequence; do not restart a finished item or skip ahead.
- Use read-only inspection first for production/security tasks.
- After every action, update status and evidence here.
- Add every newly discovered defect, requirement, dependency and explicit deferral to this register.
- When the user says “next,” continue from the next unblocked register item rather than guessing.

## 9. Immediate next action
Run the authenticated saved-template → reload → generate → inspect-output acceptance for Nursery, Primary, Junior Secondary and Senior Secondary. Before that, confirm whether a relevant pull request is open and its exact status; the PR number was not established by the available evidence. Do not merge or deploy during this validation. Once this is proven, proceed to the combined document-security role matrix and school-isolation acceptance, then follow the larger handover sequence.


## 10. Continuation update — 14 October 2026, document authorization audit

**Current review branch head:** [4968a60903a5246c381c235c678c8b68987c318f](https://github.com/Hassan-625/IHLink-SchoolPro/commit/4968a60903a5246c381c235c678c8b68987c318f). PR [#103](https://github.com/Hassan-625/IHLink-SchoolPro/pull/103) remains open and draft. No merge or deployment was performed. Render's live SchoolPro deployment was still commit `29856dff17ea8a3bc8bb31b7900967b7df9d316b` when checked.

### New read-only production finding

The connected Supabase database's `pg_policies` output showed that `authorized staff update draft document issues` had a `WITH CHECK` condition limited to `status = 'draft'` and `issued_at IS NULL`. It did not re-check the new row's school access, documents-module entitlement, or null output path. The existing `students read own issued documents` policy also used the tautology `st.school_id = st.school_id` rather than binding the student to the issue's school. The guardian read policy did not explicitly bind the ward's school to the issue's school. The draft issue insert policy also did not verify that a non-null student belongs to the same school as the issue.

These are policy-level tenant-binding gaps found by inspection, not proof that an exploit has occurred. A separate read-only trigger/function inspection found existing server-side defenses: `private.enforce_schoolpro_tenant_relations()` verifies a document's student and template belong to the issue school, while `private.guard_schoolpro_document_issue_lifecycle()` prevents changing a draft issue's school/serial identity and prevents direct mutation of issued/revoked records. This materially reduces the immediate risk for writes that pass through these triggers, but does not make the weaker RLS policy definitions correct: RLS is still a separate authorization boundary, and the student/guardian SELECT policy gaps can affect legacy/inconsistent rows. The staged migration remains a defense-in-depth correction. **Production policies have not been changed.**

### Staged remediation in PR #103

Added migration [`20261014190000_harden_schoolpro_document_issue_update_tenant_scope.sql`](https://github.com/Hassan-625/IHLink-SchoolPro/blob/fix/result-design-section-selection/supabase/migrations/20261014190000_harden_schoolpro_document_issue_update_tenant_scope.sql) to:
- Revalidate school/module/role authorization in the updated draft issue row.
- Require draft issues to have no issuance timestamp or output path.
- Bind non-null student IDs to the same school on issue creation and draft updates.
- Bind student and guardian issued-document reads to the same school as the document issue.

Added static migration assertions to `scripts/school-document-design-test.mjs`, which is already part of the SchoolPro CI job. Latest code commit is [`4968a609`](https://github.com/Hassan-625/IHLink-SchoolPro/commit/4968a60903a5246c381c235c678c8b68987c318f).

**Verification state:** migration and test are staged in the feature branch; CI for the new head had not yet returned a workflow run at the last check, and Vercel status was pending. Do not mark the remediation passed until CI validates the new head and the SQL is reviewed against the live schema. Do not apply the migration to production without the planned review and explicit approval.

**Next action:** recheck CI and review the migration/test results. If green, continue the authenticated role-matrix and two-school acceptance. If CI fails, correct the branch before proceeding. The Result Design Studio save/reload/generate acceptance remains outstanding and PR #103 must remain draft until both workstreams are evidenced.


### Additional finding — document finalization RPC

Read-only inspection of `public.finalize_schoolpro_document_issue(p_issue, p_output_path)` found that the existing SECURITY DEFINER RPC checked the actor's school role and that the path began with the issue's school ID, but did not check the documents-module entitlement and did not confirm that the exact path existed in the intended private output bucket before marking the document issued.

The staged migration now replaces this RPC to require:
- an authenticated actor and draft issue;
- the documents module entitlement for that school;
- the existing authorized school-role check;
- a school-prefixed output path and an existing object with that exact path in `schoolpro-document-outputs`;
- the existing lifecycle trigger bypass flag, update, and audit event behavior.

Static regression assertions were added to `scripts/school-document-design-test.mjs`. Latest code commit: [`4c3764c`](https://github.com/Hassan-625/IHLink-SchoolPro/commit/4c3764cb1200761eaf4558ecfbdc6f7704f00038). **This remains staged only.** CI must pass against this code; the SQL must be reviewed before applying; authenticated acceptance is still required. No production migration or policy has been applied.
