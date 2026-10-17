# Semantic catalog spot-check and live-main call-site parity — 2026-10-17

## Safety and scope

Read-only inspection of the live Supabase catalog and GitHub `main` source. No SQL executed against production beyond SELECT/catalog inspection; no writes, export/import, migration replay, Aiven changes, Render changes, deployment, merge, or cutover. The source database remains authoritative.

This is a bounded semantic spot-check, not a claim that all 397 recovered live-only SQL versions or all 79 cross-boundary foreign keys are closed.

## Recovered SQL compared with live catalog

The source payloads were read from `supabase_migrations.schema_migrations` and compared to current definitions using `pg_indexes`, `pg_constraint`, `pg_get_functiondef`, `pg_trigger`, and `cron.job`.

| Ledger version / migration | Expected SQL effect | Live catalog observation | Classification |
|---|---|---|---|
| `20260917000302` `index_subject_allocations_by_subject` | `CREATE INDEX schoolpro_subject_assignments_subject_idx ON public.schoolpro_subject_assignments(subject_id)` | Exact live index definition is `CREATE INDEX ... USING btree (subject_id)` on the expected table. | **Exact semantic match** for this index. |
| `20261015161735` `schoolpro_access_invitation_role_constraint` | Recreate role CHECK with the 20 accepted role strings, including class_teacher, head_teacher, exam_officer, IT/admin and operational roles. | Live `schoolpro_access_invitations_role_check` contains the same 20 values in the expected `role = ANY(text[])` check. | **Exact semantic match** for this constraint. |
| `20261003161802` `schoolpro_once_only_four_month_demo_and_expiry_grace` | Drop `trg_schoolpro_demo_window` and `private.validate_schoolpro_demo_window()`; add demo columns and unique partial index; define `activate_schoolpro_demo(uuid,uuid)`; define expiry routine; schedule daily job. | Trigger and obsolete validator are absent; `schoolpro_demo_once_per_school` partial unique index matches. The two-UUID `public.activate_schoolpro_demo` overload still exists but now raises `Use calendar-reviewed term demo approval`; a separate overload implements the newer calendar-reviewed flow. The live expiry function has materially evolved from the recovered body to distinguish trial expiry and annual paid grace. Cron job `schoolpro-expiry-grace-daily` is active at `15 0 * * *` and calls `private.enforce_schoolpro_subscription_expiry()`. | **Partially present / superseded by later behavior.** The version's current catalog state must be understood as a historical transition, not replayed. The later definition and job are live; the old function body is not semantically equivalent. |
| `20261003161802` demo request column/index changes | Add `school_id`, `activated_at`, `free_access_ends_at`; unique index where school_id is not null. | `schoolpro_demo_once_per_school` exists with the expected predicate; live index inspection alone does not prove every column's exact type/default/FK semantics. | **Index confirmed; column details not closed by this spot-check.** |

### Consequence

The name-level reconciliation of 634 references (622 present, 12 absent, 11 explained by later drops, `public.activity_logs` unresolved) remains only a name-level check. The examples above demonstrate why: objects can exist while their bodies evolve, overloads differ, or historical functions become guarded stubs. A full semantic pass must compare definitions and dependencies, including grants, RLS, trigger wiring, scheduled jobs and dynamic SQL. Never replay recovered live-only SQL to “make it match”; it is historical evidence.

## Dynamic Storage call mapping from live Render source branch

Render's latest recorded production frontend commit remains `29856dff17ea8a3bc8bb31b7900967b7df9d316b`. Read-only GitHub `main` source review resolved the callers that use `DesignAssets` / `useDesignImages`:

| Source file (GitHub main) | Component/helper | Resolved bucket(s) | Other relevant operations |
|---|---|---|---|
| `src/pages/schoolpro/SchoolProDocumentStudio.tsx` (blob `53646266fd4aea9bdf2370f48ddfbe9581249f48`) | Imports `DesignAssets`, `useDesignImages`; template card passes `bucket="schoolpro-document-templates"`; visual editor calls `useDesignImages('schoolpro-document-templates', row.settings)`. | `schoolpro-document-templates` for original/converted template uploads, signed URLs, download/removal, logo/signature assets. `schoolpro-document-outputs` for generated issued-document outputs. | Invokes `schoolpro-render-document`; reads/writes `schoolpro_document_templates` and `schoolpro_document_issues`. |
| `src/pages/schoolpro/SchoolProInvoiceStudio.tsx` (blob `6570c11dc9dde1319dfa89b19cc458f9dbe9bfaf`) | Imports `DesignAssets`, `PaperPreview`, `useDesignImages`; both receive `schoolpro-invoice-templates`. | `schoolpro-invoice-templates` for uploaded source templates and invoice logo/signature images. | Reads/writes `schoolpro_invoice_templates` and fee structures/items. |
| `src/pages/schoolpro/SchoolProBrandingSettings.tsx` (blob `d8f74a722d53bead9aeeef2ab8950445a08022a7`) | Separate branding editor, not `DocumentDesign`. | `schoolpro-branding`; source also references the `schoolpro_branding` table (underscore in table name, hyphen in Storage bucket). | Must preserve that distinction in API mapping. |
| `src/pages/schoolpro/SchoolProResultTemplates.tsx` (blob `9d148eb22ad96d4ab6c633553bf998d61d0d8027`) | Result design/workbook path, separate from `DocumentDesign`. | `school-result-templates` for workbook/template, logo and signature assets; `schoolpro-result-outputs` for generated outputs. | Existing cross-component mismatch remains: deployed result renderer/access function historically writes/signs in `school-result-templates`, while generated-output rows point to `schoolpro-result-outputs`. Must resolve with real Storage API/signed URL tests before migration. |

