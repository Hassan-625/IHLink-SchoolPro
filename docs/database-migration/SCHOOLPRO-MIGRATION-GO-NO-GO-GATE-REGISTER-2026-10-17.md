# SchoolPro migration go/no-go gate register — 2026-10-17

## Decision

**NO-GO: migration rehearsal, production export/import, and cutover are not yet authorized.** This register is an execution control, not a claim that outstanding work passed. Source Supabase production remains read-only. No production DDL/DML, grants/policies, Storage object/bucket mutation, Edge deployment, Render configuration/deploy, merge, export/import, or cutover was performed for this checkpoint.

## Gate register

| Gate | Required evidence | Current status | Exit condition |
|---|---|---|---|
| G1 — Tenant isolation and role boundaries | Disposable synthetic school A/B tests through actual RPC/API/Storage paths; positive and negative cases; role matrix; test logs and SQL/API evidence | **BLOCKED — NOT RUN end-to-end**. Limited source-side read-only RLS SELECT checks passed for selected root/student/result/invoice and selected child rows, but no write tests and no receipt/admissions/CBT/signed-URL adversarial suite. | All cross-school and wrong-role attempts are denied; intended same-school actions succeed; no secrets or result snapshots leak; replay/rate-limit/concurrency cases pass. |
| G2 — Source completeness and provenance | Version-by-version disposition for 397 live-only versions; independent deployment evidence for 35 marker versions; exact routine identity/body/successor/drop comparison; effective policy/ACL/default ACL; trigger and cron transition diff | **OPEN**. 397 payloads recovered; 35 payloads byte-match ledger but independent deployment audit evidence missing; 236 routine mismatches remain heuristic candidates, not proven defects; historical policy/ACL and trigger transitions incomplete; datasub-provider-health-5m provenance unresolved. | Every relevant object/action is exact, intentionally superseded/dropped, or has an approved disposition; no unresolved security-significant difference is silently carried forward. |
| G3 — Destination correctness (Aiven PostgreSQL) | Approved PostgreSQL target DDL; extension/role/grant/RLS/function/trigger/sequence/job mappings; explicit Supabase Auth/Storage/Edge integration boundary; seed policy; repeatable integrity and workflow tests | **NOT PROVEN**. Repository evidence reviewed so far does not establish a complete runnable Aiven PostgreSQL target, full schema parity, or passing destination integration/regression suite. | Aiven PostgreSQL target can be provisioned from versioned artifacts and pass schema, data-integrity, role, workflow, performance and regression checks with recorded evidence. |
| G4 — Isolated rehearsal and recovery | Isolated environment; source snapshot with approved handling; full rehearsal; counts/checksums/business totals; recovery backup and restore test; rollback triggers; owner approval | **BLOCKED**. Only listed Supabase branch is main with status MIGRATIONS_FAILED; a new branch requires organization selection and explicit cost approval if charged. No full rehearsal or recovery test has passed. | Full rehearsal and reconciliation pass; restore/rollback demonstrated; exceptions signed off; separately approved production runbook and window exist. |

## Security cases that must be represented in the synthetic test suite

- Result PIN/code: invalid, revoked, repeated, enumerated, throttled, cross-school, snapshot field minimization.
- Admissions: foreign-school offer IDs, forged/replayed tokens, guardian mismatch, unauthorized acceptance and repeated submission.
- CBT: invalid/expired/foreign candidate token, attempt/question mismatch, replay, deadline boundary, concurrent submit/save, token leakage and rate limits.
- School fee receipts: wrong bucket, wrong tenant path, traversal/forged path, nonexistent object, forged MIME, upload-delete/replacement race, unauthorized receipt access.
- Results: wrong school/class/period, unauthorized teacher/coordinator, direct anonymous submission/publication, held/unpublished result, repeat/concurrent submit and publish.
- Generated files: owner vs unrelated school, student/guardian/staff eligibility, template-vs-output bucket mismatch, signed URL creation/download/expiry/revocation and forged path.
- Role matrix: anon, student, guardian, teacher, form master/coordinator, exam officer, school owner/director/proprietor, platform super admin, and service role, limited to each role's intended scope.

Tests must use synthetic tenant A/B records and separate credentials. Do not send adversarial payloads against production.

## Source-completeness method

For each of the 397 versions, record: version, source payload checksum, parsed object/action, exact schema + identity arguments where applicable, live definition, successor/drop migrations, effective privileges, ownership/search_path/SECURITY DEFINER, policy predicate, trigger/function wiring, cron command/schedule, dependencies, semantic disposition, test evidence, reviewer and unresolved risk. Do not replay recovered historical SQL to make live state resemble old state.

The 35 marker versions are payload-verified against the ledger, but payload equality does not reconstruct the original deployment actor/time/request/result evidence. Record that provenance limitation rather than inventing it.

## Destination and rehearsal controls

- Treat Supabase Auth, Storage, Edge Functions, shared payment/profile/virtual-account links, email queues and academic-clock jobs as explicit cross-system boundaries; do not fabricate physical MySQL foreign keys to services that remain external.
- Preserve source data; do not copy demo/seed operational records into new customer workspaces.
- Use deterministic row counts, key coverage, checksums where stable, FK/orphan checks, tenant ownership aggregates, and academic/payment totals.
- Validate idempotency, interrupted-run recovery, duplicate handling, and source-to-target reconciliation.
- Rehearse backup restoration and rollback before any production cutover.
- Keep migration approval separate from code CI success, source recovery, or a candidate patch.

## Immediate dependencies

1. Establish a safe disposable test environment. The current Supabase branch inventory has only main, marked MIGRATIONS_FAILED. A new branch may incur hourly compute cost; obtain the Supabase organization ID, retrieve the actual quoted cost, and obtain explicit user agreement before confirming/creating it.
2. In parallel, continue the no-production-write semantic matrix and build/verify the Aiven PostgreSQL target inventory. Do not mark a gate passed from a plan, static inspection, CI status unrelated to the gate, or source-side SELECT-only test.
3. Update this register and the master handover with evidence links and exact outcomes after each batch.

## Approval rule

No migration/cutover approval until G1–G4 are all **PASS** with attached reproducible evidence and explicit owner sign-off. A single critical unresolved tenant, data-integrity, provenance, target-compatibility, or recovery defect keeps the decision **NO-GO**.

## Architecture correction
The authoritative project handover sets the active target as **Supabase PostgreSQL → Aiven PostgreSQL**, with the existing SchoolPro frontend remaining on Render. The MySQL pilot/PR #107 is paused historical reference only and must not be continued as the active target. Aiven target correctness includes PostgreSQL extensions, roles/grants/RLS, routines, triggers, sequences and Supabase-managed service boundaries; a database-only restore does not replace Auth, Storage, Edge Functions, Realtime, jobs or secrets. No Aiven target is yet proven ready and no live source export/import or Render configuration change occurred.
