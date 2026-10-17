# SchoolPro audit batch 8 — signature-aware live routine inventory and SECURITY DEFINER search_path triage — 2026-10-17

## Read-only method

Queried `pg_proc`/catalog metadata in production for all routines in `public` and `private` whose names begin `schoolpro_`. Each routine was keyed by schema plus `pg_get_function_identity_arguments` (signature), not just name. Definitions were hashed for a reproducible current-state baseline. No production objects were modified.

## Current signature baseline

| Measure | Result |
|---|---:|
| Current `schoolpro_*` routine signatures in public/private | 111 |
| Distinct schema-qualified routine names | 111 |
| Current same-name overload groups | 0 |
| SECURITY DEFINER routines | 82 |
| Routines with `search_path = ''` explicitly set | 108 |
| Effective anon EXECUTE | 8 |
| Effective authenticated EXECUTE | 89 |
| Effective service_role EXECUTE | 68 |

No same-name overload groups were returned by the current catalog query for SchoolPro-prefixed routines. This is useful for the current signature inventory only: it does not resolve the 236 earlier body/overload mismatch heuristic, which spans recovered migration declarations and potentially broader routine families. Historical overloads may have been dropped, renamed or replaced, so every recovered declaration still needs a migration timeline.

## Three current SchoolPro routines without an empty search_path

| Signature | SECURITY DEFINER | Effective ACL | Triage |
|---|---|---|---|
| `public.schoolpro_cbt_is_eligible(uuid,uuid)` | yes | authenticated, service_role; no anon | Sets `search_path=public`; unqualified table/type references exist. Review whether changing to empty path with fully qualified names is safe and covered by regression tests. |
| `public.schoolpro_return_library_loan(uuid)` | yes | authenticated, service_role; no anon | Sets `search_path=public`; unqualified tables and type references. Authorization checks platform admin or `schoolpro_member_can_manage(l.school_id)`, then locks and updates loan/book rows. Validate cross-school loan IDs, caller role, concurrency and search_path hardening. |
| `public.schoolpro_result_comment(numeric)` | no | anon, authenticated, service_role | Pure immutable text helper. Public execution is lower risk; it is not a SECURITY DEFINER entrypoint and does not access tenant rows. |

The two SECURITY DEFINER routines with `search_path=public` are not automatically exploitable from this observation alone. They do merit hardening review because they resolve unqualified objects under a writable/public search path. The candidate target should fully qualify table/type/function references and set a controlled empty search_path, with tests before any change.

## Current effective policy baseline refinement

Current catalog reports 293 policies over 101 distinct policy-bearing SchoolPro-prefixed tables; policy-name count is 269. Command counts are 120 SELECT, 31 INSERT, 26 UPDATE, 19 DELETE, and 97 ALL. The earlier 107-table inventory includes SchoolPro candidate tables without a current policy row; RLS status and table existence must be tracked independently from policy-bearing-table counts.

The complete per-table policy matrix must preserve each policy's roles, permissive/restrictive mode, command, USING expression and WITH CHECK expression, plus the combined effective expression. A policy's role array does not capture inherited grants by itself; current role-membership traversal found no inheritance edges from `anon`, `authenticated` or `service_role` in the inspected catalog. Effective `has_*_privilege` results and ownership/BYPASSRLS still need to be evaluated separately.

## Not completed by this batch

- The 236 heuristic historical body/overload differences are not fully reconciled.
- This current-state signature inventory is not a 397-version historical function/action matrix.
- No disposable adversarial test was run.
- The result-output bucket change is only a repository candidate patch, not deployed or accepted.
- Historical policy/ACL, trigger and cron transition completeness remains open.
