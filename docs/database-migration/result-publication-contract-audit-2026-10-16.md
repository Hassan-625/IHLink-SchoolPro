# SchoolPro result-publication contract audit
**Date:** 2026-10-16  
**Source:** read-only catalog inspection of the live Supabase PostgreSQL project.  
**Scope:** static analysis of `public.schoolpro_results` policies and enabled triggers; no write probes or production changes.

## Executive result

The live result workflow is enforced by a combination of RLS policies and several triggers. No single trigger is the whole contract. The target API/MySQL design must preserve the intersection of these checks, including status transitions, score fields, the explicit `locked` flag, tenant references, operational subscription status, inactive-student rules, lifecycle events and email side effects.

**No bypass has been demonstrated.** The lock-trigger interaction below is a code-review question to resolve with owner-approved tests in an isolated environment, not a claim of an exploitable production vulnerability.

## Live trigger order on `schoolpro_results`

PostgreSQL runs same-kind triggers in trigger-name alphabetical order. The catalog reports all nine listed triggers enabled (`tgenabled = O`).

| Order | Trigger | Timing | Function | Role in contract |
|---:|---|---|---|---|
| 1 | `calculate_schoolpro_result_total` | BEFORE INSERT / UPDATE OF assessment_scheme_id, assessment_scores | `private.calculate_result_total()` | Reads JSON scheme components; rejects negative/over-maximum values; missing component score defaults to zero; writes total_score |
| 2 | `enforce_schoolpro_result_relations` | BEFORE INSERT / UPDATE OF school_id, student_id, subject_id, assessment_scheme_id | `private.enforce_schoolpro_tenant_relations()` | Validates tenant relationships for result and scheme |
| 3 | `enforce_schoolpro_result_workflow` | BEFORE UPDATE | `private.enforce_result_workflow()` | Blocks edits to selected assessment fields when old status is published; role-gates status changes; stamps approval/publication metadata |
| 4 | `schoolpro_activation_before_write` | BEFORE INSERT / UPDATE / DELETE | `private.guard_schoolpro_operational_write()` | Checks operational subscription state for interactive writes, with a separate trusted-background path |
| 5 | `schoolpro_active_pupil_activity` | BEFORE INSERT / UPDATE | `private.schoolpro_reject_new_inactive_student_activity()` | Rejects new result activity for inactive/transferred students |
| 6 | `trg_schoolpro_result_email` | AFTER UPDATE OF status | `public.queue_schoolpro_transactional_email()` | Queues transactional email side effect |
| 7 | `trg_schoolpro_result_lifecycle_event` | AFTER UPDATE | `private.log_schoolpro_result_lifecycle()` | Writes lifecycle event/snapshot for selected status transitions |
| 8 | `trg_schoolpro_result_lock` | BEFORE UPDATE | `public.enforce_schoolpro_result_lock()` | Checks row JSON differences when old and new locked flags are both true |
| 9 | `trg_validate_schoolpro_result_tenant` | BEFORE INSERT / UPDATE OF school_id, student_id, subject_id, session, term | `private.validate_schoolpro_result_tenant()` | Verifies same-school student/subject; requires and trims session/term |

Trigger names are sorted alphabetically within timing/event groups; this list is the catalog's trigger-name ordering, not an assertion that AFTER and BEFORE triggers execute in one combined sequence. Confirm timing groups and execution behavior in isolated tests. Any target implementation should make ordering explicit in service transaction logic rather than relying on accidental port order.

## Relevant RLS contract

- **Insert:** permissive policy requires `private.schoolpro_can_write_result(school_id, student_id, subject_id, session)`, `locked = false`, and `status = 'draft'`.
- **Update:** permissive policy requires the same authorization, and the existing row and resulting row must be unlocked draft records. The policy `USING` and `WITH CHECK` both encode the draft/unlocked condition.
- **Read:** SELECT is a composition of permissive reader scope and restrictive gates: active account, readable student scope, plus cached school/staff/family/result-reader relationships. Do not translate this as a single role check.
- **Result events:** SELECT is limited to platform super-admin or specified school leadership roles.
- **Class and student reads:** restrictive policies narrow broader permissive policies through `schoolpro_can_read_class(id)` and `schoolpro_can_read_student(id)`.
- **Assessment scheme:** reads combine general school access with more specific staff/guardian policies; create/update/delete is limited to proprietor/administrator, plus a super-admin policy. Review exact role implications against product requirements before porting.

PostgreSQL permissive policies combine by OR; restrictive policies combine by AND. The replacement API must reproduce the effective policy expression, not copy each policy as an independent allow rule.

## Lock interaction requiring isolated verification

Two separate protections are active:
1. `private.enforce_result_workflow()` rejects changes to `ca_score`, `exam_score`, `assessment_scores`, and `assessment_scheme_id` when the old status is `published`. It also role-gates status changes.
2. `public.enforce_schoolpro_result_lock()` rejects a changed row only when both `old.locked = true` and `new.locked = true`, ignoring `locked` and `updated_at` when comparing JSON.

The second condition is asymmetric: its body does not reject a transition from `locked=true` to `locked=false` on its own. Normal authenticated UPDATE RLS requires the old and new row to be unlocked draft records, so the policy should block that direct path; however, privileged service-role/background writers can have different RLS behavior. Whether another trusted routine/trigger constrains every privileged path must be established by tracing grants, service-role callers and all update paths.

**Do not patch production based on this static observation.** In a disposable clone, write contract tests for:
- authenticated direct update of a published result;
- authenticated direct update of a locked draft;
- attempts to clear `locked` while changing result values;
- authorized correction/reopen workflow and its required audit reason;
- privileged/background update path, with explicit allowlist and audit;
- cross-school student, subject and assessment scheme IDs;
- score below zero, score above component max, absent score, malformed numeric value, empty/missing scheme;
- lifecycle event and email side effects for every allowed status transition;
- transaction rollback proving no partial row update or orphan event/notification.

The expected result for direct user mutation of published/locked records is denial. Any approved privileged path must be narrowly defined, attributable, and auditable.

## Target-side contract proposal

Implement a single server-side result command service with separate operations:
- `saveDraft`: class/form master or assigned teacher scope; validates active enrollment, tenant, session/term, subject allocation and component bounds.
- `submitForReview`: validates required assessment completeness; records actor and transition.
- `approve` / `publish`: exam-officer/authorized leadership policy; transactionally updates status and appends immutable lifecycle event.
- `requestCorrection`: required after publication; captures reason, requester, reviewer, prior snapshot and resulting change.
- `applyCorrection`: only through approved correction workflow; writes immutable audit history and controlled republication.
- `readResults`: enforces student/family/teacher/leadership scope server-side and queries only selected class/session/term.
- `sendPublicationNotification`: transactional outbox + idempotent worker, not an external email call inside an unrepeatable transaction.

The target's normalized component schema must be compared with the live JSON scheme using golden fixtures; missing-score-as-zero, maximum score, decimal precision, scheme edits and historical scheme snapshot semantics need explicit decisions.

## Exit criteria

Do not mark result-publication parity complete until the source caller/ACL map is captured, every path is covered by allowed/denied isolated tests, event/email idempotency is proven, and target calculation fixtures match the live behavior or a documented owner-approved change. Production remains on Supabase and Render; this document authorizes no schema changes, deployments, or cutover.
