# Live effective function ACL reconciliation — anonymous entry points — 2026-10-17

## Scope

Read-only catalog review of effective EXECUTE privilege on public/private routines, including `SECURITY DEFINER`, ACL and schema USAGE. This is a privilege snapshot, not a complete per-version GRANT/REVOKE diff. No ACLs were changed.

## Current public-schema functions executable by anon

There are 11 public-schema routines for which `has_function_privilege('anon', ...,'EXECUTE')` is true:

| Routine | SECURITY DEFINER | Classification / required review |
|---|---:|---|
| `accept_schoolpro_admission_offer(uuid,text,text,text)` | yes | Public bearer-token write. Review token entropy/expiry, rate limits, idempotency and replay. |
| `check_schoolpro_result_pin(text,text,text,text)` | yes | Public result PIN checker. No in-body failed-attempt throttle found; direct RPC can bypass frontend throttles. High priority. |
| `get_schoolpro_admission_offer(uuid)` | yes | Public bearer-token read. Review token entropy/expiry, field minimization and enumeration resistance. |
| `schoolpro_verify_result_code(text)` | yes | Public verification by code; returned snapshot/output needs minimization and enumeration controls. |
| `submit_schoolpro_application(uuid,text,text,text,date,text,text,text,text,text)` | yes | Public admissions intake. Review spam controls, duplicate handling and per-school abuse limits. |
| `verify_schoolpro_document(text)` | yes | Public serial lookup; review serial entropy, field minimization and enumeration controls. |
| `get_candidate_cbt(uuid)` | yes | Public bearer-token examination access. Token is checked against a candidate attempt; function enforces attempt status/expiry, published test and timing, and serializes start/update with row lock. Review token generation entropy, request throttling and token leakage/replay. |
| `save_candidate_cbt_answer(uuid,uuid,text)` | yes | Public bearer-token answer write. Validates in-progress attempt, deadline and question membership; review token abuse and answer payload bounds. |
| `submit_candidate_cbt(uuid)` | yes | Public bearer-token submission. Validates active attempt/deadline and scores objective answers; already-submitted attempt returns prior score. Review token abuse, concurrency and idempotency tests. |
| `schoolpro_result_comment(numeric)` | no | Pure result-comment helper; inspect its inputs/output and keep it free of sensitive lookup or mutation. |
| `enforce_schoolpro_result_lock()` | no | Trigger function; anonymous EXECUTE ACL does not itself make a trigger function callable as an ordinary RPC. Keep this distinct from callable endpoint exposure. |

The six SchoolPro admission/result/document routines above are confirmed anonymous-executable SECURITY DEFINER endpoints. The three candidate-CBT routines are also SECURITY DEFINER and anonymous-executable, but function bodies use a bearer UUID in `schoolpro_candidate_cbt_attempts.access_token` and check test/attempt state. This appears to be an intentional public examination-link capability; it is not an authorization failure solely because the function is public. Security depends on high-entropy tokens, expiry, no token leakage, concurrency safety and abuse resistance, all of which require dedicated tests.

## Private-schema ACL qualifier

The catalog reports 29 routines in schema `private` with effective anon EXECUTE, including trigger/helper functions that retain default ACLs. However, `has_schema_privilege('anon','private','USAGE')` is false. They are therefore not ordinarily directly addressable by an anon PostgREST caller through that schema. This does **not** justify copying permissive default function ACLs to the target; clean up unnecessary privileges and preserve trusted trigger execution, while verifying security-definer callers and trigger wiring.

## Current snapshot counts

- `public`: 234 routines; 189 SECURITY DEFINER; 11 anon-executable routines.
- `private`: 135 routines; 113 SECURITY DEFINER; 29 routines report anon EXECUTE at function ACL level, but anon lacks `private` schema USAGE.
- `service_role` privilege counts are not interpreted as an exposure metric here; its elevated role semantics mean they must be reconciled against the target's trusted service boundary rather than copied blindly.

These are catalog totals for the whole live project, not SchoolPro-only object counts. The migration covers shared DataSub, Academy, payment, email, document and other product schemas too.

## Required per-version ACL work

1. For every recovered GRANT/REVOKE, identify exact object signature (including overload), role, grant option, owner and effective ACL after subsequent migrations.
2. Include schema USAGE, default privileges, table/sequence ACLs and policies; do not infer endpoint reachability from function ACL alone.
3. Preserve only intentional public bearer-token endpoints, with high-entropy token generation, expiry, response minimization, rate limiting at a trusted boundary and tests for parallel/replayed calls.
4. Keep internal trigger helpers non-publicly callable by design; validate actual trigger wiring and avoid accidental direct endpoint exposure.
5. Repeat this inventory against the target trusted API design; the target must not expose PostgreSQL service credentials or make direct client connections.

No production grants or functions were changed. This snapshot advances the effective ACL baseline but does not close the 397-version ACL audit.
