# SchoolPro tenant authorization regression evidence — live read-only — 2026-10-17

## Scope and safety

This test is separate from the foreign-key validation review. It exercised live Supabase row-level security by running **read-only transactions** as database role `authenticated`, setting the request JWT subject/claims to an existing school-scoped proprietor identity, selecting specific rows, and rolling back. No production rows were written or changed. User IDs and individual record IDs are intentionally omitted from this report.

These results apply to the current Supabase source system only. They do not prove equivalent Aiven authorization; the future trusted API and target schema still require their own adversarial tests.

## Two-school SELECT results

### School-root and direct-school tables

| Identity | Object | Own-school rows visible | Other-school rows visible | Result |
|---|---|---:|---:|---|
| HASSAN ACADEMY proprietor | `schoolpro_schools` | 1 | 0 | Pass |
| HASSAN ACADEMY proprietor | `schoolpro_students` | 2 | 0 | Pass |
| HASSAN ACADEMY proprietor | `schoolpro_results` | 0 | 0 | Foreign-school result rows not visible; own school has no result rows in this query. |
| HASSAN ACADEMY proprietor | `schoolpro_invoices` | 0 | 0 | Foreign-school invoice rows not visible; own school has no invoice rows in this query. |
| IH Academy proprietor | `schoolpro_schools` | 1 | 0 | Pass |
| IH Academy proprietor | `schoolpro_students` | 1,212 | 0 | Pass |
| IH Academy proprietor | `schoolpro_results` | 34,803 | 0 | Pass |
| IH Academy proprietor | `schoolpro_invoices` | 3,362 | 0 | Pass |

### Child tables without direct `school_id`

A specific live row belonging to IH Academy was queried under both authenticated identities:

| Child object | IH Academy proprietor sees row | HASSAN ACADEMY proprietor sees row | Result |
|---|---:|---:|---|
| `schoolpro_assignment_submissions` | 1 | 0 | Pass for this sample |
| `schoolpro_cbt_attempts` | 1 | 0 | Pass for this sample |
| `schoolpro_cbt_answers` | 1 | 0 | Pass for this sample |
| `schoolpro_fee_items` | 1 | 0 | Pass for this sample |

These are **targeted sample-row authorization checks**, not a proof that all rows and all write paths are safe. The assignment-submission parent join confirmed 27,440 rows across 1,120 students and 896 assignments for IH Academy, with no assignment submissions in the HASSAN ACADEMY workspace at the snapshot. The per-row test was used to avoid scanning the entire child table under expensive RLS expressions.

## Performance signal

A broad cross-table aggregate over assignment submissions, CBT attempts/answers and fee items timed out while evaluating RLS, with the error context naming `is_admin` and `schoolpro_can_read_student`. The same task's targeted per-row authorization checks completed. This is not evidence of a cross-tenant disclosure, but it is a **performance/review item**: avoid full-table RLS joins during production operations, and inspect query plans/indexes and the cost of nested security helper functions before designing bulk migration verification.

## What this does and does not prove

**Proved in this read-only run:** the two tested proprietor identities could read their own school root/data where present and could not read the sampled foreign-school rows in the tested tables. The RLS context was applied as role `authenticated`, not merely inferred from FK validity.

**Not proved:** cross-school INSERT/UPDATE/DELETE denial; school reassignment attempts; arbitrary RPC abuse; teacher/guardian/student role restrictions; super-admin scoping; Storage object access, signed-URL issuance/download/expiry; every row in the 107-table candidate inventory; or Aiven/trusted-API tenant isolation.

## Required next authorization suite

- Expand to role matrix: school owner, exam officer, assigned teacher, unassigned teacher, guardian, student, and platform super-admin.
- Test SELECT/INSERT/UPDATE/DELETE and school/parent/actor reassignment attempts for high-risk result, payment, subscription, admission, document, assignment and CBT paths.
- Run sample and count-based tests for every one of the 18 no-direct-`school_id` tables; where full scans time out, use indexed parent IDs and bounded ranges, and record timeout/performance evidence.
- Exercise Storage API with real authenticated sessions and both expected/unexpected buckets/paths.
- Repeat the suite against the Aiven trusted API and target constraints before cutover.

## Status

**Partial live tenant-authorization evidence recorded; not tenant-isolation sign-off.** No DDL, grants, production configuration, data, or Edge Function changed.
