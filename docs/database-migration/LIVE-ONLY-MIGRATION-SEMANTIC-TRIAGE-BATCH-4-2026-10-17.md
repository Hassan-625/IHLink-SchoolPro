# Live-only SQL semantic comparison — batch 4: class-result submission policy correction — 2026-10-17

## Scope

Compared the exact ledger payloads for `20261012162055 schoolpro_class_result_submission_records_20261012`, `20261013130436 restrict_schoolpro_class_result_submission`, `20261013130652 fix_schoolpro_class_result_submission_school_scope`, and `20261013130821 audit_schoolpro_schoolwide_result_publication` with the current policy/function catalog. Read-only only.

## Policy defect and later correction

The initial policy in `20261012162055` contained this correlation:

`where m.school_id=school_id and m.user_id=auth.uid()`

Because the unqualified `school_id` is ambiguous in the subquery, it did not clearly bind the membership row to the submission's school. Version `20261013130652` explicitly drops/recreates the policy and qualifies the correlation:

`m.school_id = schoolpro_class_result_submissions.school_id`

The current `pg_policies` catalog confirms that exact school-correlated policy structure, with `private.schoolpro_module_allowed(school_id,'results')` plus school-manager or authorized-role membership checks. This is a resolved source-to-live policy evolution; the corrected version, not the first version, is the target baseline.

## Function grants and submission semantics

Version `20261013130436` revokes `PUBLIC` and `anon` execution from `public.schoolpro_submit_class_results(uuid,uuid,text,text)` and grants execution to `authenticated, service_role`. Current function definition retains this intended workflow:

- caller must be authenticated and pass results module permission;
- class ID must belong to the supplied school;
- caller must be school leadership/manager or the assigned class form teacher;
- at least one eligible unlocked draft result must exist for the same school/class/term/session;
- fingerprint is computed for that school/period and a submission row is inserted/upserted on the unique school/class/term/session key.

The current `publish_schoolpro_results(uuid,text,text)` definition matches the `20261013130821` body: authenticated caller, module permission, leadership/exam-officer/head-teacher/vice-principal authorization, valid period, updates only matching school/term/session unlocked approved results to published and locked, and writes an audit event. This is a school-scoped publication operation; it does not publish drafts or other periods.

## Disposition

- **Resolved:** ambiguous policy correlation corrected by `20261013130652`; live catalog uses the explicit outer-table school column.
- **Resolved:** anonymous execution on the class-submission RPC revoked by `20261013130436`; current function logic matches the intended class/period gates.
- **Still required:** adversarial tests for cross-school class IDs, a teacher assigned to another class, wrong school ID, wrong term/session, repeated submission/concurrency, and a direct anon RPC attempt. The current catalog comparison is not a substitute for those execution tests.

No production changes were made.
