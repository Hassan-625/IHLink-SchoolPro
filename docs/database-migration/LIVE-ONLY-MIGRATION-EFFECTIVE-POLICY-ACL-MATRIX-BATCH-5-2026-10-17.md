# Live-only 397-version audit — effective policy and ACL baseline, batch 5 — 2026-10-17

## Scope and safety

This is a read-only continuation of the 397 recovered live-only migration-version audit. Queries inspected the current production catalog and the applied migration ledger only. No migration SQL was replayed; no production object, grant, policy, data, Storage object, function deployment, or hosting configuration was changed. No merge or cutover was authorized.

This report establishes a reproducible *current effective-state baseline* and ties it to the version-level review already in progress. It is not falsely labeled as a complete semantic comparison of all 397 historical payloads: historical ACL/policy statements must still be reconciled with later statements, role inheritance, schema USAGE, object ownership, default privileges, and catalog-effective state.

## Current SchoolPro RLS baseline

Read-only production catalog counts:

| Measure | Result | Interpretation |
|---|---:|---|
| SchoolPro candidate tables | 107 | Prefix-scoped public tables and partitions considered |
| Tables with RLS enabled | 107 | All identified SchoolPro tables have RLS enabled |
| Tables with FORCE ROW LEVEL SECURITY | 0 | Table owners/bypass-capable roles remain a separate boundary; RLS enablement is not a complete authorization proof |
| Current SchoolPro policies | 293 | Current policy objects, not 293 historical policy declarations |
| Permissive policies | 243 | Permissive policies combine by OR within applicable command/role scope |
| Restrictive policies | 50 | Restrictive policies combine as an additional AND gate |
| SELECT / INSERT / UPDATE / DELETE / ALL | 120 / 31 / 26 / 19 / 97 | Command counts; ALL overlaps the operational command semantics |
| Policies targeting anon | 7 | Role target count only; does not prove the policy is reachable or permissive |
| Policies targeting authenticated | 290 | Role target count only; policy predicates still determine row authorization |

A current policy review must evaluate the *combined* permissive and restrictive expressions per table/command, not read each policy independently. For child tables without a direct school key, the policy may derive school ownership through a parent row; that join and every relevant parent key must be tested for cross-tenant consistency.

## Current effective routine ACL baseline

Production catalog query used `has_function_privilege(role, oid, 'EXECUTE')`, which incorporates effective privileges rather than only textual ACL entries.

| Schema | Routines | SECURITY DEFINER | Effective anon EXECUTE | Effective authenticated EXECUTE | Effective service_role EXECUTE |
|---|---:|---:|---:|---:|---:|
| public | 234 | 189 | 11 | 187 | 234 |
| private | 135 | 113 | 29 | 80 | 41 |
| Total | 369 | 302 | 40 | 267 | 275 |

Important interpretation:
- The 29 private-schema functions with effective anon EXECUTE are not equivalent to 29 callable PostgREST endpoints: anon has no USAGE on the private schema in the previously recorded schema-privilege check. Preserve both function ACL and schema reachability in the target matrix.
- The 11 public-schema anon-executable routines include six SchoolPro admission/result/document endpoints, three candidate-CBT bearer-token endpoints, plus a pure result-comment helper and a trigger helper. The helper/trigger routines are not equivalent to ordinary exposed business RPCs, but must be evaluated with trigger wiring and object exposure.
- 302 SECURITY DEFINER routines require review of caller checks, owner, fixed/empty search_path, dynamic SQL, and reachable entry points. SECURITY DEFINER status alone is not proof of a defect, nor is an authenticated grant alone proof of safe tenant authorization.
- A prior targeted ACL review found that the live `schoolpro_transfer_ownership(uuid,uuid)` has authenticated and service_role execution but denies anon, whereas the historical migration explicitly granted authenticated and revoked PUBLIC/anon. The extra service_role grant must be sourced/versioned before target ACL design.

## Version-level matrix rules for all 397 payloads

