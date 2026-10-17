# Live tenant-relation and missing-object reconciliation — 2026-10-17

## Scope and safety

Read-only catalog queries against Supabase project `lnqsroyiybutkfngbyge`. No production DDL, data changes, migration replay, export/import, configuration change or merge occurred. This is a schema/evidence reconciliation, not production approval.

## Current enforcement functions and trigger bindings

The branch-only migration names do not all match current routine names. Live catalog inspection found current, differently named enforcement paths:

| Relationship area | Live trigger / function evidence | Assessment |
|---|---|---|
| Results | `enforce_schoolpro_result_relations` -> `private.enforce_schoolpro_tenant_relations()`; also `trg_validate_schoolpro_result_tenant` -> `private.validate_schoolpro_result_tenant()` | Both check student and subject school agreement; first also checks assessment-scheme school. Function names in the branch-only file differ, but current equivalents exist. |
| CBT test questions | `enforce_schoolpro_cbt_question_relations` -> `private.enforce_schoolpro_tenant_relations()` | Function derives school from the test and verifies the question-bank row has that school. |
| CBT eligibility | `enforce_schoolpro_cbt_eligibility_relations` -> `private.enforce_schoolpro_tenant_relations()` | Checks test, optional student and optional class against `new.school_id`. |
| Candidate CBT attempts | `trg_candidate_cbt_tenant` -> `private.validate_candidate_cbt_tenant()` | Checks admission/application and CBT test belong to the same school. |
| Guardian links | `schoolpro_guardian_school_scope` -> `private.schoolpro_guardian_school_scope()` | Checks linked student belongs to selected school. |
| Document issues | `enforce_schoolpro_document_issue_relations` -> `private.enforce_schoolpro_tenant_relations()`; `trg_guard_schoolpro_document_issue_lifecycle` -> `private.guard_schoolpro_document_issue_lifecycle()` | Both check student/template school agreement on write/creation. The named validator in the branch file is absent, but a different current trigger path exists. |
| Lesson notes | `schoolpro_lesson_workflow`, `schoolpro_validate_activity_calendar`, `schoolpro_preserve_activity_session`, plus `schoolpro_activation_before_write` | No function named `validate_schoolpro_lesson_notes_tenant` was found. Current RLS policies constrain school access and author/leader scope; the trigger set enforces workflow/calendar/session behavior. Exact semantic equivalence to the proposed tenant validator is **not proven**. |
| Result approvals | `schoolpro_activation_before_write`; current RLS policies require module access and management or exam-officer/head-teacher/vice-principal role within the same `school_id` | No function named `validate_schoolpro_result_approvals_tenant` was found. RLS role/school scoping exists, but it is not identical evidence to a trigger validator. |
| Promotions | `schoolpro_activation_before_write`, `schoolpro_archive_applied_progression`; current RLS policy constrains school access and management roles | No function named `validate_schoolpro_promotions_tenant` was found. Existing policies and archive trigger exist, but exact tenant-validation equivalence is **not proven**. |

The current shared trigger function is `SECURITY DEFINER` with an empty `search_path`; this is a positive hardening signal, not a complete grant/owner audit. Trigger existence and function definitions must still be paired with effective table privileges, full policy composition and negative authorization tests.

## Read-only cross-tenant row consistency checks

The following joins were executed against current rows. Each reported **0 mismatched rows**:

- results -> students, subjects and assessment schemes
- guardian links -> students
- document issues -> students and document templates
- CBT eligibility -> tests, students and classes
- CBT test-question mappings -> test/question-bank school
- candidate CBT attempts -> admission/application and test school
- lesson notes -> classes and subjects
- promotions -> students, source class and target class
- result approvals -> results

**Interpretation:** no existing cross-school mismatch was found by these 17 targeted inner-join checks. These checks do not count orphaned foreign keys (an inner join omits orphans), null relationships, inaccessible rows, storage-object key mismatches, or future writes. They do not prove that RLS denies cross-tenant reads or that trigger/RPC bypass paths are safe. Before migration approval, add explicit orphan counts, null/invalid-school counts, storage key checks and two-tenant negative write/read tests.

## Concrete policy predicate defect to review

The live policy `students read own issued documents` on `schoolpro_document_issues` includes the predicate `st.school_id = st.school_id`, which is tautological rather than comparing the student's school to the document issue's `school_id`. The same predicate also checks `st.id = schoolpro_document_issues.student_id` and `st.user_id = auth.uid()`; current write-time triggers check student/document school agreement and the row audit found zero current student-school mismatches. Nonetheless, the policy's school predicate is defective and should be corrected to compare `st.school_id` to `schoolpro_document_issues.school_id`, then tested with mismatched-school rows and authenticated student identities. **No policy change was applied** because production writes are outside this audit's authorization.

## Missing-object discrepancies: resolved as names, not assumed equivalent

