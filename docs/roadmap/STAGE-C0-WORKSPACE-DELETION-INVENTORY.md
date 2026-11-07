# Stage C0 — Workspace deletion and record lifecycle inventory

**Review date:** 2026-11-07  
**Branch:** `feat/schoolpro-stage-c0-workspace-corrections`  
**Status:** Read-only production schema inventory; implementation not yet approved or applied.

## Guardrails

- This review queried schema metadata and aggregate object counts only. It did not modify production schema, rows, Storage objects, Auth users, or profiles.
- Never delete global `profiles` or `auth.users`, reusable role/permission definitions, global/default templates, unrelated tenant data, DataSub/IHLink data, or required financial, legal, and audit evidence.
- A school owner may submit a deletion request; only an authorized IHLink platform reviewer may approve or reject it.
- Approval must not directly cascade-delete the school row. The executor must be server-side, tenant-scoped, idempotent, dependency-aware, audited, and capable of stopping safely when retained evidence or unresolved dependencies remain.
- Storage deletion must use the Storage API/object lifecycle, not direct SQL deletion from `storage.objects`; object removal must be limited to exact tenant-owned prefixes after ownership is established.
- Record-level lifecycle actions must distinguish reversible archive/deactivation from irreversible purge and retain historical records where they underpin transcripts, results, financial evidence, or legal obligations.

## Read-only production findings

The connected Supabase project currently contains **two SchoolPro school rows**, both marked active. A direct read-only query on 2026-11-07 returned:

| School | School ID | Created at (UTC) | Status |
|---|---|---|---|
| IHLINK Academy | `eb601205-cffd-420d-97d0-7d5ca081628a` | 2026-11-04 13:26:29 | active |
| HA ACADEMY | `ac7ac8a8-5035-4e39-8868-cad54add84a6` | 2026-11-05 13:37:52 | active |

These are different IDs from the two historical workspaces recorded as deleted on 2026-10-28. Their purpose and ownership are not established by this query. This inventory does not identify either current school as eligible for deletion and does not authorize deletion, archival, or other mutation of either one.

### Foreign keys referencing `schoolpro_schools`

The schema contains many direct tenant foreign keys with `ON DELETE CASCADE`, but the following direct references are not ordinary cascade-safe operational children and require explicit lifecycle treatment:

| Child table | FK delete action | Required handling |
|---|---|---|
| `ihlink_email_queue` | NO ACTION | Preserve shared queue/audit evidence; cancel or detach only a tenant-specific queued message through its supported lifecycle. |
| `schoolpro_custom_requests` | NO ACTION | Review request history and retention; do not silently cascade. |
| `schoolpro_demo_requests` | SET NULL | Preserve request history and allow school link to become null only when appropriate. |
| `schoolpro_document_issue_events` | RESTRICT | Retain issue/revocation audit evidence or create an approved retained snapshot before tenant purge. |
| `schoolpro_enrollment_history` | NO ACTION | Historical enrolment is academic evidence; archive/retain or explicitly snapshot before purge. |
| `schoolpro_onboarding_requests` | NO ACTION | Preserve onboarding history; detach only under a defined retention rule. |
| `schoolpro_result_events` | RESTRICT | Result event history is audit evidence; retain or snapshot before operational purge. |
| `schoolpro_transcript_issues` | NO ACTION | Issued transcript records are legal/academic evidence; retain or snapshot. |
| `schoolpro_transcript_settings` | NO ACTION | Archive settings or explicitly remove only after transcript evidence is preserved. |

The catalog also shows cross-table dependencies that do not necessarily carry `school_id` on the child row. The known example `schoolpro_candidate_cbt_answers.question_id -> schoolpro_question_bank.id` uses NO ACTION; deletion must account for dependent answers before deleting a question, without deleting reusable/default question-bank content.

### Financial and audit retention

A number of school-scoped tables currently have cascading school foreign keys, including subscription/payment records and school audit logs. A cascade is not, by itself, permission to erase them. Before implementing the executor, classify and explicitly preserve or snapshot at least:

- School subscription intents, subscription payments, upgrade requests, and transfer/payment proof references.
- School invoices, fee payments, payment allocations, and payment intents/proofs.
- Issued document/transcript evidence and their event history.
- School audit logs, while retaining platform-wide audit/security history.
- Any external/global payment ledger references (including the existing `payment_transactions` relationship that uses `ON DELETE SET NULL`).

