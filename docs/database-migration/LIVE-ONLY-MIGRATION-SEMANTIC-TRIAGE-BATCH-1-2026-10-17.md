# Live-only SQL semantic comparison — catalog triage batch 1 — 2026-10-17

## Scope and safety

Read-only query against the live Supabase migration ledger and catalog. The 397 version list was sourced from `LIVE-ONLY-MIGRATION-SQL-DEPENDENCY-REVIEW-2026-10-17.md`; each version was joined to `supabase_migrations.schema_migrations`. No migration was replayed and no production object was changed.

This is a **triage baseline**, not completion of the requested 397-version semantic audit. Name matching and body-substring checks are deliberately not counted as semantic passes.

## Whole-batch triage counts

The ledger query covered all 397 recovered live-only versions and found:

| Signal | Count | Interpretation |
|---|---:|---|
| Versions containing function DDL | 240 | Version count; multiple function declarations may occur in one version. |
| Extracted function declarations | 504 | Names parsed from SQL, not unique signatures. |
| Function names with at least one current catalog overload | 499 | Name-level existence only. |
| Declarations whose current `prosrc` occurs as a substring in that version's SQL | 263 | Heuristic only; not signature-aware or semantic proof. |
| Declarations with a live overload but no body-substring match | 236 | Requires overload/signature and later-definition analysis; may be superseded, altered or a parser false negative. |
| Function declarations with no current routine of that name | 5 | Requires explicit later-drop/rename or unresolved classification. |
| Parsed `CREATE POLICY` declarations | 144 | Dynamic SQL policy generation is not reliably parsed by the simple expression. |
| Parsed policies whose name/table exist now | 107 | Name/table presence only; policy expressions, roles and permissive/restrictive mode not compared by this count. |
| Parsed policies absent by name/table | 33 | Not proof of absence: dynamic `format('%I', ...)` SQL and quoted/complex identifiers produce parser false positives; later drops/renames also possible. |
| Parsed `CREATE TRIGGER` declarations | 43 | Static trigger parser only. |
| Parsed triggers whose name exists now | 42 | Name presence only; trigger definition/function wiring not compared by this count. |
| Parsed triggers absent by name | 1 | Requires historical transition classification. |
| Versions containing GRANT/REVOKE | 256 | Effective ACL comparison still required. |
| Versions containing `cron.schedule`/`cron.unschedule` | 5 | Job name, schedule, command and active status still need per-version comparison. |

## Exact function/ACL spot-check: ownership transfer

For live-only version `20261013181250` (`secure_schoolpro_ownership_transfer`), compared the recovered SQL payload directly to the live `public.schoolpro_transfer_ownership(uuid,uuid)` definition.

- The recovered function updates `schoolpro_leadership_settings` only when a row already exists.
- The live function uses an UPSERT (`INSERT ... ON CONFLICT ... DO UPDATE`) to ensure the proprietor title row exists. This is a **material live behavior change**, not a formatting-only difference.
- The live function is `SECURITY DEFINER` with an empty search path, and checks `auth.uid()`, active Super Admin profile role, school existence, active target profile and non-identical owner before changing ownership.
- Live effective function privileges: `anon` cannot execute; `authenticated` can; `service_role` can. The recovered version explicitly revokes PUBLIC/anon and grants authenticated, but the live catalog also grants service_role. This ACL difference must be traced to its later source and assessed; do not assume the old grant statement describes the current effective ACL.
- The live function removes the former owner's school membership but intentionally does not alter the former user's platform-level Super Admin role.

The observed difference is recorded as **superseded/evolved live definition; later UPSERT behavior and extra service_role ACL need provenance and authorization review**. No changes were made.

## Required interpretation

The triage reveals why the 397 versions cannot be marked complete by object-name existence alone. Function overload identity arguments and bodies, current effective grants, policy expressions, trigger-to-function wiring, cron job commands/schedules and later migration transitions must be compared individually. The simple parser's policy/trigger misses are not accepted as true absence without inspecting the underlying SQL.

## Next batch

Continue by resolving all five missing function names, the 236 function declarations with live names but no body substring match, and every policy/grant/trigger/cron statement. Start with SchoolPro security, results, subscription/payment, identity and Storage paths; then reconcile shared platform/DataSub/Academy/other-service versions so the 397-version total is not silently reduced to SchoolPro-only SQL.