Each historical version must receive one row per affected object/action, not one coarse status per version. Minimum fields:

1. Migration version and name; exact recovered payload identifier/hash.
2. Object type, schema, object name, and routine identity arguments (for overloads).
3. Historical action: CREATE/OR REPLACE/ALTER/DROP policy, function, trigger, GRANT, REVOKE, default privilege, schema grant, or cron transition.
4. Historical body/expression/grant as authored.
5. Later superseding version(s), if any, with explicit transition evidence.
6. Current live definition/effective state: routine body and SECURITY DEFINER/owner/search_path; policy roles, command, permissive mode, USING and WITH CHECK; table/sequence/schema ACL; effective privilege checks for anon/authenticated/service_role; trigger event/condition/function wiring; cron schedule/command/active status.
7. Semantic disposition: exact; formatting-only; evolved/superseded; intentionally dropped; absent/unresolved; parser false-positive; or requires execution test.
8. Tenant/role abuse tests required and evidence link.
9. Target disposition: reproduce, redesign behind trusted API, omit retired object, or unresolved/blocked. No target disposition authorizes production replay.

The current-state query is intentionally catalog based. Historical SQL substring matches are not considered semantic equality, and policy-name/table-name matches are not accepted as expression equality.

## Resolved and still-open function-body cases

- The five previously missing routine names are resolved to explicit later DROP migrations (see semantic triage batch 2); do not resurrect them.
- `public.schoolpro_transfer_ownership(uuid,uuid)` is resolved as an evolved definition: live UPSERT behavior is grounded in later successor migration `20261013184713`; the additional service_role grant still needs provenance/authorization disposition.
- `private.schoolpro_module_allowed(uuid,text)` is grounded in later plan-access implementation `20261008152205`, not the older implementation with a final `ELSE true`. It remains a module/plan check and cannot substitute for table-level tenant predicates.
- `submit_schoolpro_payment` body matches its recovered declaration but has a latent trust-boundary defect: caller-supplied receipt path/MIME are not checked against actual Storage bucket/object ownership or metadata. No production rows were present in the prior count; target must not preserve this behavior without trusted object validation.
- Class-result submission policy ambiguity is resolved by `20261013130652` explicit outer-table qualification; the related RPC's anon/PUBLIC revoke is grounded in `20261013130436`. Cross-school and role/period adversarial execution tests remain outstanding.
- The initial 236 body/overload mismatch signal remains a heuristic backlog, not a count of 236 proven defects. Each must be reconciled by identity signature and latest applicable migration; do not claim all resolved from name/body substring evidence.

## Acceptance gates still open

1. Finish signature-aware disposition for every one of the 236 function declarations flagged by the first parser, including explicit later ALTER/CREATE/DROP successors and effective ACL changes.
2. Produce the full 397-version policy/ACL object-action matrix, including DROP/RENAME/dynamic policy cases, role membership/default ACLs and schema reachability.
3. Confirm all current SchoolPro policy combinations against the 107-table inventory; do not equate “RLS enabled” with tenant isolation.
4. Continue trigger-function wiring and cron transition reconciliation; preserve the unresolved provenance for `datasub-provider-health-5m`.
5. Run disposable adversarial role/tenant tests for result PIN/code verification, public admissions/document endpoints, candidate CBT token lifecycle, receipt Storage ownership, class-result submission/publication and signed result-output access.
6. Keep source-to-live Edge Function parity and the result-output bucket mismatch as blockers until resolved and tested.
7. No export/import, Aiven write, migration replay, production DDL/grant/policy changes, Render deployment, merge, or cutover without separate explicit authorization.

## Evidence source

Live Supabase project `lnqsroyiybutkfngbyge`; migration ledger baseline of 476 applied versions, of which 397 are the recovered live-only set. Earlier evidence documents in this directory include the 397-version semantic triage batches 1–4, anonymous entry-point ACL review, cron review, 79-FK review, row-ownership register, and Edge Function parity report.