The executor must not delete global payment ledger rows, bank-transfer evidence required by IHLink, or global profile/Auth records. The approved design should retain minimum immutable evidence (tenant identifier/name snapshot, amount/currency/reference, timestamps, decision actor, and linked external payment identifiers) for the applicable retention period before operational data is purged.

### Storage inventory

The production Storage catalog includes SchoolPro buckets for admissions, branding, demo documents, document outputs, document templates, invoice templates, payment receipts, and result outputs. Aggregate inventory found 95 objects in four SchoolPro buckets:

| Bucket | Objects observed |
|---|---:|
| `schoolpro-document-outputs` | 83 |
| `schoolpro-document-templates` | 9 |
| `schoolpro-invoice-templates` | 2 |
| `schoolpro-result-outputs` | 1 |

All 95 observed objects use a UUID as their first path segment. Some paths refer to a historical school row already recorded as removed in the handover; at least one other UUID prefix is not established by this aggregate review as a current school. Therefore, UUID-shaped prefixes alone are insufficient proof of ownership. Before deletion, map each object prefix to a known tenant or retained global/default asset using the relevant metadata/table references. Preserve all unclassified objects. Do not delete from `storage.objects` directly; use the supported Storage object deletion API after exact prefix/object ownership has been verified.

## Required implementation design

1. **Request lifecycle**
   - Owner or authorized school proprietor submits a request for their exact school, with a reason, explicit irreversible-action confirmation, and re-authentication/step-up check where supported.
   - Enforce one open request per school using a partial unique index and server-side locking.
   - Record immutable requester, school, reason, submission time, and a schema/versioned preflight summary.
   - Authorized active IHLink Super Admin reviewer may approve or reject with a mandatory decision note. The requester cannot approve their own request.
   - Revalidate school identity, owner authority, open-request state, retention blockers, and preflight snapshot at approval/execution time.
   - Separate approval from execution; provide an idempotent execution state with progress and safe retry after a failed step.

2. **Deletion executor**
   - Pin `search_path`, revoke default PUBLIC/anon execution, grant only required authenticated reviewer access, and check active platform role inside the RPC.
   - Lock the school row and deletion request; derive school ID only from the locked request, never from a client-supplied free-form scope.
   - Use an explicit, reviewed child-first table allowlist and exact `school_id = locked_school_id` predicates. Handle non-`school_id` children by joining through their parent IDs.
   - Stop before destructive work if an unknown FK, cross-tenant reference, retention record, or unclassified Storage object is discovered.
   - Preserve global profiles/Auth, role/permission catalogues, shared/default templates (`school_id IS NULL`), external payment ledger rows, and unrelated tenant data.
   - Keep an immutable deletion audit record outside the school-owned rows being purged; record reviewer, executor, timestamps, counts, retained-evidence references, and outcome.
   - Storage cleanup is a separate, retryable phase using supported Storage APIs and exact approved object lists/prefixes; never issue a bucket-wide delete.
   - Remove the school row only after the operational cleanup and retained-evidence checks pass. If retention policy requires the school identity row, mark it permanently closed/archived instead of deleting it.

3. **Owner-managed record lifecycle**
   - Build an explicit entity policy matrix for students, classes, teachers/staff/members, parents/guardians, and other school-owned records.
   - Prefer deactivate/archive for people and entities referenced by historical attendance, assessments/results, transcripts, finance, or audit evidence.
   - Use hard delete only for unreferenced draft records with no retained dependencies and only after a server-side dependency check.
   - Never delete the linked global profile/Auth user as a side effect of removing a school membership.
   - Log each archive/deactivate/purge action with actor, tenant, entity type/id, reason, timestamp, and before/after state where appropriate.

4. **Acceptance tests**
   - Owner can submit only for their own school; unrelated school owner cannot read or submit another tenant's request.
   - Inactive accounts, unauthorized members, and non-platform reviewers cannot approve/execute.
   - Request duplication, self-approval, stale preflight, repeated execution, and concurrent execution are rejected or idempotently handled.
   - Test all direct NO ACTION/RESTRICT dependencies and non-`school_id` children.
   - Prove global/default templates, role/permission definitions, profiles/Auth, DataSub/IHLink rows, external payment ledger rows, and unrelated tenant data survive.
   - Prove every selected Storage object is tenant-owned; unclassified and shared objects survive.
   - Test retention snapshots and failure/retry at each execution phase.

## Current disposition

No deletion lifecycle migration or production data change has been made. The schema inventory identifies the principal retention and dependency hazards, but implementation still requires a complete FK/table classification, exact Storage reference mapping, and a disposable PostgreSQL regression fixture. Do not apply a migration or delete any live workspace as part of this review.
