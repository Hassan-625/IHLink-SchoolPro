# Master migration handover status addendum — 2026-10-17

This checkpoint supplements `MASTER-MIGRATION-HANDOVER.md`; the large master file itself has not been rewritten in this pass.

## Evidence status
- Production Supabase ledger: 476 versions. The original comparison found 397 live-only versions against the 123-file branch snapshot. A draft RLS correction was subsequently added on the migration branch; it is not deployed.
- The remote marker enumerates 35 distinct versions, all matching the live ledger by exact version/name. No exact-version SQL source for those 35 was found in the inspected SchoolPro branch or related repository tree.
- The related `Hassan-625/IHLink_Design_System_1` repository contains 139 migrations. Eleven exact-version source candidates for live-only versions were recovered there and documented in the inventory. They are corroborating source candidates, not proof of deployment.
- No authoritative migration API audit event with actor/time/request/result has been recovered.

## Tenant and storage evidence
- Prior 17 cross-school relationship checks: zero mismatches.
- 141 document issues: no orphan/null student refs, no student/issue school mismatch, no orphan/null template refs, and no template/issue school mismatch.
- 83 document issue events: no orphan issue refs or event/issue school mismatch.
- 96 academic documents: no orphan student refs or school mismatch. Admission-document table has zero rows.
- All 83 document output paths match an object in `schoolpro-document-outputs`; all 83 first path segments match the corresponding issue `school_id`.
- Three document-template rows match storage objects and school prefixes; the bucket contains nine objects total, so six objects remain to be classified.
- Admission and payment-receipt buckets have zero objects. Policy definitions were inspected, but authenticated adversarial storage tests have not run.
- The live `students read own issued documents` policy contains `st.school_id = st.school_id`. A correction is drafted on the branch only.

## Approval gates remain open
1. Recover original SQL and authoritative deployment evidence for all 35 marker versions.
2. Complete object/dependency review for all 397 live-only versions. Eleven source candidates have been reviewed; the remaining 386 lack exact-version source in inspected repositories. Unresolved scope buckets remain provisional.
3. Test the draft policy correction in a disposable rehearsal with two authenticated school identities, including full policy composition, PostgREST reads and document-download paths. Do not apply to production before explicit rollout approval.
4. Complete orphan/null checks across all SchoolPro child relationships, classify every storage object, and run adversarial cross-tenant read/write/update/delete and RPC/path-tampering tests in rehearsal.
5. Verify target network restrictions before any rehearsal import.

**Export/import is not approved.** No production DDL, migration replay, data export/import, Render configuration change, deployment or merge occurred.

## Evidence links
- [Remote-batch provenance](REMOTE-BATCH-SQL-DEPLOYMENT-PROVENANCE-REGISTER-2026-10-17.md)
- [Live-only version inventory](LIVE-ONLY-MIGRATION-VERSION-INVENTORY-2026-10-17.md)
- [Tenant/catalog reconciliation](LIVE-TENANT-RELATION-CATALOG-RECONCILIATION-2026-10-17.md)
- [Issued-document RLS test plan](ISSUED-DOCUMENT-RLS-CORRECTION-TEST-PLAN-2026-10-17.md)

## New live read-probe evidence
A read-only authenticated two-identity probe against current production RLS returned no cross-school document issue rows and no cross-school output objects for either sampled student identity. One identity could see one own issue/output object; the other saw none. Both transactions rolled back. This validates only sampled current-policy reads and does not exercise a deliberately mismatched issue/student row or test the proposed policy correction. Write/delete, guardian/staff, RPC, and download-endpoint adversarial tests remain open.
