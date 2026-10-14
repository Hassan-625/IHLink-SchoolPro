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


### Additional finding — private output storage read policy

The read-only audit of `storage.objects` found that the guardian branch of the `schoolpro document outputs read` policy checked an active guardian link against the issue's student ID but did not require the joined student record to resolve within the same school as the issue. The student join was already school-scoped, but because it was a LEFT JOIN, the guardian branch could still evaluate independently for a legacy/inconsistent issue row.

The staged migration now recreates that read policy so guardian access requires a resolved student row whose `school_id` matches the document issue. Student access likewise requires that matching row to exist. The static document regression script asserts this condition. This is a defense-in-depth correction for existing or inconsistent rows; no production storage policy has been changed.

Latest code/test commits:
- [`a26e426`](https://github.com/Hassan-625/IHLink-SchoolPro/commit/a26e42622e792cef1af15c04cf072ec5a23a5422) — staged storage read policy correction.
- [`b390649`](https://github.com/Hassan-625/IHLink-SchoolPro/commit/b390649565b236b7cd1ce58d53c0e61fe62b017d) — static regression assertion.

CI must be rerun/confirmed for this latest change. Do not apply the migration until the SQL and role-matrix acceptance are reviewed.


### Continuation update — 14 October 2026, fail-closed module entitlement

The latest complete SchoolPro CI run before the final null-safety adjustment passed on commit [b390649](https://github.com/Hassan-625/IHLink-SchoolPro/commit/b390649565b236b7cd1ce58d53c0e61fe62b017d): [CI run #677](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38612150673). Payment-page validation also passed on that commit. The full CI run had completed its mobile-layout check and production build successfully.

During the SQL review, one additional fail-closed edge case was identified in the staged finalization RPC: in PL/pgSQL, a boolean expression that evaluates to NULL does not enter an `IF NOT (...)` branch. If the module-entitlement helper ever returns NULL for an absent or incomplete entitlement, the old check could fail to reject it. The staged migration now uses `private.schoolpro_module_allowed(i.school_id, 'documents') is not true`, which rejects both FALSE and NULL. A static regression assertion was added to `scripts/school-document-design-test.mjs`.

Commits:
- [94f32c3](https://github.com/Hassan-625/IHLink-SchoolPro/commit/94f32c3c69d7709f5e1fc18f2113918b3c3a5f6e) — fail-closed module-entitlement guard in staged migration.
- [a9b790c](https://github.com/Hassan-625/IHLink-SchoolPro/commit/a9b790cfed608de64e8c96a2246a15b074eb945d) — static regression assertion for FALSE/NULL entitlement behavior.

**Current verification:** the new SchoolPro CI run [38612173100](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38612173100) was still in progress at this update. Payment validation passed for the prior commit but must be confirmed for the new head. The branch remains `fix/result-design-section-selection`; PR #103 remains open/draft and unmerged. No production migration, storage policy, data, or Render deployment has been changed.

**Next action:** verify CI and payment validation for commit `a9b790c`; then finish reviewing the RPC's effective grants and run the authenticated document role-matrix/two-school isolation checks. The Result Design Studio save → reload → generate → inspect-output acceptance for all four sections remains outstanding. Do not merge or deploy before the acceptance evidence and explicit approval.


### Continuation update — RPC permission review and latest checks

The latest payment-page validation run for commit `a9b790c` passed: [run 38612471126](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38612471126). In SchoolPro CI [run 38612470752](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38612470752), type-checking and all test steps through `school-document-design-test.mjs` passed, including the new NULL-entitlement assertion. The mobile-frame/carousel/customer-layout step and final build were still in progress at the time of review; do not mark the run fully green yet.

RPC grant review:
- The staged migration uses `CREATE OR REPLACE FUNCTION public.finalize_schoolpro_document_issue(uuid, text)`, rather than dropping/recreating the function. PostgreSQL's `CREATE OR REPLACE FUNCTION` preserves the existing function's ownership and privileges, so the replacement itself should not erase existing EXECUTE grants.
- The checked-in migration excerpts reviewed so far do not establish the current live ACL for this exact RPC. Effective grants still require a read-only catalog query against the intended Supabase project (e.g. `pg_proc`/ `aclexplode(proacl)`) or confirmation from the migration that originally created the function. Do not infer live grants solely from the replacement migration.
- No authenticated database session was available for the cross-school/role-matrix test in this step. These tests remain outstanding.

No production migration, RLS/storage policy, production data, or Render deployment has been changed. PR #103 remains open and unmerged. Next: wait for the latest CI to finish, establish the RPC's effective grants from authoritative catalog/source evidence, then proceed with authenticated role-matrix and two-school isolation acceptance before any merge/deploy.


### Continuation update — 14 October 2026, CI and live RPC ACL verified

**Latest branch-check evidence:** the SchoolPro CI workflow [run 38612535468](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38612535468) completed successfully for commit `501e006a3e646f07fcef1327a4a0654ae7ced8eb`. The `validate` job passed typecheck, the school-context/access/role tests, result section/workflow/export tests, operational-role and native-entry security checks, document-design regression tests, mobile-frame/carousel/customer-layout checks, artifact upload and production build. Payment validation [run 38612535370](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38612535370) also completed successfully for that commit. The commit's combined status additionally reports Vercel success, which is not Render deployment evidence.

**Authoritative read-only Supabase ACL query:** against project `lnqsroyiybutkfngbyge`, `public.finalize_schoolpro_document_issue(p_issue uuid, p_output_path text)` exists as a SECURITY DEFINER function owned by `postgres`. Its effective ACL entries are EXECUTE for `authenticated` and `service_role`, plus owner `postgres`; there is no EXECUTE entry for `PUBLIC` or `anon`. Raw ACL returned: `{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}`. This closes the previously open question about the live function's grants. It does **not** certify the function's full behavior or the staged replacement migration; authorization logic and authenticated tests remain necessary.

The live migration ledger confirms the proposed migration `20261014190000_harden_schoolpro_document_issue_update_tenant_scope` has not been applied to production. No production RLS/storage policy, data, or Render deployment was changed during this check.

**Next action:** proceed to the next acceptance item in the original sequence: authenticated Result Design Studio save → reload → generate → inspect-output for Nursery, Primary, Junior Secondary and Senior Secondary. The available tools still do not provide a signed-in browser session for this end-to-end journey, so it cannot honestly be marked passed yet. Continue with the document-security role matrix and two-school isolation checks when authenticated test access is available. PR #103 remains unmerged; do not deploy to Render or apply the staged migration without explicit approval and complete acceptance evidence.


### Continuation update — live production policy re-check (14 October 2026)

A second read-only query of `pg_policies` against production project `lnqsroyiybutkfngbyge` confirms the staged document-security migration is **not live** and the following original policy definitions remain present:

- `authorized staff update draft document issues`: `WITH CHECK` currently only requires draft status and `issued_at IS NULL`; it does not revalidate same-school student binding, null output path, module entitlement, or the authorized staff role after row changes.
- `students read own issued documents`: the live predicate still contains tautological `st.school_id = st.school_id`.
- `guardians read ward issued documents`: the live policy checks the active guardian link but does not explicitly bind the student's school to the issue's school.
- `schoolpro document outputs read` storage policy: the guardian branch checks a link to `d.student_id` without requiring a successfully joined student row in the issue's school.
- `authorized staff create draft document issues`: the live insert policy does not bind a non-null student to the same school as the issue.

These are verified live policy-definition defects, not evidence that an unauthorized read or write was successfully exploited. Do not attempt exploitation against production. The staged migration addresses these definitions and adds module and private-bucket object-existence checks to the finalization RPC. Keep the remediation **IMPLEMENTED IN BRANCH — NOT APPLIED TO PRODUCTION** until review, acceptance and explicit approval.

**Latest CI watch:** SchoolPro CI run [38613132633](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613132633) is still in progress; typecheck and all scripted tests, including document-design regression, have passed so far, with mobile-layout checks and build still pending at last inspection. Payment validation run [38613132379](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613132379) passed. The documentation update commit is [2b217335870959fe00c7b893029681da7cadab39](https://github.com/Hassan-625/IHLink-SchoolPro/commit/2b217335870959fe00c7b893029681da7cadab39).

**Next:** inspect completion of CI run 38613132633, then continue source-level acceptance review for Result Design Studio persistence/mapping/output. Authenticated save → reload → generated-output inspection and two-school/role-matrix runtime tests remain blocked until a safe authenticated test session is available. No production changes, PR merge, or Render deployment were made.

### Continuation update — 14 October 2026, CI completion and Result Design Studio source review

**CI result:** SchoolPro CI run [38613132633](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613132633) has now completed successfully. The run passed type-checking, all scripted checks (including result-section data, class-result export, document-design security assertions and template preview), mobile-frame/carousel/customer-layout checks, artifact upload and the production build. Payment validation [38613132379](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613132379) also passed. These checks apply to the workflow's tested commit; the documentation-only handover commit does not itself have an associated PR-triggered run. CI is not evidence of authenticated production save/reload behavior.

**Source-level review completed:**
- `src/lib/resultSectionTemplates.ts` normalizes Nursery/KG, Primary/Basic, JSS/Junior Secondary and SSS/Senior Secondary labels, stores section-specific design snapshots under the same school-owned template row, preserves the parent row's identity, and uses the school default for unknown/unconfigured sections.
- `src/pages/schoolpro/SchoolProResultTemplates.tsx` exposes the section selector, workbook upload, field/assessment mappings, mapping validation and save/replace flow. The generation path resolves the design using the selected student's normalized class level and then writes configured fields, result rows, custom fields, images and domain/rating sections to the workbook.
- `scripts/test-result-section-data.mjs` covers distinct fixture workbook/mappings for all four sections, unknown-section fallback, independent section updates, preservation of school identity, and roster paging. `scripts/test-class-results-export.mjs` round-trips a generated synthetic XLSX and checks totals, averages, comments, selected-student output and page setup.

**Remaining gap:** all of the above are source/static or synthetic-fixture evidence. No authenticated browser/database round trip has been observed here: upload/save → navigate away/reload → verify each section's persisted workbook/mappings → generate an actual test student's workbook → inspect the resulting file and term-history columns. The section-specific workstream therefore remains **IMPLEMENTED — end-to-end verification pending**, not complete. First/Second/Third Term history behavior and the cross-school role matrix still need dedicated evidence.

**Production state:** no merge, migration, production policy/data change, or Render deployment was performed. PR #103 remains the review vehicle; keep it unmerged until the outstanding acceptance and security gates are evidenced and the user approves release.

**Next action:** continue with the authenticated Result Design Studio save/reload/generate/output acceptance when a suitable authorized test session is available. In parallel, review the exact save/load and term-history branches for any source-level gaps; do not represent synthetic CI as a live pass.

### Continuation update — 14 October 2026, section-switch upload safety

During the source review, I traced the selected-student → section auto-selection behavior. Selecting a pupil in another section changes the editor section and reloads the saved design, but the prior implementation did not clear a pending, unsaved workbook or logo. That could leave an uploaded-but-unsaved file in the editor while the section selector has changed, allowing the user to accidentally save the pending file against the wrong section. This was a source-level UX/data-association risk; no production incident was inferred.

**Branch correction:** updated `src/pages/schoolpro/SchoolProResultTemplates.tsx` so an automatic section switch clears the pending workbook, pending logo, and stale feedback before changing the section. Added a regression assertion in `scripts/test-result-section-data.mjs` to guard that behavior.

- Source commit: [7f24b4c](https://github.com/Hassan-625/IHLink-SchoolPro/commit/7f24b4cc400c994402e38ae7bee53994e8d6b4e0)
- Test commit / current tested branch tip at this update: [b2b6b9b](https://github.com/Hassan-625/IHLink-SchoolPro/commit/b2b6b9bf2700cfb0480808c1a082fc0894359037)
- The earlier CI run [38613132633](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613132633) passed before this new change. No PR-triggered run for the new test commit was returned by the available workflow-run lookup; **the new change is not yet CI-verified**.

No database or production data changes, merge, or Render deployment were made. The authenticated save/reload/generate/output test and cross-school role matrix remain outstanding.

**Next action:** obtain CI evidence for commit `b2b6b9b` (type-check, result-section regression tests and full build), then continue the source review and pursue authenticated end-to-end acceptance. Do not call this fix verified until the new commit's CI is green.

### Continuation update — 14 October 2026, section-switch safety CI verified

The new source/test commit `b2b6b9bf2700cfb0480808c1a082fc0894359037` has now passed its associated GitHub Actions checks:
- SchoolPro CI [run 38613798557](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613798557) — passed type-check, startup/context/role checks, `scripts/test-result-section-data.mjs`, result workflow, class-results export, document-design assertions, template preview, mobile-layout checks, artifact upload and production build.
- Payment validation [run 38613799095](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613799095) — passed TypeScript check and build.

The section-switch pending-upload safety fix is therefore **CI verified**. This does not certify authenticated production behavior or the whole Result Design Studio. The next acceptance gate remains upload/save → navigate away/reload → verify section-specific mappings/workbook persisted → generate and inspect output for Nursery, Primary, Junior Secondary and Senior Secondary, including term-history columns and two-school role isolation. Those live checks remain unverified without an authorized test session.

No production migration/data changes, PR merge, or Render deployment were made. PR #103 remains unmerged pending acceptance evidence and user approval.

### Continuation update — 14 October 2026, stale section-mapping race found and guarded

After the section-switch safety fix passed CI, further source tracing found a related race: the selected student's section could change while the async section config reload was still pending. During that brief interval, the visible editor config could still represent the previous section, and a fast save could persist those old mappings against the target section's workbook path.

**Branch correction added (CI pending):**
- Introduced a section-config readiness guard.
- Section auto-switch now locks saving and clears pending workbook/logo/feedback while target mappings reload.
- The save handler refuses to persist while the target section is not ready.
- The load path unlocks saving only after it has applied the target section config.
- Added static regression assertions for the lock, save guard and unlock behavior.

Commits: source [30287ff](https://github.com/Hassan-625/IHLink-SchoolPro/commit/30287ff9fbaed86a214b4bb79abfe77b8c8be482); test [08b24ff](https://github.com/Hassan-625/IHLink-SchoolPro/commit/08b24ff83f6428125aeae3b447726163e84d51cf). The earlier pending-upload fix on parent commit `b2b6b9b` passed SchoolPro CI [38613798557](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613798557) and payment validation [38613799095](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38613799095). No workflow run/status has yet been returned for the new stale-config-race fix, so **this latest correction remains unverified until CI passes**.

This was a source-level race finding, not evidence of a production data loss incident. No production data/policy changes, PR merge or Render deployment occurred.

**Next action:** verify CI for `08b24ff`, then continue acceptance of section-specific save/load and workbook generation. Authenticated round-trip and two-school role-matrix tests remain open.

### Continuation update — 14 October 2026: stale-load race and CI correction

The first CI attempt for the section-readiness guard failed in scripts/test-result-section-data.mjs because one static assertion still expected the old section-switch code. Type-check and earlier checks passed before this assertion failed. Payment validation run 38614446463 passed.

A deeper review found that overlapping async load requests could finish out of order and allow an older section response to overwrite newer mappings or mark the editor ready. Added a monotonically increasing loadSequence request identity; stale requests return before applying roster/config state, and only the latest request may unlock saving. Updated the test assertion to match the readiness lock and added checks for stale-load protection.

Commits: source guard c808fd6850614ebb57bd2928368b0284e425a2d1; stale-load test cf82b43c66562a1ab31acb52d18c2732235b861e; assertion correction 662cfa14cab8719012494ddcf747fe477e042bce. No CI run/status was returned for the latest test commit at this check. The current source/test changes remain unverified until a fresh CI run passes.

No production data/policy changes, PR merge, or Render deployment occurred. Next: confirm CI on the latest commit, resolve any remaining failures, then continue authenticated section-specific save/reload/generate acceptance and cross-school role-matrix verification.

### Continuation update — 14 October 2026: CI green and school-context invalidation

The corrected section-readiness and stale-load regression suite passed in SchoolPro CI run [38614735834](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38614735834); payment validation also passed in [38614735846](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38614735846). These checks cover source-level tests/build, not authenticated production save/reload behavior.

A further source audit identified a tenant-context edge case: if the active school context cleared while a previous school's asynchronous result-template load was still in flight, the early return could leave the previous request valid. The loader now increments its request identity before checking school context and clears school-scoped students, schemes, and saved template when no school is active. A regression assertion was added. Commits: source [e2a8a3b](https://github.com/Hassan-625/IHLink-SchoolPro/commit/e2a8a3b9d4b1fd5b1fce5a654d26fdcb339b459e); test [460cb5c](https://github.com/Hassan-625/IHLink-SchoolPro/commit/460cb5cff62e7f12da5d8869e733387853eef3e9). CI for this newest change is pending confirmation.

No production data/policy changes, PR merge, or Render deployment occurred. Next: verify CI for this context-clear guard, then continue section-specific save/reload/workbook checks and authenticated cross-school isolation tests.

### Follow-up guard — pending CI

The context-clear guard exposed one related state issue worth preventing: pending workbook/logo uploads from school A could remain in editor state during a direct school A → school B reload. The loader now locks saving and clears pending workbook/logo selections at the start of every reload, not only when the school context is empty. This prevents an unsaved school-specific workbook/logo from accidentally being uploaded into another school's configuration after switching contexts. Regression assertion updated.

Commits: source [46d993d](https://github.com/Hassan-625/IHLink-SchoolPro/commit/46d993dc73198a0223b9af3b8a602ea840222a19); test [1b10797](https://github.com/Hassan-625/IHLink-SchoolPro/commit/1b1079755d129fd2759a115d0b97d61fa8d76c9e). CI has not yet been confirmed for these newest changes. The earlier CI green runs remain valid for the earlier section-race correction only, not these follow-up changes.
