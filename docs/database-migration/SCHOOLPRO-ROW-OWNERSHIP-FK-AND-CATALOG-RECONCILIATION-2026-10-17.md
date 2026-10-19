# SchoolPro ownership and live-catalog reconciliation — 2026-10-17

## Scope and safety

Read-only queries against live Supabase project `lnqsroyiybutkfngbyge`. No production writes, export/import, migration replay, Aiven writes, Render changes, merge, or cutover occurred. Supabase remains the production source of truth. This report adds current live row evidence to the existing 107-table ownership register; it does not replace the full register.

## 18 tables without a direct `school_id`: current live counts and disposition

Exact counts queried with `count(*)` on 2026-10-17 (not planner estimates):

| Table | Live rows | Disposition |
|---|---:|---|
| `schoolpro_schools` | 2 | Tenant roots; retain only explicitly allowlisted school UUIDs and approved owner references. |
| `schoolpro_admission_acceptances` | 0 | Admission child; inherit tenant through admission and offer, require same-school pair. |
| `schoolpro_admission_documents` | 0 | Admission child; validate parent and object ownership; file payloads not included by default. |
| `schoolpro_admission_events` | 4 | Admission child/audit history; retain only if parent and retention checks pass. |
| `schoolpro_admission_offers` | 0 | Admission child; inherit through application. |
| `schoolpro_assignment_submissions` | 27,440 | Inherit tenant only when assignment and student have same school. |
| `schoolpro_candidate_cbt_answers` | 0 | Candidate attempt/question child; currently no rows. |
| `schoolpro_candidate_cbt_attempts` | 0 | Admission/test child; currently no rows. |
| `schoolpro_cbt_answers` | 2,800 | Inherit tenant through attempt/student/test; validate question belongs to same school/test scope. |
| `schoolpro_cbt_attempts` | 280 | Require student and test to belong to the same school. |
| `schoolpro_cbt_test_questions` | 280 | Require test/question scope compatibility. |
| `schoolpro_fee_items` | 504 | Inherit tenant through fee structure. |
| `schoolpro_student_activation_challenges` | 0 | Transient credential challenges; do not migrate reusable secrets; invalidate/reissue at cutover if needed. |
| `schoolpro_account_challenges` | 0 | Transient account challenges; do not migrate reusable secrets. |
| `schoolpro_plan_catalog` | 4 | Platform-wide configuration; do not copy blindly as tenant data. |
| `schoolpro_subscription_catalog` | 3 | Platform-wide configuration; compare against current annual/demo/grace business rules. |
| `schoolpro_subscription_plans` | 3 | Platform-wide configuration; determine authoritative relationship to subscription_catalog before target seed. |
| `schoolpro_login_attempts` | 2 | Unscoped security telemetry; exclude historical rows by default and apply retention/privacy policy. |

### Read-only integrity results

The following anti-join checks were executed against live data. Orphan count was zero for each checked relationship:

| Relationship | Rows checked | Orphans |
|---|---:|---:|
| admission offers → admissions | 0 | 0 |
| admission events → admissions | 4 | 0 |
| admission documents → admissions | 0 | 0 |
| admission acceptances → admissions | 0 | 0 |
| admission acceptances → offers | 0 | 0 |
| assignment submissions → assignments | 27,440 | 0 |
| assignment submissions → students | 27,440 | 0 |
| candidate attempts → admissions | 0 | 0 |
| candidate attempts → CBT tests | 0 | 0 |
| candidate answers → candidate attempts | 0 | 0 |
| candidate answers → question bank | 0 | 0 |
| CBT attempts → tests | 280 | 0 |
| CBT attempts → students | 280 | 0 |
| CBT answers → attempts | 2,800 | 0 |
| CBT answers → question bank | 2,800 | 0 |
| CBT test questions → tests | 280 | 0 |
| CBT test questions → question bank | 280 | 0 |
| fee items → fee structures | 504 | 0 |
| student activation challenges → students | 0 | 0 |
| account challenges → initial credentials | 0 | 0 |

Additional same-school pair checks returned zero mismatches for:
- assignment submission assignment/student;
- CBT attempt test/student;
- CBT test/question;
- candidate attempt admission/test;
- candidate answer question vs admission-derived tenant.

**Limit:** this proves only the listed live rows/joins at query time. It does not prove every foreign key, trigger, RLS policy, RPC, Storage object, or write path is tenant-safe. Parent-table scoping for questions and test compatibility should also be validated against the actual application/RPC rules.

## Cross-boundary foreign keys: disposition review

The existing register records 79 foreign keys crossing the public SchoolPro table boundary. A fresh live-catalog query also exposed relationships outside that exact counting scope (including `private.schoolpro_academic_clock`, `ihlink_email_queue`, and `payment_transactions`); these must not be silently added to or subtracted from the canonical 79 count. Reconcile counts by the original scope definition before calling the inventory complete.