- `schoolpro_family_result_periods` and `schoolpro_family_report_media` are absent as tables. Current result-release logic uses private JSONB caches, including `private.schoolpro_cached_family_result_periods()` and `private.schoolpro_cached_result_reader_keys()`, which derive allowed student/term/session or reader keys from students, guardian links, assignments, enrollment history and `private.schoolpro_result_access(...)`. This is a materially different implementation from a persisted family-period/media table; report media storage must be traced separately.
- `schoolpro_plan_attempts` and `schoolpro_plan_answers` are absent. Current CBT plan checks instead use `schoolpro_cbt_tests`, `schoolpro_cbt_attempts`, and helper functions `private.schoolpro_cbt_test_plan_allowed(uuid)` and `private.schoolpro_cbt_answer_plan_allowed(uuid)`. The latter derives the test from an attempt. Do not create missing tables merely because an older migration file references names that no longer exist.
- Current catalog includes `schoolpro_candidate_cbt_answers`, `schoolpro_candidate_cbt_attempts`, `schoolpro_cbt_answers`, `schoolpro_cbt_attempts`, `schoolpro_cbt_eligibility`, `schoolpro_cbt_test_questions`, `schoolpro_cbt_tests`, `schoolpro_result_access_events`, `schoolpro_result_access_overrides`, `schoolpro_result_access_pins`, and `schoolpro_subscription_plans`.

These discrepancies are best classified as **different current architecture / probable rename or replacement; provenance still unresolved** until commit-by-commit SQL diffs and object dependency review identify when and why the change occurred.

## Required next checks

1. Review and test the student-issued-document RLS predicate; obtain explicit approval before production policy changes.
2. Add orphan/null checks and read/write cross-tenant negative tests for every child relationship, especially CBT question-bank/test links, document output paths and inherited-parent tables.
3. Compare full current RLS policies and routine ACLs against the original migration SQL once recovered; don't treat matching table names or current helper names as exact historical equivalence.
4. Identify how family report media is stored and how its storage object keys are tied to school/student ownership.
5. For lesson notes, approvals and promotions, confirm current RLS role predicates plus write triggers with targeted adversarial tests. No equivalent named trigger validator should be assumed.


## Related ledger work

The [live-only migration version inventory](LIVE-ONLY-MIGRATION-VERSION-INVENTORY-2026-10-17.md) contains all 397 live-only versions with provisional product-scope triage. The [remote-batch SQL/deployment provenance register](REMOTE-BATCH-SQL-DEPLOYMENT-PROVENANCE-REGISTER-2026-10-17.md) corrects the marker count to 35 distinct versions and records the unresolved original SQL/deployment evidence. These links are supporting handover artifacts; no production changes were applied.

## Additional orphan and storage-ownership checks — 2026-10-17
Read-only live queries added explicit LEFT JOIN orphan counts (not just inner-join mismatch checks):
- `schoolpro_document_issues`: 141 rows; student references: 0 orphans, 0 nulls, 0 school mismatches; template references: 0 orphans, 0 nulls, 0 school mismatches.
- `schoolpro_document_issue_events`: 83 rows; 0 orphan issue references and 0 event/issue school mismatches.
- `schoolpro_academic_documents`: 96 rows; 0 orphan student references and 0 school mismatches.
- `schoolpro_admission_documents`: 0 rows; application orphan count is therefore vacuously zero, not a meaningful exercised test.
- `schoolpro_document_issues.output_storage_path`: 83/83 non-null paths match an object in the `schoolpro-document-outputs` bucket; 0 missing objects, 0 wrong-bucket matches.
- `schoolpro-admission-documents` and `schoolpro-admissions` each currently have zero stored objects; admission-document storage access remains untested on real objects.
- Storage bucket catalog: `schoolpro-document-outputs` is private with 83 objects; `schoolpro-document-templates` private with 9; `schoolpro-demo-documents` private with 2; `schoolpro-result-outputs` private with 1; `school-result-templates` private with 8; `schoolpro-admissions` private with 0; `schoolpro-payment-receipts` private with 0; `schoolpro-branding` is marked public but has 0 objects.
- Storage policy definitions include school-scoped folder checks for admission objects, issue-path-based checks for document outputs, and school-scoped checks for document templates. Definition inspection does not replace authenticated two-school negative read/write/delete tests.
- **Not yet proven:** cross-tenant reads via PostgREST and download endpoints, object-key tampering, path-prefix spoofing, service-role bypass, RPC/view side channels, and behavior under non-member roles. No adversarial identities were used against production.

## Authenticated two-identity read probe — 2026-10-17
A read-only transaction-scoped probe set `ROLE authenticated`, supplied the JWT subject claim for two existing student-only identities from different schools, queried issue rows and document-output objects, and rolled each transaction back. No rows were changed.
- School `7a340a27-9184-420a-b566-8fc0d3dac555`: 0 visible document issues and 0 visible document-output objects.
- School `d342eb87-8d6a-477a-a380-7fab83f586b7`: 1 visible issue and 1 visible document-output object; no visible issue rows or output objects belonging to another school.
- This is a positive, sampled current-policy read-isolation result. It does **not** prove the proposed policy fix: existing data has no mismatched issue/student school rows, and no synthetic adversarial fixture, write/update/delete, guardian/staff role, RPC, or download-endpoint test was run. Production was not modified.
