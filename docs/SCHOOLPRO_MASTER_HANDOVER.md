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


### Continuation update — 14 October 2026, generation blocked during school-context reload

The latest source-level review found that the save action was blocked while the Result Design Studio reloaded a school/section, but the Generate workbook action did not have the equivalent readiness guard. During a rapid school-context change, a user could attempt generation while the saved template and roster were still being refreshed. Generation now stops with a clear message until the active section configuration is ready, and it also requires the selected student to exist in the currently loaded roster before resolving or downloading a template.

- Source commit: [4e2b0ff](https://github.com/Hassan-625/IHLink-SchoolPro/commit/4e2b0fffac90e2d89ff9bc9b3698b0513d58ec8a)
- Regression-test commit: [ea3c396](https://github.com/Hassan-625/IHLink-SchoolPro/commit/ea3c3969b9d086cc4a9ed1b6b3704c2dd2d197e0)
- Prior latest CI: SchoolPro CI [run 38615917765](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38615917765) passed typecheck, the result-section test, other scripted checks and production build; payment validation [run 38615917733](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38615917733) passed. Those runs predate the generation-guard commits, so the new correction is pending CI.
- Vercel reported a failure for the prior test commit, while a separate Vercel status on the source commit reported success. These are Vercel checks, not Render deployment status; no conclusion about Render production health is drawn from them.

The fix is source/test only. No production database, policy, data, merge or Render deployment was changed. PR #103 remains unmerged. Next: verify CI for ea3c396, correct any failures, then continue reviewing result-field calculations and section-specific persistence. Authenticated save → reload → generate → inspect-output acceptance for all four sections remains outstanding.


### CI follow-up — generation-guard assertion correction

SchoolPro CI run [38637970880](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38637970880) reached the result-section test and failed because that test still expected the prior optional-chaining expression (`selected?.class_level`) after the source now validates the selected student before reading `selected.class_level`. This was a stale static assertion, not a TypeScript failure or a demonstrated runtime defect. Updated the assertion to match the validated-student path in commit [bf790b9](https://github.com/Hassan-625/IHLink-SchoolPro/commit/bf790b99497dc53a4dc4086441273c10544f439a). Payment validation run [38637970110](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38637970110) was in progress at the time of this update. The corrected test commit must pass a fresh CI run before this source fix is considered CI-verified.

No production change, merge, or Render deployment was made. Next: verify the new CI run and repair any further assertion issues before returning to section-specific persistence/output review.


### CI checkpoint — 14 October 2026, result-section assertion now passes

Fresh SchoolPro CI run [38638126735 (run 700)](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638126735) has passed the result-section data test, including the new generation readiness/roster assertion. Typecheck and earlier scripted checks have not reported failures in this run. At the latest check, the workflow was still running its mobile-frame/carousel/customer-layout check; the production build step had not started, so this is not yet a full green CI result. Payment-page validation [38638126746 (run 460)](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638126746) completed successfully. Vercel's status check was successful, but it is not Render deployment evidence. No merge, production policy/data change, or Render deployment occurred.

Next: wait for the remaining CI/build steps to finish; once green, continue the section save/reload and generated-workbook audit. Authenticated live acceptance remains outstanding.


### Continuation update — section persistence assertions strengthened

SchoolPro CI [run 38638126735 (run 700)](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638126735) and payment-page validation [run 38638126746 (run 460)](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638126746) completed successfully for the prior generation-guard revision. The result-section regression suite now additionally asserts that named-section saves use their section snapshot, updates are scoped by both template ID and `school_id`, the default upsert uses the school conflict key, uploaded workbook paths are namespaced by school, and generation downloads the resolved section workbook path. Test commit: [917d0bb](https://github.com/Hassan-625/IHLink-SchoolPro/commit/917d0bbca538edc0fc5b69c287feb42ceb72c861).

These are source-level regression assertions, not a substitute for authenticated database/storage acceptance. CI for the strengthened assertions is pending. No production changes, merge, or Render deployment were made. Next: validate this test revision in CI, then continue with result-field calculation and live section save/reload/output acceptance.


### Continuation update — 14 October 2026, section persistence CI and term-history source review

The strengthened persistence regression test in commit [917d0bb](https://github.com/Hassan-625/IHLink-SchoolPro/commit/917d0bbca538edc0fc5b69c287feb42ceb72c861) has passed in SchoolPro CI run [38638506703](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638506703) through the result-section data test and all preceding scripted checks, including type-checking. At the latest inspection, the mobile-layout check was still running and artifact upload/build had not started; therefore this CI run is **not yet a confirmed full pass**. Payment validation [38638506693](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638506693) completed successfully.

Further source review confirmed that workbook generation fetches previous-term results only for terms preceding the selected term; First Term therefore has no previous-term fetch, Second Term loads First Term, and Third Term loads First and Second Term. The generated rows write prior-term scores to configured columns and calculate each subject's cumulative average only when all required term scores are present. This is source-level evidence; it does not prove the actual generated workbook or authenticated round-trip works.

**Next:** recheck CI run 38638506703 until the mobile check and production build complete. If green, record full CI success and continue the four-section authenticated save/reload/generate/output acceptance. The live authenticated journey and two-school role/storage isolation remain outstanding. No production policy/data changes, PR merge, or Render deployment occurred.


### Continuation update — 14 October 2026, CI complete and live document-policy audit

**Result Design Studio CI:** workflow run [38638506703](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638506703) completed with conclusion **success**, including type-checking, section-data and result-workflow tests, mobile-layout checks, and the production build. Payment-validation run [38638506693](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38638506693) also passed. This is repository CI evidence only; authenticated browser save/reload/generate acceptance remains outstanding.

**Read-only production policy check** against Supabase project `lnqsroyiybutkfngbyge` found that migration `20261014190000_harden_schoolpro_document_issue_update_tenant_scope.sql` is not present in the live `supabase_migrations.schema_migrations` ledger (the query for versions on/after 20261014 returned no rows). The existing live policies still show these gaps:
- Draft issue UPDATE `WITH CHECK` confirms draft status and `issued_at IS NULL`, but does not reassert the module entitlement, same-school student binding, `output_storage_path IS NULL`, and the same authorized role/school predicate.
- Draft issue INSERT does not require a linked student to belong to the issue's `school_id`.
- Student SELECT contains tautology `st.school_id = st.school_id`, rather than binding the student's school to the issue's school.
- Guardian SELECT checks an active guardian link to the issue's student but does not bind that student's school to the issue's school.
- The live private-bucket storage SELECT policy joins a student only when the student matches the issue's school, but its guardian branch can still pass on a guardian link to `d.student_id` without requiring the joined same-school student row to exist.

These are policy-definition defects and an authorization-risk finding; this read-only check does **not** prove that an unauthorized user accessed any record. The branch contains the staged migration that corrects these correlations, hardens draft INSERT/UPDATE checks, requires an actual output object, and aligns the finalization RPC and storage-read authorization.

**Safety decision:** migration remains staged. Do not apply it to production until its SQL is reviewed against the live schema, regression tests pass, and the user explicitly approves the production policy change. No production data or policy was changed, no PR was merged, and no Render deployment occurred.

**Next action:** review/test the staged migration against the exact live schema and role matrix; then, separately, continue authenticated four-section Result Design Studio acceptance. Keep both workstreams open until independently evidenced.


### Continuation update — 14 October 2026, staged migration schema review and regression hardening

Read-only live schema inspection confirmed the staged migration's referenced core objects exist: `public.schoolpro_document_issues`, `public.schoolpro_students`, `public.schoolpro_members`, `public.schoolpro_guardian_links`, and `public.schoolpro_document_issue_events`. The live role enum contains `super_admin`; the existing entitlement, membership-management and finalization functions have the expected names/signatures, and the finalization function is security-definer with an empty search path. No production DDL or policy was executed.

The schema review identified two extra edge cases to cover before considering the migration review-ready: the security-definer finalization RPC must independently reject a draft whose linked student belongs to another school (because RLS is not the only enforcement boundary), and guardian authorization should require the guardian-link row's `school_id` to match the document issue's school in both issue-row and storage-output policies. These checks have now been added to the staged migration and its document-design regression test on `fix/result-design-section-selection`. Commits: migration [5b6b4623266faaf482bc457cd42701254602311e](https://github.com/Hassan-625/IHLink-SchoolPro/commit/5b6b4623266faaf482bc457cd42701254602311e); regression test [99af1c97fbcf5ff04d5c018c42af002bba7c8fda](https://github.com/Hassan-625/IHLink-SchoolPro/commit/99af1c97fbcf5ff04d5c018c42af002bba7c8fda).

**Status:** IMPLEMENTED — CI verification pending. The live schema inspection is read-only and confirms object/signature compatibility, but it does not execute the migration or prove the policy behavior. The migration remains unapplied in production; no data/policy changed, no PR merged, and no Render deployment occurred. Next: confirm CI runs the updated regression assertions, inspect any failure, then continue the authenticated four-section Result Design Studio and cross-school role-matrix acceptance. Production application still requires explicit approval.


### Continuation update — CI checkpoint after document-security regression changes

GitHub Actions now confirms the updated `scripts/school-document-design-test.mjs` passed in SchoolPro CI run 708 (run ID `38640524581`), including the new static regression assertions for the security-definer finalization school-boundary guard and guardian-link school matching. Typecheck and the preceding result-section, result-workflow, class-results-export, operational-role, account-access and document-design checks also completed successfully. The mobile-layout/operational-document test step was still running at the last poll, and the production build had not started; therefore this run is not yet a complete green CI result. [View CI run](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640524581).

Payment validation run 468 (ID `38640524283`) completed successfully, including TypeScript validation and production build. [View payment validation](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640524283).

The next Result Design Studio work remains source/test acceptance for section-specific generation and assessment totals, followed by authenticated save/reload/generate tests. Source inspection still shows `total_marks_obtainable` calculated as `scores.length * 100`; do not silently change this until the assessment-scheme scoring contract and section-specific maxima are verified. The section data tests pass, but they do not prove a live generated workbook or authenticate role-based access. No production changes, PR merge or Render deployment occurred.


### Continuation update — four-section result mapping presets

A source audit found a gap in the Result Design Studio: the section selector and stored template snapshots supported Nursery, Primary, Junior Secondary and Senior Secondary, but the built-in mapping preset UI exposed only Nursery and Primary. Added Junior Secondary and Senior Secondary starter mapping presets, extended the profile type to all four sections, and added regression checks for each profile's identity, mapped subject/total fields, and presence in the UI. Commits: profile helper [3eab3e6204719c0c587d8aa6d4b92e78f39f9a05](https://github.com/Hassan-625/IHLink-SchoolPro/commit/3eab3e6204719c0c587d8aa6d4b92e78f39f9a05), Result Design Studio UI [e7b011d0a661bda0fe823681db1fd7b370acdd0f](https://github.com/Hassan-625/IHLink-SchoolPro/commit/e7b011d0a661bda0fe823681db1fd7b370acdd0f), regression tests [6b026655e37ef6e8d4041f67274e0ed9b303258e](https://github.com/Hassan-625/IHLink-SchoolPro/commit/6b026655e37ef6e8d4041f67274e0ed9b303258e).

These are starter *mapping layouts*, not claims that all four sections must use identical assessment weighting or grading standards. They provide each section its own named mapping preset and editable starting layout. School-specific assessment schemes, uploaded workbook templates, mapped columns and grading rules remain authoritative and must be validated with representative examples for each section. The earlier source finding that `total_marks_obtainable` is calculated as `scores.length * 100` remains open for scoring-contract review; no grading or marks logic was changed in this step.

CI run 708 (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640524581) completed successfully before these latest commits, including the document-security regression checks, mobile checks and production build. The new commits have triggered fresh CI and must be re-verified. Payment validation run 468 passed (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640524283). No production changes, merge or Render deployment occurred.


CI follow-up for four-section mapping presets: SchoolPro CI run 711 (ID `38640953144`) has passed TypeScript typecheck and `scripts/test-result-section-data.mjs`, including the newly added tests for Nursery, Primary, Junior Secondary and Senior Secondary profile identity and UI exposure. The full workflow was still in progress at the last check, so production build and remaining checks are not yet marked passed. [Track run 711](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640953144). A second run 712 was also triggered by the regression-test commit and remains in progress: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640962054.

### Continuation update — CI green and assessment maximum correction

CI verification is complete for the four-section Result Design Studio mapping work. SchoolPro CI runs [711](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640953144) and [712](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640962054) both passed all listed checks, including typecheck, section/result regressions, document-design checks, mobile checks and production build. Payment-validation runs [471](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640953011) and [472](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38640962077) also passed typecheck and production build.

Source review confirmed a real reporting defect in src/pages/schoolpro/SchoolProResultTemplates.tsx: total_marks_obtainable was calculated as scores.length * 100, which assumes every subject is assessed out of 100 regardless of the linked scheme. The correction now sums the component maxScore values from the assessment scheme referenced by each result row. If a result has no matching scheme, an empty scheme, or invalid component maxima, the report leaves the obtainable maximum blank rather than inventing a number. Regression cases cover mixed schemes, one subject, unknown/empty schemes and no results.

**Scoring boundary:** this corrects the obtainable-marks summary field only. It does not alter stored marks, assessment scoring, grade bands, subject averages, ranking, published results or historical records. The existing overall-average/grade semantics still need a separate contract review to confirm whether the school's grade scale expects raw subject marks or normalized percentages when schemes differ from 100. Do not silently change those semantics without confirming the scoring contract. CI must be re-run for this latest change before marking it verified.

No production migration/policy/data changes, PR merge or Render deployment occurred. The document-security migration remains staged and requires explicit approval before production application. Authenticated save/reload/generate acceptance for all four sections remains outstanding.

### Continuation update — assessment-summary follow-up and CI checkpoint

A further source review of the result-generation path found the current overall average is computed as the arithmetic mean of each subject's total_score, and the resulting value is compared directly with the configured grade-band min_score/max_score. Per-subject grade output likewise compares the cumulative raw score (or current raw score) directly to grade bands unless the section profile's fixed threshold list overrides it. The report now derives total_marks_obtainable from the linked assessment schemes, but the source does not yet establish whether total_score is normalized to a common scale before being stored. Therefore **do not change overall average, grade band, or ranking formulas yet**: first trace where total_score is produced and verify whether grade bands are defined as raw marks or percentages. If subjects can have different maxima and scores are raw, direct arithmetic averaging can be misleading; if scores are normalized upstream, changing it here would be wrong.

Latest CI checkpoint for the assessment-maximum correction:
- Payment validation run [38641562351](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38641562351) completed successfully (type-check and build).
- SchoolPro CI run [38641562310](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38641562310) passed type-check and all scripted regression tests plus mobile/layout checks; production build was still running at the last poll. Do not record full CI success until that run concludes successfully.

Next actions: (1) verify run 38641562310 reaches a successful conclusion; (2) trace total_score generation and grade-band contract, then add regression tests for mixed-max schemes without changing stored/published marks; (3) continue authenticated section-specific upload → mapping → save → reload → workbook generation checks. These source tests do not replace live authenticated acceptance.

No production data/policies changed, no PR merge, and no Render deployment occurred. Document-security migration remains staged and unapplied.


## Continuation update — 14 October 2026: scoring contract and term-total row

- **Read-only scoring contract trace:** the live `schoolpro_results` table has a BEFORE INSERT / BEFORE UPDATE OF `assessment_scheme_id, assessment_scores` trigger `calculate_schoolpro_result_total`, calling `private.calculate_result_total()`. The function verifies the assessment scheme belongs to the same school, validates each entered component score against that component's configured `maxScore`, and writes `total_score` as the sum of entered component marks. The client submits component marks and does not authoritatively calculate the stored total. No production data or schema was changed by this inspection.
- **Result Design Studio change implemented on the working branch:** generated workbook now adds a `TOTAL MARKS` summary row beneath the last reserved subject row and sums the current-term totals, First Term totals and Second Term totals into their respective mapped columns. Historical totals are matched to the current subject by `subject_id`. The summary row's cumulative-average cell is filled only when all terms required for the selected term are available; it averages the term-level grand totals. Per-subject cumulative average behavior remains: First Term uses current term; Second Term uses First + Second; Third Term uses First + Second + Third only when all expected subject results exist.
- **Regression coverage added:** helper tests cover current and historical total summation, invalid and missing totals, and source assertions for the three mapped summary columns. These tests still require CI execution before the change is called CI-verified.
- **Ranking caution:** the existing class-position value comes from the current-term `schoolpro_result_class_rank` RPC. It has not yet been changed to cumulative cross-term ranking. Before changing rank/grade semantics, trace that RPC and the class/broadsheet calculation contract and add a regression fixture with unequal term totals. Do not overwrite published marks to test.
- **Next workstream:** continue transaction operation → ledger → reconciliation validation using read-only inspection and documented evidence; keep any live payment or ledger writes out of production unless explicitly approved.
- No PR merge, Render deployment, production data write or production policy/migration application performed as part of this update.


## Continuation update — 14 October 2026: transaction and ledger read-only audit

- **Result workbook regression:** the new term-total summary helper and its regression assertions passed in SchoolPro CI run [#720](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38643177858) through the result-section regression step; the run was still completing its mobile/layout and production-build steps at the time of this note. Payment-page validation run [#480](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38643177689) completed successfully. Do not call the full SchoolPro CI run green until its final conclusion is successful.
- **Scoring/ranking contract:** read-only inspection of `schoolpro_result_class_rank` shows it ranks the student's published results for the requested single term/session by sum of subject `total_score`, then returns class population, position, total and average. It does not calculate cross-term cumulative position. Cumulative cross-term ranking remains a separate, not-yet-implemented decision; do not silently change the published-result ranking contract.
- **Payment/ledger snapshot (read-only):** current `payment_transactions` has 1 row (`datasub`, credited, settled, ₦200); `wallet_ledger` has 14 DataSub entries (2 credits totalling ₦400, 1 debit ₦200, 5 refund entries totalling ₦442, 6 reserve entries totalling ₦520). There are no duplicate wallet-ledger `reference` values in the current snapshot, and the linked payment has matching internal/external references in ledger rows. These aggregates alone do not prove every refund/reserve lifecycle is correct; reconcile each lifecycle and balance movement against source transactions before certifying.
- **Reconciliation warning:** aggregate current DataSub wallet balance is ₦122 while the simple credit-minus-debit ledger total is ₦200. This may reflect refund/reserve semantics or an incomplete accounting path, so it is an **OUTSTANDING reconciliation discrepancy**, not yet evidence of a lost or duplicated customer payment. Next step is trace wallet balance updates, refund/reserve lifecycle semantics, and per-entry before/after balances without displaying customer identifiers or mutating records.
- **Finance ledger:** `finance_ledger_entries` currently contains 0 rows and has no write trigger among the inspected payment/transaction tables. Several service-specific payment-intent/payment tables are also empty in this snapshot. The general finance ledger is therefore not yet demonstrated as the cross-service transaction ledger.
- **Critical database security finding:** `public.customer_payment_transactions` has RLS disabled and `anon` currently has SELECT, INSERT, UPDATE and DELETE table privileges. This is a policy/grant-definition risk. No unauthorized access was demonstrated, and no policy/data was changed. Stage a least-privilege migration after confirming the legitimate webhook/RPC write paths; revoke anonymous direct access and enforce authenticated owner/finance scope. Production policy changes require explicit approval.
- **No production data, payment, wallet, ledger, policy or migration was changed.** No merge or Render deployment occurred. Keep transaction reconciliation and the customer-payment RLS fix as high-priority follow-ups in the original handover sequence.


### Continuation update — 14 October 2026: DataSub wallet lifecycle reconciliation follow-up

- **Read-only transaction-to-ledger matching:** the current `datasub_transactions` snapshot has 6 transactions totalling ₦520 (5 failed, 1 successful); their selling prices total ₦520 and provider costs total ₦393. All 6 reserve entries (₦520) match a DataSub transaction reference, and all 5 refund entries (₦442) match a DataSub transaction reference. The 5 failed transactions' refund total is consistent with the successful transaction being the one unrefunded reserve, but transaction-level matching should be retained as the evidence rather than treating aggregate totals alone as proof.
- **Balance movement explanation narrowed:** wallet history shows an initial ₦200 credit, a ₦200 settlement hold/reversal of the premature credit, then a second ₦200 credit. One successful ₦78 DataSub transaction and the current wallet balance of ₦122 are arithmetically consistent (₦200 − ₦78 = ₦122). Thus the earlier ₦122-versus-₦200 aggregate discrepancy is likely explained by the successful ₦78 purchase rather than by a missing customer funding credit.
- **Remaining ledger-integrity defect/risk:** the successful ₦78 purchase is represented by a reserve entry, but reserve/refund entries have no `balance_before`, `balance_after`, `direction`, or `transaction_type`. The wallet ledger therefore does not independently provide a complete auditable available-balance movement for service purchases; the arithmetic balance explanation is not equivalent to a fully reconciled double-entry ledger. The five failed purchases have matching refund rows. Do not backfill or alter live rows as part of this audit.
- **Security review continued read-only:** `public.customer_payment_transactions` has no row in `pg_policies` and grants broad direct table privileges to both `anon` and `authenticated` roles (including SELECT/INSERT/UPDATE/DELETE, plus other table privileges); RLS remains disabled. This is more extensive than an anonymous-only exposure. No legitimate service write path has yet been conclusively mapped to this table. Next security step is to inspect application/webhook usage and grants on narrowly scoped RPCs, then prepare a staged least-privilege migration that preserves verified server-side payment processing and authenticated owner/finance reads. Do not apply it to production without explicit approval.
- **Scope unchanged:** all checks were read-only. No wallet/payment rows, policies, grants, schema, production deployment, or PR merge were changed.


### CI verification correction — 14 October 2026

- Re-checked the final job records after the preceding update: SchoolPro CI run [#720](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38643177858) is now **completed successfully**, including typecheck, all scripted regression checks, mobile/layout checks, and production build. Payment-page validation run [#480](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38643177689) is also **completed successfully**, including typecheck and production build.
- This validates branch CI only. It does not constitute authenticated live acceptance, production deployment, PR merge, or proof that the staged security migration has been applied.


### Continuation update — 14 October 2026: payment write-path trace checkpoint

- **Database RPC/grant inspection (read-only):** reviewed public/private function names, security-definer status, and EXECUTE grants for payment-related RPCs. Relevant settlement/finalization routines generally deny `anon` EXECUTE and require server-side or authenticated access; the `credit_verified_payment` routine denies both `anon` and `authenticated` EXECUTE, consistent with a trusted server-side path. `my_payment_outcomes(p_platform)` is a security-definer read RPC granted to authenticated callers, likely intended for scoped customer-facing outcomes. However, no database function definition was found that references `customer_payment_transactions`, so the direct table write path has not yet been established from SQL functions.
- **Table shape:** the payment table includes `user_id`, provider/platform references, transaction status and amount, settlement timestamps, and virtual-account metadata including NUBAN/account name. Because it contains financial and account data, a broad authenticated read policy should not be assumed safe without confirming the UI's exact needs. Preferred target is to revoke direct `anon` access, deny direct authenticated writes, and expose only owner-scoped fields via a vetted view/RPC if direct table reads are unnecessary. Keep trusted service-role processing intact; service-role access bypasses RLS.
- **Migration decision:** do not write/apply a final policy migration until the client/edge-function paths are mapped and existing RPC/view dependencies are confirmed. A blanket `REVOKE` or owner-read policy could break payment status pages or virtual-account flows. No production policy, grant, data, merge, or deployment changed during this step.


### Continuation update — 14 October 2026: application-path and database-dependency trace

- **Repository trace (branch `fix/result-design-section-selection`):** inspected the payment-related source files present in this branch, including `src/components/BankTransferPayments.tsx`, `src/pages/schoolpro/SchoolProPayments.tsx`, and `supabase/functions/schoolpro-payment/index.ts`. The generic service bank-transfer component reads `ihlink_bank_accounts` and the signed-in user's `direct_transfer_submissions`, then submits through `submit_service_bank_transfer`. SchoolPro guardian fee payments use `schoolpro_guardian_links`, `schoolpro_students`, `schoolpro_invoices`, `schoolpro_bank_accounts`, and the `submit_schoolpro_payment` RPC. The inspected `schoolpro-payment` Edge Function uses service-role queries scoped to a verified guardian link and school invoice, and returns school-specific receiving accounts. None of these inspected paths directly accesses `customer_payment_transactions`.
- **Database dependency trace (read-only):** searched PostgreSQL view and materialized-view definitions, ordinary function definitions, and triggers for references to `customer_payment_transactions`; the query returned no matches. This narrows the known dependency surface but does not prove that no other uninspected client module, Edge Function, webhook, or external provider integration accesses the table.
- **Security decision:** still do not apply a production revoke/policy change yet. Next, enumerate all repository and deployed Edge Function sources that create/read virtual-account payment records, and inspect the relevant table's grants plus the scoped `my_payment_outcomes` contract to confirm what the user-facing UI actually needs. Then prepare a migration and regression checks that preserve server-side settlement, owner-scoped status visibility, and Finance review while removing unnecessary direct client privileges. Do not expose virtual-account metadata by adding a broad owner policy without validating field scope.
- **No production data, schema, grants, policies, wallet balances, or payment records changed.** No PR merge or Render deployment occurred.


### Continuation update — 14 October 2026: deployed payment Edge Function trace

- **Live Supabase Edge Function inventory inspected read-only:** reviewed the deployed source for `billstack-payment` (v20), `billstack-webhook` (v18), and the legacy service payment functions (`datasub-payment`, `schoolpro-subscription`, `host-payment`, `consult-payment`, `engineering-payment`, `print-payment`, `business-payment`). The legacy service-payment endpoints return HTTP 410 and direct users to the supported bank-transfer workflow; they do not access `customer_payment_transactions`.
- **Active BillStack path:** `billstack-payment` reads/writes `profiles`, `virtual_accounts`, and `payment_provider_banks`; `billstack-webhook` records webhook events, verifies the transaction with BillStack, resolves the matching virtual account, writes `payment_transactions`, and calls the restricted `credit_verified_payment` RPC. It checks that the virtual account is active, customer-visible, and assigned to DataSub; other-platform legacy transfers are routed to Finance reconciliation rather than credited through this path. Neither deployed BillStack function references `customer_payment_transactions`.
- **Security assessment narrowed, not closed:** the inspected SchoolPro/service payment Edge Functions and deployed BillStack functions do not establish a current direct dependency on `customer_payment_transactions`. Database dependency search also found no views, materialized views, ordinary functions, or triggers referencing that table. The remaining uncertainty is direct client/module usage and any external consumer not represented in these inspected function sources. Before changing grants, inspect the repository's complete client call sites and the table's ownership/foreign-key relationships; then stage regression tests for DataSub virtual-account funding, webhook idempotency, customer outcome reads, and Finance review.
- **No production change:** only function-source retrieval and read-only inspection were performed. No function was deployed, no payment was initiated, and no schema, grant, policy, ledger row, merge, or Render deployment was changed.


### Continuation update — 14 October 2026: payment-table privilege and ownership review

- **Direct grants reconfirmed read-only:** `customer_payment_transactions` grants `anon` and `authenticated` SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, and TRIGGER privileges. The table has RLS disabled and no policies were found in the earlier inspection. This is a broad exposure surface for a table holding user IDs, amounts/status, provider references, and virtual-account identifiers/account metadata.
- **Relationship check:** the inspected schema reports no declared foreign-key constraints on `customer_payment_transactions`; by contrast, the canonical `payment_transactions.virtual_account_id` references `virtual_accounts.id`. No inspected deployed payment Edge Function reads or writes `customer_payment_transactions`; active BillStack processing uses `virtual_accounts`, `payment_transactions`, `webhook_events`, and the server-only `credit_verified_payment` function. `my_payment_outcomes(p_platform)` is a security-definer RPC executable by authenticated users but not anon, and its query scopes records by `auth.uid()` and requested platform against `payment_transactions`, with customer refund status joined by the same caller.
- **Proposed remediation (not applied):** treat `customer_payment_transactions` as an unreferenced legacy table until the complete client source is exhaustively searched. A candidate least-privilege change is to remove direct privileges from `anon` and `authenticated`, enable RLS as defense-in-depth, and retain service-role/server-side access only if a verified use remains. Do not add an owner SELECT policy to the raw table by default: virtual-account metadata should be exposed only through a scoped, minimal projection if a real UI dependency is found. First validate migration history and enumerate client usage so the table is not a hidden dependency.
- **Verification limitation:** GitHub code search returned no indexed matches for the table/RPC names, but its result was marked incomplete; this is not proof of an exhaustive repository-wide absence. The repository tree has 204 TS/TSX/JS/JSX source files, so the remaining step is to scan source blobs comprehensively (or clone/export the branch for a local text search), then run static checks and relevant payment-path regression tests against a non-production database. Do not apply the candidate migration to production yet.
- **No production changes:** no grants, RLS, policies, schema, data, Edge Functions, merge, or Render deployment were changed.


## 2026-10-15 continuation — legacy payment table source scan

- **PASS — source inventory:** Git tree for `fix/result-design-section-selection` was not truncated and contains exactly 204 JavaScript/TypeScript/JSX/TSX files. Each file blob was fetched and scanned for `customer_payment_transactions`, `my_payment_outcomes`, and `virtual_accounts`. No matching references were found in those 204 source files; the earlier GitHub indexed search remains non-authoritative, but this direct source scan completed without reported fetch failures.
- **Existing payment path review:** Previously inspected active BillStack Edge Functions use `payment_transactions`, `virtual_accounts`, and provider-bank data rather than `customer_payment_transactions`. The client-visible `my_payment_outcomes(p_platform)` RPC remains owner-scoped to `auth.uid()`; it is not a reason to grant direct access to the legacy table.
- **IMPLEMENTED IN BRANCH — not deployed:** Added `supabase/migrations/20261015120000_lock_down_legacy_customer_payment_transactions.sql` (commit `6e7615a4c6ad4597ad22be6534114c5cd7050ba2`). It revokes all direct table privileges from `PUBLIC`, `anon`, and `authenticated`, enables RLS without adding client policies, and preserves table data and existing `service_role` grants.
- **Verification status:** Migration is prepared on the feature branch only. It has **not** been executed against a database, and no isolated database/test harness was available in this step; therefore SQL execution and payment-flow regression tests are **BLOCKED / pending**, not passed. The source scan is static evidence only and does not prove runtime payment behavior.
- **Required pre-production regression checks:** Apply only to a disposable/staging database first; verify service-side virtual-account funding, owner-scoped payment outcomes/status, webhook idempotency, refund status, and Finance reconciliation. Confirm service-role access remains intact and anon/authenticated direct SELECT/INSERT/UPDATE/DELETE are denied. Inspect SQL migration history and runtime dependencies before production approval.
- **Safety boundary:** No production database changes, merges, or Render deployments were made. Keep PR #103 open and unmerged pending review and explicit approval.


## 2026-10-15 continuation — staging gate and cost confirmation

- **BLOCKED — isolated test database:** Supabase branch listing returned only the `main` development branch, marked `MIGRATIONS_FAILED`; it is not a verified clean staging target. No separate healthy staging branch is available in the current branch list.
- **Read-only database check only:** The connected IHLink Platform database reports `public.customer_payment_transactions` exists, RLS is disabled, and 14 client-role grant rows exist for `anon`, `authenticated`, or `PUBLIC`. This is a read-only observation; no grants, RLS settings, rows, or migrations were changed.
- **Advisor context:** The Supabase security advisor also reports broader existing warnings involving exposed `SECURITY DEFINER` functions and tables with RLS but no policies. These are separate findings and must be triaged individually; this payment-table task does not remediate them.
- **Cost gate:** Supabase's branch cost estimate for organization `gvtivfhraqixrurjryqz` is **US$0.01344 per hour** while the branch is active (actual billing may depend on provider terms). Creating a new isolated branch requires the user's explicit cost confirmation before proceeding.
- **Next action pending user approval:** Confirm whether to create a new Supabase development branch at the estimated hourly cost. Until then, keep the migration on the feature branch only. Do not apply it to the connected IHLink Platform database.
- **Safety boundary reaffirmed:** No production changes, merges, or Render deployments were made.


## 2026-10-15 continuation — no-cost static validation and test alternatives

- **User decision:** Do not create a paid Supabase development branch. No cost confirmation or branch-creation call was made.
- **Static migration review:** Re-fetched the candidate SQL migration and confirmed its intended sequence is transactional (BEGIN/COMMIT), revokes direct table privileges from PUBLIC, anon, and authenticated, enables RLS without adding client policies, and changes only a table comment besides the access-control statements. The migration contains no data deletion or payment-row mutation. This is a source-level review, **not a PostgreSQL execution/syntax pass**.
- **Important open verification before applying anywhere:** The migration comment says it preserves service-role access, but revoking privileges from PUBLIC can also remove privileges inherited through PUBLIC if the service_role does not have equivalent explicit grants. Before approving the migration, verify the table owner and effective/explicit service_role privileges in the isolated test database; then assert the effective privileges after migration. Do not assume that retaining explicit grants is enough until effective access is tested.
- **Repository / CI review:** supabase/migrations/20261015120000_lock_down_legacy_customer_payment_transactions.sql is present on the feature branch, after the latest listed migration timestamp. The repository has no supabase/config.toml at the checked path, so the normal application CI workflow does not currently provide a Supabase CLI local-stack migration test. The latest SchoolPro CI run [#730](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38718997407) was still in progress when checked; typecheck and the scripted checks through test-template-preview.mjs had passed, while the mobile/layout tests and production build were still pending. This CI job does not execute the candidate SQL migration.
- **No-additional-Supabase-cost alternative:** Add a separate GitHub Actions job using a disposable PostgreSQL service container, create a minimal fixture table and test roles, grant the same starting privileges, run the candidate migration, then assert: RLS is enabled; anon/authenticated/PUBLIC have no effective direct table privileges; the trusted server role retains the explicitly intended privileges; and the migration is repeatable only if its expected one-time behavior is documented. This uses the existing repository CI path rather than a billable Supabase branch. It is a good SQL/ACL contract test but does not reproduce Supabase Auth, Edge Functions, real table dependencies, or end-to-end payment settlement.
- **Higher-fidelity no-new-Supabase-bill option:** Run Supabase CLI + Docker locally against a disposable local stack, using a sanitized schema/fixture and seeded synthetic payment records. Apply the migration only to that local database and run role/ACL assertions plus mocked payment-path regressions. This costs no additional Supabase branch usage, but requires Docker/local resources and a faithful enough fixture. Do not point local migration tooling at the connected IHLink Platform project.
- **Status:** static source review performed; migration execution, effective service-role privilege verification, and payment-flow regression tests remain **BLOCKED / pending**. Keep the migration unapplied. No production schema/grants/policies/data, merge, or Render deployment changed.


## 2026-10-15 continuation — disposable PostgreSQL migration test added and passed

- **Implemented on the feature branch:** Added `scripts/test-legacy-payment-migration.sh` and `.github/workflows/legacy-payment-migration-test.yml`. The workflow provisions a disposable PostgreSQL 17 service container in GitHub Actions; it does not connect to Supabase or Render and incurs no Supabase branch charge.
- **PASS — SQL execution in disposable PostgreSQL:** GitHub Actions run [Legacy payment migration ACL test](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38719431031) completed successfully. The candidate migration executed inside its transaction. Assertions verified RLS enabled, all tested direct table privileges denied to `anon` and `authenticated`, and explicitly granted SELECT/INSERT/UPDATE/DELETE privileges preserved for a fixture `service_role` configured with `BYPASSRLS`.
- **Scope of evidence:** This is a useful migration syntax and ACL contract test against a minimal synthetic table. It does not prove the connected IHLink Platform project's current service-role grants, actual table dependencies, Supabase Auth behavior, Edge Function behavior, payment settlement, refunds, or Finance reconciliation. In particular, the test explicitly grants privileges to its synthetic `service_role`; production's effective grants must still be inspected read-only before any deployment decision.
- **Current gate:** Keep the migration unapplied to Supabase production. Next no-cost checks are to inspect the production table ACL/role membership and ownership read-only, then add deeper local/CI regression coverage for payment outcomes and webhook paths where practical. Do not run migrations against the connected project. No production data/schema/grants/policies changed; no PR merge or Render deployment.


## 2026-10-15 continuation — connected-project ACL recheck (read-only)

- **Connected IHLink Platform project, read-only verification:** `public.customer_payment_transactions` is owned by `postgres`; `relrowsecurity=false`; the raw ACL explicitly grants all seven direct table privileges (SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER) to both `anon` and `authenticated`, and explicitly grants the same privileges to `service_role`. Effective privilege checks confirmed `anon` and `authenticated` can currently SELECT/INSERT/UPDATE/DELETE/TRUNCATE; `service_role` has effective access and `BYPASSRLS=true`.
- **Effect on candidate migration:** The connected project's current ACL shows explicit `service_role` grants, so the candidate's `REVOKE ... FROM PUBLIC, anon, authenticated` does not appear to revoke the explicit service-role ACL entries. This is still a read-only observation; it is not permission to apply the migration, and the production table remains unchanged.
- **Security issue remains real:** Direct client roles currently have broad effective access while RLS is disabled. The passing disposable PostgreSQL test establishes the candidate migration's basic SQL/ACL behavior; it does not validate every live application dependency or payment journey. Keep production change gated on a reviewed rollout and regression evidence.
- **No production change:** The SQL used only SELECT statements against catalog/privilege metadata. No grants, RLS, rows, schema, migration history, Edge Functions, PR merge, or Render deployment were changed.


## 2026-10-15 continuation — payment dependency inventory and CI recheck

- **Read-only dependency check:** PostgreSQL catalog query found no declared foreign-key constraints where `public.customer_payment_transactions` is either the referencing or referenced table. A search of ordinary stored functions' definitions found no function body referencing this legacy table. The trigger-catalog query did not return usable evidence, so triggers are **not yet cleared** by this check. No data was sampled or modified.
- **Cross-check with source/Edge Function review already recorded above:** the repository scan found no client source references to `customer_payment_transactions`; inspected active BillStack functions use `payment_transactions` / `virtual_accounts`, while the reviewed legacy platform payment functions return HTTP 410 and direct callers to the supported bank-transfer path. This reduces known dependency risk but does not prove there are no dynamic SQL, external integrations, uninspected functions, triggers, scheduled jobs, or operational scripts using the table.
- **Fresh CI evidence on current PR head `eceb56d7a70fda1ce9e9631cf0c7381cb6084ae7`:** the payment-page validation run [#495](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38719613334), disposable PostgreSQL ACL test [#6](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38719613247), and SchoolPro CI [#733](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38719437506) all report success. These are CI results, not authenticated production payment-path acceptance tests.
- **Decision:** the dependency inventory is improved but not sufficient to approve production application. Next required checks are trigger inventory via a simpler catalog query, a final scan for dynamic/operational references, and documented regression cases for payment outcomes, webhook idempotency, settlement/crediting, refunds, and finance reconciliation. Then present a controlled rollout/rollback checklist for explicit approval. Do not merge PR #103, apply production DDL, or deploy to Render as part of this step.
- **No production mutation:** all database queries in this continuation were read-only catalog queries; no grants, policies, rows, schema, Edge Functions, merge, or deployment were changed.


- **Trigger inventory completed (read-only):** a direct `pg_trigger` catalog query returned no non-internal triggers on `public.customer_payment_transactions`. Together with the prior empty FK and stored-function-reference checks, there are no declared FKs, ordinary stored-function body references, or user-defined triggers found on this table. This still cannot exclude dynamic SQL or external/operational consumers.


## 2026-10-15 continuation — payment regression matrix and deployed-vs-repository mismatch

### Deployed behavior confirmed read-only
- **Supabase function inventory:** `schoolpro-payment` is ACTIVE at deployed version 14 with `verify_jwt=false`. Its deployed source returns HTTP 410 `bank_transfer_required` for non-OPTIONS requests and instructs users to use the bank-transfer receipt workflow. `schoolpro-subscription` is ACTIVE at version 4 with `verify_jwt=true`, but its deployed source also returns HTTP 410 `bank_transfer_required`. Thus SchoolPro online checkout through these two legacy functions is intentionally unavailable in the currently inspected deployment; do not report Flutterwave/online checkout as working.
- **Repository mismatch:** the feature branch's `supabase/functions/schoolpro-payment/index.ts` is different from deployed version 14: the checked-in file accepts authenticated requests and supports an `instructions` action, then returns `unsupported_action` for other actions. The deployed function does not contain that logic. This is a code/deployment drift item that needs reconciliation before a function deployment; do not deploy it blindly because its auth, checkout, and payment-finalization behavior has not passed a full review.
- **Database components present:** read-only catalog queries show `schoolpro_payment_intents`, `schoolpro_fee_payments`, `schoolpro_invoices`, `payment_transactions`, and `webhook_events` schemas, plus a `finalize_schoolpro_payment` SECURITY DEFINER function with execute denied to anon/authenticated and granted to service_role. Their existence does not prove the corresponding provider callback/checkout is live.
- **Current supported payment posture from deployed function text:** bank transfer and Finance receipt verification for SchoolPro; BillStack's live payment function explicitly restricts virtual accounts to DataSub. Keep SchoolPro and other services on configured bank-transfer workflows unless/until a reviewed online payment implementation is deliberately approved and deployed.

### Payment regression checklist (not yet run as end-to-end acceptance)
1. **Receipt / bank-transfer workflow**
   - Owner can submit a receipt only for their own payable invoice; a different user cannot submit or inspect the proof.
   - Validate allowed MIME types, maximum file size, receiving bank ownership/school scope, amount not above outstanding balance, valid transfer date, unique source/customer reference, and safe storage path.
   - Receipt submission alone must never mark an invoice paid or activate service.
   - Finance approval must atomically record the payment, update only the correct invoice/order/subscription, preserve an audit trail, and reject duplicate approvals; rejection must retain evidence and reason.
2. **Provider webhook / idempotency (DataSub BillStack path)**
   - Reject invalid/missing signature and malformed/unknown references; record event result without crediting.
   - Duplicate/replayed successful events must not double-create ledger entries, wallet credits, service fulfilment, or receipts.
   - Verify owner, platform, provider, currency, exact amount, settlement status and provider reference before crediting.
   - Out-of-order failure then success, success then duplicate success, and retry after transient DB/provider failure must produce deterministic, recoverable states.
3. **Settlement and crediting**
   - Pending/unsettled or amount-mismatched transaction never credits.
   - One verified settled payment creates exactly one ledger credit and one final payment state.
   - A failed/rolled-back database transaction cannot leave a wallet balance without its ledger record or vice versa.
4. **Refunds / failed fulfilment**
   - Refund request, review, provider execution, final processed state, wallet reversal and ledger entry must be separately auditable.
   - Duplicate refund callbacks or repeated processing cannot double-refund; partial refunds must respect refundable balance; denied refunds must not change balances.
   - Failed fulfilment refund queue is reconciled against original purchase and wallet ledger.
5. **Finance reconciliation**
   - Reconcile provider settlements against `payment_transactions`, webhook events, wallet ledger, invoices, receipts, refunds and service fulfilment using stable references and amount/currency.
   - Report unmatched provider credits, unmatched internal credits, duplicates, stale pending transactions, fees/margins, and refund mismatches; export must be reproducible.
   - SchoolPro payments reconcile against school-owned invoices/accounts and must remain separate from IHLink subscription revenue.

### Controlled rollout and rollback gate
- Do not apply the legacy-table migration or deploy any Edge Function until a reviewer approves the exact target and scope.
- Before a production rollout: snapshot/export relevant schema and ACL metadata; record function versions/hashes and active payment configuration; confirm rollback steps; run tests in a disposable local environment with synthetic data; ensure finance can reconcile a known transaction; schedule a low-volume window and establish a payment support contact.
- Apply the narrowly scoped ACL migration only after confirming the legacy table has no remaining consumers. Immediately re-query RLS, role grants, and service_role effective privileges; smoke-test owner-scoped payment outcomes, BillStack virtual-account creation, webhook verification/settlement, and Finance refund/reconciliation paths.
- Rollback should restore only the previously captured grants if the approved migration causes an identified legitimate server-side break; do not disable RLS or regrant client roles broadly as a generic fallback. Keep data intact and investigate the failing dependency.
- **Not yet complete:** the above are test specifications, not evidence that those acceptance tests have passed. Live end-to-end provider transactions/refunds and a production rollout are not authorized or performed in this step.
- **No production mutation:** this continuation only inspected deployed Edge Function source and database catalogs, then updated this guide. No DDL, rows, grants, function deployments, merge, or Render deployment changed.

## 2026-10-15 — confirmed payment ownership rule (authoritative)

The owner-confirmed requirement is explicit and supersedes any ambiguous payment wording elsewhere in this handover:

- **BillStack is DataSub-only.** BillStack virtual accounts, payment initiation, provider webhooks, and provider reconciliation must not be used by SchoolPro subscriptions, SchoolPro school fees, or any other IHLink service.
- **SchoolPro subscription invoices:** the school uploads proof of its bank transfer against its IHLink/SchoolPro subscription invoice. An authorized IHLink Super Admin/subscription administrator reviews the evidence against the receiving account and invoice, then marks the subscription as paid only after verification. Receipt upload alone must not activate/renew a subscription.
- **School fees:** the parent/student submits proof against the correct fee invoice where enabled. An authorized finance user at that school (e.g. bursar) reviews and marks it paid only after verification. Enforce school tenancy on the invoice, receipt, payment record, and reviewer permission; staff from another school must not read or change it.
- **Separate financial ledgers:** IHLink subscription revenue belongs to the IHLink billing workflow; tuition and other school charges belong to that school's fee ledger. Do not combine them or let school-fee approval mark an IHLink subscription paid.
- **Required audit trail:** retain uploader, invoice and school/subscription scope, receipt object reference, claimed amount/date, reviewer, decision timestamp, approved amount/reference, and rejection reason. Reject duplicate approvals and ensure payment status changes are atomic. Never store receipt file contents or sensitive banking details in ordinary logs.
- **Implementation gate:** verify the actual upload, review/approve/reject, invoice update, subscription entitlement, and audit paths in code and tests. Current deployed schoolpro-payment / schoolpro-subscription handlers return HTTP 410 and direct users to bank-transfer workflows; that is not proof the complete receipt-review journey works. Reconcile repository/deployment drift before changing deployment. No production DDL, payment mutation, function deployment, merge, or Render deployment was performed by documenting this rule.

## 2026-10-15 continuation — SchoolPro receipt workflow contract tests

### Source inspection findings
- Parent fee payment page (`src/pages/schoolpro/SchoolProPayments.tsx`) uploads receipts to `schoolpro-payment-receipts` with `upsert:false`, then calls `submit_schoolpro_payment`; the UI says submissions await school finance review.
- School Fees & Finance (`src/pages/schoolpro/SchoolProFees.tsx`) loads `schoolpro_payment_submissions` scoped by `school_id`, offers pending proof rejection/confirmation through `review_schoolpro_payment_submission`, and exposes a manual full-balance correction through `record_schoolpro_payment` for authorized school finance roles. Server-side RPC authorization/atomicity still needs a database-source and negative-permission test; a client page is not sufficient proof.
- Subscription workspace (`src/pages/schoolpro/SchoolProSubscription.tsx`) calls `prepare_schoolpro_bank_subscription` and embeds `BankTransferPayments` with platform `schoolpro_subscription`; its copy says Finance verification activates or renews the subscription. The shared transfer component checks proof MIME/size, uploads with `upsert:false`, calls `submit_service_bank_transfer`, and explicitly says upload does not activate service.
- The currently checked-in `supabase/functions/schoolpro-payment/index.ts` is not an online checkout implementation. Its `instructions` path checks an active guardian link and returns school bank accounts; it must not be deployed as a substitute for the full receipt workflow without reviewing the deployed/repository mismatch.

### Regression test added and run
- Added `scripts/test-schoolpro-receipt-payment-contract.mjs` and `.github/workflows/schoolpro-receipt-payment-contract.yml` to the feature branch. The contract checks cover receipt upload without overwrite, fee proof submission, confirmation/rejection RPC calls, manual payment recording, bank-transfer subscription preparation, upload-not-paid messaging, and absence of BillStack/online checkout code in the SchoolPro payment Edge Function.
- GitHub Actions run **38721508630** completed successfully: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38721508630
- This is a static source-contract test only. It does **not** prove real user permissions, RLS/storage access, RPC transaction atomicity, receipt download/review UI, duplicate approval prevention, invoice balance integrity, subscription entitlement activation, or end-to-end bank reconciliation. Those remain explicit acceptance tests.
- Payment ownership remains fixed: BillStack is DataSub-only; SchoolPro subscriptions use receipt upload and IHLink-side verification; school fees use receipt upload and school-side finance verification. No production DB changes, live payment submissions, Edge Function deployments, merge, or Render deployment were performed.

### Next focused check
- Inspect the SQL definitions and grants/policies for `submit_schoolpro_payment`, `review_schoolpro_payment_submission`, `record_schoolpro_payment`, `prepare_schoolpro_bank_subscription`, and `submit_service_bank_transfer`. Confirm school/user ownership, role checks, receipt storage isolation, duplicate-reference/duplicate-review handling, and atomic invoice/subscription status transitions before proposing any runtime changes.

## 2026-10-15 continuation — live SQL receipt-review RPC audit (read-only)

Read-only inspection of the connected Supabase project confirmed both receipt buckets are private and have a 5 MiB limit with MIME allowlists for JPEG, PNG, WebP, and PDF. The `schoolpro-payment-receipts` storage policies allow authenticated owners to upload/read only paths whose first folder is their own user ID. No production data or schema was changed.

### Confirmed SQL behavior
- `review_schoolpro_payment_submission` is SECURITY DEFINER and does check Finance module access, school finance role (`proprietor`, `administrator`, `accountant`, `bursar`), pending status, locks the submission and invoice rows, validates each allocation against the invoice's remaining balance, writes fee-payment records, updates invoice balances, and marks the submission reviewed in one database transaction. It rejects already-reviewed submissions. These are source-level findings; a full negative-permission test has not run.
- `record_schoolpro_payment` is SECURITY INVOKER, checks school finance role, positive two-decimal amount, reference, supported method, and balance ceiling, then writes payment and invoice update in one transaction. The manual 'mark fully paid' UI uses this function rather than directly editing invoice status.
- `prepare_schoolpro_bank_subscription` checks active account, school ownership or manager role, published annual price and company bank-account availability. It creates/returns a pending bank-transfer intent, not a BillStack checkout.
- `submit_service_bank_transfer` verifies the subscription intent belongs to the authenticated payer, is pending and bank-transfer-only, and the amount matches; it verifies the uploaded object exists in the private `direct-transfer-proofs` bucket and is under the user's path. A unique index protects repeated transfer references.

### High-priority gap identified
- `submit_schoolpro_payment` checks guardian-school/student relationships, invoice school scope, positive allocation and outstanding balance, and equality between allocations and the declared total. However, the current function body does **not** itself validate that `p_receipt_path` belongs to `auth.uid()`, that a matching object exists in `schoolpro-payment-receipts`, or that the declared MIME type matches the uploaded object/allowlist. Storage policies protect actual uploads, but they do not stop a caller from invoking the SECURITY DEFINER RPC with an arbitrary or nonexistent path. This can create a submission the school finance reviewer cannot inspect and weakens the database boundary.
- The same function does not lock invoice rows while accepting allocations, unlike the review RPC. A race between concurrent submissions may allow two pending submissions to reserve the same remaining balance; the reviewer will reject an over-balance confirmation later, but the submitter may see misleading pending proofs. The next code fix should add path/object/MIME/size validation and deterministic invoice locking/duplicate handling, then add disposable-database regression tests for forged paths, missing objects, unsupported MIME, another user's path, duplicate bank reference, concurrent over-allocation, and valid owner submission.
- **Not fixed yet:** no migration has been applied or deployed. The next change should be a reviewed branch migration and isolated test, not a direct production SQL edit. Keep the confirmed payment split: BillStack is DataSub-only; SchoolPro subscriptions are IHLink-reviewed bank receipts; school fees are school-finance-reviewed bank receipts.
