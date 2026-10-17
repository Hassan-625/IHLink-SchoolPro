# Master migration handover continuation — 2026-10-17

This is a continuation checkpoint for the existing [Master Migration Handover](MASTER-MIGRATION-HANDOVER.md). It records the latest committed audit artifacts without replacing the master or changing production.

## New evidence

1. [Row ownership, cross-boundary FK and catalog reconciliation](SCHOOLPRO-ROW-OWNERSHIP-FK-AND-CATALOG-RECONCILIATION-2026-10-17.md) — commit `8a0a4386482a18503615e97672e5592bbbae259b`.
2. [Semantic catalog spot-check and live-main call-site map](SCHOOLPRO-SEMANTIC-CATALOG-SPOTCHECK-AND-LIVE-CALLSITE-MAP-2026-10-17.md) — commit `1d146b107cac27ff3cd31390a8dbdf903b6909e2`.
3. [Application dynamic call-site review](APPLICATION-DYNAMIC-CALLSITE-REVIEW-2026-10-17.md) — commit `d68cc42532c232cbbe1e08118e8ac7ae61d053d6`.

## Current findings

- Exact live counts were obtained for all 18 tables without direct `school_id`. Targeted child-parent checks returned zero orphans in the checked relationships and five same-school consistency checks returned zero mismatches. These results do not constitute full ownership or tenant-isolation sign-off.
- The 79 cross-boundary FK review remains open pending exact constraint-name/column reconciliation. Additional adjacent private/shared integration references surfaced and must remain outside the canonical count until the original scope is reconciled.
- Two recovered SQL effects were semantically confirmed: `schoolpro_subject_assignments_subject_idx` matches the recovered index definition, and `schoolpro_access_invitations_role_check` matches the recovered 20-role constraint. The demo/expiry migration has been superseded in parts: old validation trigger/function are absent, the unique partial index and active cron job exist, and current function bodies differ materially from the recovered historical payload. Do not replay recovered SQL.
- `DocumentDesign` callers were mapped in GitHub `main`: document templates use `schoolpro-document-templates`, invoice assets use `schoolpro-invoice-templates`; result template/output bucket mismatch remains unresolved. Main source has not been proven byte-identical to the deployed Render build.
- The 397 recovered SQL payloads still need complete version-by-version semantic catalog comparison. Name-level presence and file-to-ledger byte equality are insufficient.
- Production export/import, SQL replay, Aiven changes, Render environment/deployment, merge and cutover remain blocked. Supabase remains the source of truth.

## Next action

Continue the semantic comparison for the remaining recovered SQL versions, reconcile all 79 FK entries against the canonical register, and finish the row-level ownership decisions. In parallel, compare the exact Render-deployed frontend/Edge Function source to repository source. Update the master handover when the large-file GitHub update operation is available; the evidence above is already committed on `migration/mysql-schoolpro-foundation`.

No production data or schema was modified.


## Additional FK closure evidence — 2026-10-17

Added [SCHOOLPRO-79-CROSS-BOUNDARY-FK-REVIEW-2026-10-17.md](SCHOOLPRO-79-CROSS-BOUNDARY-FK-REVIEW-2026-10-17.md), commit `9fa27b272bd1d75c6ac8f1ea69f132bd54b6f3ac`. A fresh live catalog query enumerated **79 cross-boundary foreign keys and all 79 are validated**. The individual constraint names, source/target columns and dispositions are now listed. This closes the exact constraint enumeration/validation-status pass, but not ownership semantics or tenant authorization. The remaining 52 Auth and 21 shared Profile references must be treated as external identity links; 3 Virtual Account references and payment transaction relationships remain shared payment integration boundaries; inbound email queue/private academic-clock references need separate operational disposition.

Added [SCHOOLPRO-SEMANTIC-CATALOG-SPOTCHECK-AND-LIVE-CALLSITE-MAP-2026-10-17.md](SCHOOLPRO-SEMANTIC-CATALOG-SPOTCHECK-AND-LIVE-CALLSITE-MAP-2026-10-17.md), commit `1d146b107cac27ff3cd31390a8dbdf903b6909e2`. Two recovered SQL effects semantically match live catalog definitions; the demo/expiry migration is partially superseded by later function definitions and must not be replayed. The DocumentDesign dynamic Storage callers and bucket values were resolved in GitHub `main`, but exact parity with the deployed Render build remains unproven.


## Storage-policy comparison checkpoint

The semantic report was extended at commit `41d4ac4aefe2337d5db87ee2a96ce2d3a22cd64c` with live `storage.objects` policy checks. Document and invoice template bucket policies derive tenant scope from the first path segment, matching the UI's school-prefixed paths. The document-template bucket also has an Academy learner read policy, and the result-template bucket has family report-media and super-admin policies, so these buckets are shared-purpose rather than clean SchoolPro-only boundaries. Real Storage API/signed URL/download adversarial tests remain open; result-renderer bucket mismatch remains a blocker.

The exact FK inventory is committed separately at `SCHOOLPRO-79-CROSS-BOUNDARY-FK-REVIEW-2026-10-17.md`; all 79 current catalog constraints are validated. The semantic report now includes high-risk result workflow definition/policy comparisons and Storage policy cross-checks. Complete all-version SQL semantic parity, all row-ownership decisions, and deployed-commit/Edge Function parity remain outstanding.


## Edge Function source-parity checkpoint

The semantic report was extended at commit `7c6dadd99b01b5f4a3b942a44f224da74a81219a` after read-only retrieval of live Supabase Edge Function metadata and source for ten SchoolPro/auth functions. Three deployed sources exactly match GitHub `main` (`schoolpro-email-worker`, `schoolpro-student-login`, `schoolpro-account-login`); two existing source files differ from live deployed source (`invite-school-staff`, `schoolpro-render-document`); five active functions have no source file at the expected path in `main` (`schoolpro-owner-access`, `auth-handoff`, `schoolpro-transfer-ownership`, `schoolpro-render-result`, `schoolpro-result-access`). This is a material parity blocker.

The deployed result renderer (v6) and result-access function (v1) both use `school-result-templates`, while the frontend and Storage result-output policy use `schoolpro-result-outputs`. The mismatch is confirmed in deployed source and remains unresolved. No function was changed/deployed. Retrieve/version the missing sources, reconcile drift and bucket behavior, and test real Storage API/signed URL/download paths before migration.
