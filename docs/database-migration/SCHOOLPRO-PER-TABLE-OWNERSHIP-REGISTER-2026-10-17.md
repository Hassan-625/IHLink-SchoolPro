# SchoolPro per-table ownership decision register — 2026-10-17

## Status

**Decision register v0.1; no export/import approval.** Live catalog query against Supabase project `lnqsroyiybutkfngbyge` identified 107 public `schoolpro_*` tables: 89 have a direct `school_id`; 18 do not. The following decisions establish intended ownership semantics for review, but they are not a declaration that all live rows have passed integrity validation. Child-table tenant boundaries must be proven by joins and preserved/enforced in the target schema.

## Direct tenant key (89 tables)

**Decision:** treat as school-owned candidate data keyed by `school_id`, except where row semantics, shared references, platform-level rows, or payment/identity boundaries override the default. Before export, verify no null/invalid school IDs, tenant/parent mismatch, cross-school FK mismatch, shared/global rows, or unexpected records in each table. The presence of `school_id` alone is not sufficient for row inclusion.

## Tables without a direct `school_id` (18)

| Table | Observed ownership anchor | Proposed ownership disposition | Required validation before export |
|---|---|---|---|
| `schoolpro_schools` | Tenant root; FK to `profiles.id`; owner identity | Tenant-root table. Include schema; rows require explicit owner/school allowlist. Preserve original school UUIDs. | Validate owner identity reference, unique school code, soft-delete/status fields, and exact allowed school set. Do not copy unrelated schools. |
| `schoolpro_admission_acceptances` | FK to `schoolpro_admission_offers.id` and `schoolpro_admissions.id` | Child of a school-owned admission workflow. | Confirm offer and admission belong to same school; reject orphan or mismatched pairs. |
| `schoolpro_admission_documents` | FK to `schoolpro_admissions.id` | Child of admission; tenant inherited through admission. | Validate admission parent and storage object key ownership; no raw Storage metadata/file copy by default. |
| `schoolpro_admission_events` | FK to `schoolpro_admissions.id` | Child audit/event data; tenant inherited through admission. | Validate parent school and event retention/privacy requirements. |
| `schoolpro_admission_offers` | FK to `schoolpro_admissions.id` | Child of admission; tenant inherited through admission. | Validate offer/admission school consistency and unique workflow constraints. |
| `schoolpro_assignment_submissions` | FKs to `schoolpro_assignments.id` and `schoolpro_students.id` | Child of assignment/student; tenant inherited only if both parents agree. | Explicitly reject assignment/student pairs belonging to different schools; verify submission attachments/storage keys. |
| `schoolpro_candidate_cbt_answers` | FKs to `schoolpro_candidate_cbt_attempts.id` and `schoolpro_question_bank.id` | Child of candidate attempt/question; inherit through attempt and validate question scope. | Validate candidate attempt -> admission -> school, test/question compatibility, and no cross-school question linkage. |
| `schoolpro_candidate_cbt_attempts` | FKs to `schoolpro_admissions.id` and `schoolpro_cbt_tests.id` | Child of admission/test. | Validate admission and test share a school and test eligibility constraints. |
| `schoolpro_cbt_answers` | FKs to `schoolpro_cbt_attempts.id` and `schoolpro_question_bank.id` | Child of student attempt/question. | Validate attempt -> student/test -> school and question/test/school consistency. |
| `schoolpro_cbt_attempts` | FKs to `schoolpro_cbt_tests.id` and `schoolpro_students.id` | Child of student/test. | Validate student and test share school; enforce attempt uniqueness and status invariants. |
| `schoolpro_cbt_test_questions` | FKs to `schoolpro_cbt_tests.id` and `schoolpro_question_bank.id` | Child of test/question. | Validate test/question school and subject compatibility. |
| `schoolpro_fee_items` | FK to `schoolpro_fee_structures.id` | Child of fee structure; tenant inherited through parent. | Validate parent fee structure school, currency/amount constraints and duplicate item semantics. |
| `schoolpro_student_activation_challenges` | FK to `schoolpro_students.id` | Student/account challenge; tenant inherited through student. | Validate student parent, expiry/consumption state, and avoid exporting live secrets/tokens unless explicitly approved. Prefer invalidating/reissuing transient challenges during cutover. |
| `schoolpro_account_challenges` | FK to `schoolpro_initial_credentials.user_id` | Account challenge; infer tenant only via the related initial-credential record, not caller input. | Validate credential-to-school linkage, token hashing, expiry and consumption; do not copy reusable secrets without explicit security review. |
| `schoolpro_plan_catalog` | No FK / no direct tenant key | Platform-wide catalogue/configuration, not tenant-owned rows. | Recreate/seed approved catalogue values separately; confirm source of truth and exclude accidental customer-specific values. |
| `schoolpro_subscription_catalog` | No FK / no direct tenant key | Platform-wide subscription catalogue/configuration. | Recreate/seed approved catalogue values separately; compare active annual/demo/grace rules with application requirements. |
| `schoolpro_subscription_plans` | No FK / no direct tenant key | Platform-wide plan catalogue/configuration. | Resolve whether this overlaps `schoolpro_subscription_catalog`; select one authoritative representation or map explicitly. |
| `schoolpro_login_attempts` | No FK / no direct tenant key | Account/security telemetry; currently unscoped and potentially cross-product. Exclude historical rows by default; do not bulk-copy. | Confirm write paths, retention and account-key semantics. If needed, define a new target-local security log with bounded retention and privacy review. |

## Cross-table integrity rule

For each child table above, a simple FK to a parent UUID does not prove tenant agreement. The migration rehearsal must run anti-join checks for every parent combination and report zero orphan/mismatched rows before import. The target schema should use composite tenant-aware FKs where viable, or equivalent server-side integrity checks with negative tests. Preserve stable UUIDs where required; do not fabricate identity rows or duplicate Auth credentials.

## Explicit exclusions and external ownership

- Keep Supabase Auth as the initial identity provider; do not copy auth users, sessions, refresh tokens, MFA secrets or password hashes into Aiven.
- Keep shared `profiles`, payment/virtual-account ledgers, DataSub/BillStack, Supabase Storage service metadata and shared email-delivery queue outside bulk SchoolPro export unless a separately approved, narrow integration requires specific references.
- The 79 foreign keys crossing the simple SchoolPro-only boundary require individual mapping and cannot be treated as automatically portable.

## Approval status

- **Schema-level ownership classification:** proposed for all 107 tables (89 direct-key candidates; 18 exceptions classified above).
- **Row-level inclusion and referential-integrity sign-off:** pending read-only row audits, parent consistency checks, data-retention review, and authoritative SQL provenance reconciliation.
- **Export/import:** not approved.


## Read-only tenant integrity follow-up — 2026-10-17

The [live tenant-relation catalog reconciliation](LIVE-TENANT-RELATION-CATALOG-RECONCILIATION-2026-10-17.md) documents 17 targeted cross-school consistency joins returning zero mismatches and maps current trigger enforcement to each affected relationship. This is not a complete ownership sign-off: orphan/null checks, storage object ownership, future cross-tenant negative read/write tests and routine/trigger ACL review remain. The issued-document SELECT policy's tautological `st.school_id = st.school_id` predicate is flagged for approved correction and adversarial tests. No production writes were made.