This closes the *known caller values* for the `DocumentDesign` helper in the reviewed `main` source files. It does **not** prove branch/live parity because the repository source was fetched from `main` while Render's last recorded deployed commit is older/different; no build artifact or source-map parity proof was obtained. The 463-row migration-branch static manifest also remains non-exhaustive for aliased, wrapper-mediated, multiline and dynamically composed calls.

## Updated outstanding gates

1. Complete semantic comparison of all recovered live-only SQL payloads against current live definitions, version-by-version; include function overloads/bodies, policies, grants, triggers, cron jobs and dependencies.
2. Resolve all 79 canonical cross-boundary FK entries by exact name and source/target column pair, including row-level orphan/tenant checks where applicable. Do not fold adjacent private/shared integration references into the count without reconciling the original scope.
3. Finish ownership disposition for the 18 tables without direct `school_id`; targeted joins and counts are evidence but not export authorization.
4. Compare source call sites and Edge Function behavior at the exact Render-deployed commit and restore/version deployed Edge Function source where needed.
5. Keep export/import, SQL replay, production config changes, deployment, merge and cutover blocked until target rehearsal, complete reconciliation and explicit owner approval.


## Additional result-workflow semantic checks — 2026-10-17

A second read-only comparison checked current definitions for the recovered ledger versions around class result submission and result publication/review:

- `20261013130821 audit_schoolpro_schoolwide_result_publication`: live `public.publish_schoolpro_results(uuid,text,text)` retains the recovered authorization sequence (authenticated caller, results module permission, school leadership or exam-officer/head-teacher/vice-principal role), validates term/session, and updates only unlocked `approved` results for the exact school/term/session to published+locked before recording an audit event. The inspected body matches the recovered migration body in its material authorization and state-transition behavior.
- `20261013130652 fix_schoolpro_class_result_submission_school_scope`: the live `School result leaders read class submissions` policy explicitly correlates `m.school_id = schoolpro_class_result_submissions.school_id`, then requires the user to be a school manager or one of the enumerated school-member roles. This is the corrected qualified correlation, not the earlier ambiguous `m.school_id=school_id` expression from the initial table/policy migration.
- `20261013130436 restrict_schoolpro_class_result_submission` and `20261012162055 schoolpro_class_result_submission_records_20261012`: the live submit RPC checks that the class belongs to the supplied school, requires a school manager or that class's form teacher, restricts eligible result rows to the school/class/term/session, and stores a fingerprint under the unique school/class/term/session key. The current policy and routine therefore reflect the later school-scope correction; do not replay the earlier ambiguous policy.
- `20261012124738 schoolpro_unpublished_class_result_preview`: live `public.schoolpro_review_result(uuid,text,text)` derives the school/class through the student's enrollment history for the requested session, calls `private.schoolpro_can_review_class`, and returns only that student's matching school/term/session rows. The reviewed body retains this gate.
- `20261011230828 schoolpro_print_historical_results_with_caller_row_permissions`: live `public.schoolpro_printable_result(uuid,text,text)` requires authentication and a valid academic period, checks `public.schoolpro_result_access`, and returns only locked/published matching rows. It relies on caller row policies for class/subject/family scope, so the RLS policies and real RPC tests remain part of the acceptance gate.

These are semantic body/policy comparisons for selected high-risk result workflow versions, not an exhaustive grant/revoke, RLS, trigger, or all-397-version comparison. The current RLS policies also include later cache-based result-reader predicates; the whole policy set must be diffed as a set rather than treating any one migration body as the complete current policy.

The exact 79-constraint live FK list is now separately committed in [SCHOOLPRO-79-CROSS-BOUNDARY-FK-REVIEW-2026-10-17.md](SCHOOLPRO-79-CROSS-BOUNDARY-FK-REVIEW-2026-10-17.md), commit `9fa27b272bd1d75c6ac8f1ea69f132bd54b6f3ac`. Current live catalog says 79/79 are validated. This closes the inventory/validation-status check only; it does not close ownership, tenant authorization, shared-service disposition, or target-schema replacement.
