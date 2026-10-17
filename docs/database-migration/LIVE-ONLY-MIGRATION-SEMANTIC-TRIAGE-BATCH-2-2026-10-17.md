# Live-only SQL semantic comparison — batch 2: dropped routines, RLS evolution, ACL implications — 2026-10-17

## Scope

This batch resolves the five function-name misses from the first 397-version triage, traces a multi-version RLS policy evolution chain, and records current grant implications. All reads were against the production migration ledger and live PostgreSQL catalogs. No DDL, policy, grant, data, cron, or Edge Function changes were made.

## 1. All five missing routine names are explained by later explicit DROP migrations

| Original recovered version | Routine declaration | Later migration | Evidence / disposition |
|---|---|---|---|
| `20260920145208 datasub_automated_wallet_payments` | `public.finalize_datasub_payment(text,text,numeric,text,jsonb)` | `20261002143824 remove_legacy_flutterwave_datasub_payment` | Explicit `DROP FUNCTION` and drop of the legacy `datasub_payment_intents` table. **Resolved as intentionally retired legacy flow**, not a missing live object. |
| `20260926134501 datasub_market_pricing_control` | `public.datasub_admin_set_provider_state(uuid,boolean,integer,text)` | `20261002144053 remove_obsolete_manual_datasub_provider_activation` | Explicit `DROP FUNCTION`. **Resolved as intentionally retired**; inspect replacement provider-health/activation workflow when reconciling DataSub operations. |
| `20261002132721 academy_payment_reconciliation` | `public.finalize_academy_payment(uuid,text,numeric)` | `20261002132735 academy_use_shared_commerce` | Explicit `DROP FUNCTION` while removing `academy_course_orders` and introducing a shared-commerce finalizer. |
| `20261002132735 academy_use_shared_commerce` | `public.finalize_academy_course_order(uuid)` | `20261002135612 remove_obsolete_academy_order_finalizer` | Explicit `DROP FUNCTION`. The intermediate function was also revoked from public/anon/authenticated and granted only to `service_role`. **Resolved as intentionally retired**, not to be restored to the target. |
| `20261003160942 schoolpro_annual_subscription_and_four_month_demo_window` | `private.validate_schoolpro_demo_window()` | `20261003161802 schoolpro_once_only_four_month_demo_and_expiry_grace` | Explicitly drops `trg_schoolpro_demo_window` and `private.validate_schoolpro_demo_window()`. **Resolved as intentionally replaced** by once-per-school demo logic. |

**Result:** all five “no current routine by name” cases from batch 1 now have explicit later-ledger dispositions. None should be resurrected into the target schema merely to make the recovered SQL set look complete. This resolves that five-item absence category, not the 236 body/overload mismatches.

## 2. Ownership-transfer function has a later exact semantic successor

The current `public.schoolpro_transfer_ownership(uuid,uuid)` body matches the SQL payload of `20261013184713 schoolpro_ownership_transfer_upsert_leadership_title` (allowing for canonical formatting). That migration follows `20261013181250 secure_schoolpro_ownership_transfer`.

The predecessor did not create a missing `schoolpro_leadership_settings` row. The successor and live body use:

`INSERT ... ON CONFLICT (school_id) DO UPDATE SET owner_title = excluded.owner_title`

The live function remains `SECURITY DEFINER`, has an empty search path, checks authenticated actor and active Super Admin profile, locks the school row, validates an active target profile, rejects transfer to the existing owner, establishes proprietor membership/title, changes `owner_id`, and removes the former owner's school membership. The function's platform Super Admin role is not altered. The current ACL includes `authenticated` and `service_role`, but not `anon`; the service-role grant is a later effective privilege and must be preserved only if the trusted service adapter actually requires it.

**Disposition:** the later version is the authoritative source definition; do not compare the first declaration against live as if it were supposed to remain byte-identical.

## 3. RLS policy evolution: `schoolpro_module_permission`

The ledger contains a staged policy series, not one invariant policy definition:

- `20260929203846 schoolpro_module_permission_enforcement` introduced `private.schoolpro_module_allowed(uuid,text)` and restrictive `schoolpro_module_permission` policies across SchoolPro tables.
- `20261003104939`, `20261003110653`, `20261003111212`, `20261003111312`, `20261003111450` and `20261003112541` removed or replaced generic module-only policies on sensitive question-bank, CBT, payroll, invitation, discipline, hostel, transport, assignment, admissions and related tables with role-specific policies.
- `20261003114552 bind_schoolpro_result_writes_to_teaching_assignment` replaced the result write policy with `private.schoolpro_can_write_result(...)`, binding teacher writes to an assignment for the same school, student class, subject and session.
- Later versions such as `20261007164143 school_invoice_customer_read_boundaries`, `20261011092231 schoolpro_operational_staff_and_fee_breakdown_access`, `20261012082824 schoolpro_family_timetable_read_without_staff_write_access` and `20261012112914 schoolpro_bound_family_class_checks_without_nested_rls_scans` further changed policy composition for finance and family access.

### Important semantic nuance

The live `private.schoolpro_module_allowed(target_school, required_permission)` returns false for null/inactive callers; checks module permissions when the caller owns/is a member of the school or is a platform admin; but returns true in the final `else` branch for a caller not recognized as belonging to that school. This helper therefore **must not be treated as the tenant-ownership predicate by itself**. In restrictive policy composition, it is intended to gate the module permission while other permissive policies enforce row access. The target must preserve and test the full policy composition, including permissive/restrictive mode, command, role list, USING and WITH CHECK—not copy this helper as a standalone authorization check.

The earlier quick comparison that searched for the catalog's normalized policy expression as a literal substring in migration SQL produced false mismatches because PostgreSQL deparses and normalizes expressions and because policies are subsequently altered/dropped/recreated. Those string-substring mismatch counts are **not accepted as semantic differences**. The version chain above is based on explicit ledger operations; the complete policy-by-policy expression and effective-policy truth-table matrix remains open.

## 4. ACL comparison status

The effective anonymous SECURITY DEFINER grant report remains a separate, high-priority ACL disposition. Six public SchoolPro RPCs are currently executable by `anon`; the result-PIN checker lacks an in-body failed-attempt throttle, and result/document verification and admissions token endpoints require enumeration/abuse review. The corresponding report records the explicit historical grant and the current zero-row state of result PIN/verification tables.

For the full 397-version matrix, every GRANT/REVOKE must be reconciled to the *current effective* function/table/sequence/schema ACL, including default privileges and grants to `service_role`. A historical GRANT statement is not evidence that the same privilege remains necessary or safe.

## 5. Remaining scope

- Continue overload-aware routine comparison for the 236 declarations whose current function name exists but whose body did not match the declaring SQL payload. Trace later `CREATE OR REPLACE`, ALTER OWNER, ACL changes and explicit DROP/rename before classification.
- Build effective RLS snapshots for all 293 live policies, including permissive/restrictive mode, command, roles, USING and WITH CHECK; reconcile against every create/alter/drop migration in version order.
- Compare table, sequence, schema and function ACLs with default privileges; capture grants/revokes that affect shared identity, payments, Storage, email, academic clock and DataSub.
- Continue trigger/function wiring review and all historical cron schedule/command transitions, not just current job-name matches.

No production change was made. This is a versioned semantic evidence batch, not a 397-version completion certificate.
