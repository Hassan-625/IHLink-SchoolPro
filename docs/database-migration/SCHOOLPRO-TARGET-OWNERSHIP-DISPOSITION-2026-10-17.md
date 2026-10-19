# SchoolPro target ownership disposition register — 2026-10-17

## Scope and decision boundary

This register resolves the **technical target disposition** for all 18 SchoolPro tables that lack a direct `school_id`. It does not authorize data export, import, production DDL, or cutover. Current Supabase remains the production source of truth. The Aiven PostgreSQL target must be accessed only through a trusted server-side API; browser/mobile clients must not receive Aiven credentials.

The dispositions below are the proposed migration contract for schema design and rehearsal. User/data-owner sign-off and target-schema implementation/testing remain separate gates.

## Per-table target disposition

| Table | Live rows (2026-10-17) | Target disposition | Ownership / integrity rule | Rehearsal and cutover rule |
|---|---:|---|---|---|
| `schoolpro_schools` | 2 | **Migrate allowlisted tenant roots** | Each root is the tenant boundary. Preserve stable school UUIDs only for explicitly approved schools; owner identity remains an external Supabase identity reference. | Include only explicit tenant allowlist; verify owner authorization through trusted API; reject unknown school IDs. |
| `schoolpro_admission_acceptances` | 0 | **Schema + parent-derived ownership** | Tenant derives through the admission/application and offer; parent pair must resolve to same school. | No current rows; test valid and cross-school parent pairs using synthetic fixtures. |
| `schoolpro_admission_documents` | 0 | **Schema + metadata only; object payload separate** | Admission/application parent determines school. Object key must be verified against the same school and expected Storage bucket. | Do not migrate file bytes by default. Require Storage API tests and object manifest before any file move. |
| `schoolpro_admission_events` | 4 | **Migrate only parent-valid event history** | Every event must resolve to an admission in an allowlisted school; actor IDs are external identity references. | Reconcile retention/audit requirements; verify all four parents and preserve event ordering/timestamps. |
| `schoolpro_admission_offers` | 0 | **Schema + parent-derived ownership** | Offer must belong to an admission/application in the same school. | Empty at snapshot; test cross-school offer-parent attempts. |
| `schoolpro_assignment_submissions` | 27,440 | **Migrate filtered operational rows** | Require assignment.school_id = student.school_id = approved tenant; submission's assignment and student must be same-school. | Row count must reconcile by school and parent; add composite tenant-safe references/constraints or enforce through transactional trusted API. |
| `schoolpro_candidate_cbt_answers` | 0 | **Schema; no current data** | Ownership derives from candidate attempt and its admission/test; question must be valid for that attempt/test scope. | Do not fabricate rows. Test cross-school attempt/question rejection. |
| `schoolpro_candidate_cbt_attempts` | 0 | **Schema; no current data** | Candidate admission and CBT test must resolve to the same tenant or approved admissions scope. | No rows to copy; include negative cross-tenant fixture tests. |
| `schoolpro_cbt_answers` | 2,800 | **Migrate filtered operational rows** | Answer → attempt → student/test; question must be valid for that test. All parent ownership must resolve to one school. | Reconcile counts by school/test; validate attempt/question consistency and denied cross-school reads/writes. |
| `schoolpro_cbt_attempts` | 280 | **Migrate filtered operational rows** | Student and test must belong to the same school; preserve attempt state and timing. | Verify all 280 parent pairs; enforce same-school rules in the target transaction path. |
| `schoolpro_cbt_test_questions` | 280 | **Migrate filtered operational rows** | Test and question must be compatible; where question bank is shared, retain explicit visibility/ownership classification rather than infer tenant from the child. | Reconcile by test; test unauthorized question attachment across schools. |
| `schoolpro_fee_items` | 504 | **Migrate filtered operational rows** | Fee item belongs to fee structure; fee structure determines school. | Verify every parent and reconcile counts/totals by allowlisted school; no orphan items. |
| `schoolpro_student_activation_challenges` | 0 | **Do not migrate challenge state** | Transient credential/security state is not business data. | Keep Supabase auth flow initially; expire/invalidate and reissue challenges at any future auth-boundary change. Never copy reusable challenge secrets. |
| `schoolpro_account_challenges` | 0 | **Do not migrate challenge state** | Transient account/initial-credential challenge; security telemetry and expiry must be preserved in the current auth boundary. | Do not copy secrets or active challenges; test rate-limit, one-time use, expiry, and replay denial if flow moves. |
| `schoolpro_plan_catalog` | 4 | **Platform configuration: seed by reviewed values** | Not tenant-owned. Treat as platform-wide commercial configuration. | Compare to current approved pricing and plan rules; no blind row copy from production. |
| `schoolpro_subscription_catalog` | 3 | **Platform configuration: reconcile then seed** | Not tenant-owned. Annual paid plans, demo activation/expiry, and grace rules must match current commercial contract. | Product owner must approve canonical values; test no paid amount shown during active demo and expiry/grace transitions. |
| `schoolpro_subscription_plans` | 3 | **Platform configuration: reconcile authority first** | Not tenant-owned; relationship to `schoolpro_subscription_catalog` is not yet proven authoritative. | Do not seed until duplicate/overlap semantics and foreign-key relationships are reconciled. |
| `schoolpro_login_attempts` | 2 | **Exclude historical rows; define retention separately** | Unscoped security telemetry, not tenant business records. Avoid transferring IP/device or other security metadata without an approved retention/privacy purpose. | Keep auth throttling in the current identity boundary; if moved, design privacy-safe retention and tenant-neutral abuse controls first. |

## Shared identity and payment boundaries

- **Supabase Auth and `public.profiles`:** keep as the initial identity provider/control plane. Do not bulk-copy users, passwords, sessions, refresh tokens, MFA factors, profile records, or transient challenges into the SchoolPro dataset. Preserve actor UUIDs only as external subject references where needed; trusted API validates the Supabase JWT and school-scoped authorization on each request.
- **`public.virtual_accounts`, `public.payment_transactions`, `schoolpro_payment_intents`:** keep shared payment/DataSub/BillStack processing outside the SchoolPro tenant export. Carry only the minimum approved payment correlation identifiers and status through an explicit idempotent adapter contract. Do not create a second authoritative payment ledger.
- **Email queue and private academic clock:** treat as shared service dependencies, not SchoolPro-owned data. Either keep them in Supabase behind a stable service boundary for the initial rehearsal or approve a separate transactional migration design; do not silently copy them.
- **Storage:** object keys/metadata are not proof of object ownership. Validate exact bucket, path prefix, parent record, tenant and caller authorization via the actual Storage API before migrating any objects.

## Closure criteria

The target disposition category is now assigned for all 18 tables. The overall ownership gate remains **open** until (1) the row allowlist is owner-approved, (2) the 27,440 submissions and 2,800 CBT answers/280 attempts reconcile by tenant, (3) target constraints and trusted-API authorization tests pass, (4) shared identity/payment boundaries are approved, and (5) operational catalog values are reviewed. No production data was copied and no target schema was changed by this register.