Classification and target disposition:

1. **Identity references (`auth.users`, `public.profiles`)** — actor, reviewer, owner, member, guardian, student-login, and creator references. Keep Supabase Auth as the initial identity provider; do not export auth users, passwords, sessions, refresh tokens, MFA, or challenge secrets. For school-owned rows preserve stable user UUID references only where the target identity bridge explicitly supports them. `profiles` is shared platform data and must not be bulk-copied as SchoolPro-owned data.
2. **Shared virtual-account/payment references (`public.virtual_accounts`, `public.payment_transactions`)** — external integration boundary. Do not move the shared DataSub/BillStack ledger into the SchoolPro tenant dataset. Preserve payment correlation IDs and a separately approved adapter/ledger contract; reconcile webhook idempotency and status transitions before cutover.
3. **Email queue and academic clock integration (`public.ihlink_email_queue`, `private.schoolpro_academic_clock`)** — shared asynchronous/platform or private-schema dependencies. These are not ordinary SchoolPro tenant tables; map ownership and service execution explicitly rather than copying based on table prefix.
4. **SchoolPro child-to-identity FKs** — keep actor IDs as external identity references, enforce that the actor is authorized for the row's school in application/RPC policy, and test negative cross-school access. A valid FK to a global user/profile is not tenant authorization.
5. **School root owner FK** — `schoolpro_schools.owner_id → profiles.id` is a root ownership reference; validate every allowlisted school’s owner and role semantics separately.

### Foreign-key target inventory observed in live catalog

- `auth.users`: identity/actor references; external identity, no bulk copy.
- `public.profiles`: shared profile references; no bulk copy.
- `public.virtual_accounts`: shared payments integration; no bulk copy.
- `public.schoolpro_schools`: tenant root referenced by private academic clock/email queue integration.
- `public.schoolpro_payment_intents`: referenced by shared payment transaction integration.
- Other cross-boundary integration objects must be enumerated under the exact original public-to-public scope and matched to the 79-entry register before closure.

**Still required to close the 79-FK review:** compare all 79 names/column pairs against the source register, identify every FK's target disposition, check null/orphan cardinality where nullable semantics require it, check actor authorization by school, and design target-safe constraints/adapters. No target DDL is approved by this report.

## Recovered live-only SQL vs live catalog

The existing provenance work remains the source of record: 397 live-only migration versions have recovered SQL payloads in eight JSONL bundles; all bundle records parse and have one statement-array entry each. The 35 versions referenced by the historical “33-version batch” marker have individual SQL files that byte-match their ledger payloads. The independent deployment API/audit evidence remains unavailable, and the ledger lacks deployment timestamps/idempotency keys.

**Semantic catalog comparison is not yet complete.** A byte match between a recovered file and ledger payload proves provenance consistency between those two representations, not that every DDL effect is currently present or equivalent in the live catalog. Required next pass:
- parse each recovered statement into object-level targets (tables/columns, constraints/indexes, functions/signatures, triggers, policies, grants, views/types/extensions);
- compare the expected object definition to `pg_catalog` / `information_schema` live definitions, not just object existence;
- classify each version as exact match, partially present, superseded/renamed, absent, non-DDL/no-op, or unresolved;
- inspect ordering/dependencies and replacement definitions before any replay recommendation;
- keep all 44 branch-only version dispositions separate; source filenames and object-name coincidences are not proof of application.

No SQL was replayed. No schema was changed.

## Application call-site mapping — status

The companion `APPLICATION-DYNAMIC-CALLSITE-REVIEW-2026-10-17.md` remains the current map: 463 static scan records across 190 files, not a complete AST/runtime graph. Known dynamic table/RPC maps and fixed Edge Function names are documented there. Remaining mapping work:
- resolve every caller and actual bucket value passed to `DocumentDesign` / `DesignAssets` / `useDesignImages`;
- scan the actual live Render commit `29856dff17ea8a3bc8bb31b7900967b7df9d316b` and compare it with this migration branch;
- complete wrapper/alias/multiline/dynamic call tracing;
- map each Edge Function to “retain in Supabase”, “move behind the new trusted API”, or “retire”, including JWT/signature checks, tenant binding, payment/email idempotency, and Storage object authorization.

## Gate status

**Row ownership: partially evidenced, not signed off.** The 18-table disposition is documented and the targeted non-empty parent checks above are clean; unscoped catalog/security tables and all remaining FK/RLS/Storage paths still require decisions.

**Schema reconciliation: open.** Recovered SQL bundles and provenance consistency are established, but version-by-version semantic live-catalog comparison is not complete.

**Application mapping: open.** The manifest is useful but not exhaustive; bucket callers and production-commit parity remain.

**Migration/cutover: blocked.** No export/import, replay, production configuration change, Render deployment, merge, or cutover.
