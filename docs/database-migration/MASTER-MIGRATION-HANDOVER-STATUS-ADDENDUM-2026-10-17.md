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

## Full FK and tenant-pair audit — 2026-10-17
A generated read-only check enumerated 221 public foreign-key constraints where either child or parent table is SchoolPro-prefixed. For every constraint, the check counted non-null child keys without a matching parent row: **0 orphan FK rows across 221 constraints**. A second generated check covered 86 FK relationships where both child and parent have a `school_id` column (excluding direct school_id-to-school_id key constraints): **0 cross-school parent/child mismatches across all 86 relationships**. Null FK columns were separately observed but are not classified as defects because many are intentionally optional; they require column-nullability and workflow review. These are current-row consistency checks, not future-write or RLS-bypass proof.

## Expanded storage object reconciliation — 2026-10-17
Bucket/object-to-record matching found:
- `schoolpro-document-outputs`: 83/83 objects reference `schoolpro_document_issues.output_storage_path`; all 83 path prefixes equal the issue `school_id`.
- `schoolpro-document-templates`: 9 objects; 3 match `schoolpro_document_templates.storage_path`. The other 6 are not referenced by that table; 4 use a known school prefix and 2 use a prefix that is not a SchoolPro school ID. Seven objects in the bucket have null `owner_id`. These require manual record/intent classification before any export.
- `school-result-templates`: 8 objects; only 1 matches a `schoolpro_result_templates` path. The other 7 are not referenced by that table; all 8 have null `owner_id`, though all path prefixes correspond to a known school. These are unresolved, not automatically orphaned because other media/report paths may exist.
- `schoolpro-invoice-templates`: 2 objects with known school prefixes and null `owner_id`; all 4 `schoolpro_invoice_templates` rows have null `storage_path`, so no direct row-to-object mapping was established.
- `schoolpro-demo-documents`: 2 objects; both first path segments correspond to profiles, consistent with the current bucket policy's user-ID path model rather than school-ID paths. They are not linked to a document issue row.
- `schoolpro-result-outputs`: 1/1 object matches `schoolpro_generated_result_outputs.storage_path`.
- `schoolpro-admissions`, `schoolpro-payment-receipts`, and `schoolpro-branding`: zero objects currently; no positive object-access test is possible for these buckets.
- `schoolpro-document-outputs`, `schoolpro-document-templates`, `schoolpro-invoice-templates`, and `school-result-templates` are private buckets; `schoolpro-branding` is marked public but empty.

These counts are not export clearance. Enumerate all paths and determine their owning record/tenant, purpose, retention, and access policy before copying objects. Authenticated adversarial read probes are still required for each distinct storage policy and each download route.

## Expanded migration-source matching — 2026-10-17
The source comparison was broadened from exact version matches to exact migration-name matches across both the current SchoolPro branch and `Hassan-625/IHLink_Design_System_1`. Of the 397 live-only ledger entries, 106 have a same-name SQL candidate in one of those trees: 11 exact-version/name candidates and 95 candidates whose timestamp differs from the live ledger version. Detailed object/reference notes were added for all 11 exact-version candidates and all 95 timestamp-different candidates (the final five are in the [source-candidate review supplement](LIVE-ONLY-SOURCE-CANDIDATE-REVIEW-REMAINDER-2026-10-17.md)). A total of 106 live-only versions now have a same-name source candidate reviewed; 291 have no same-name SQL candidate in the inspected trees. A timestamp-different file is only a source candidate, not proof of the deployed payload; source differences and authoritative deployment evidence remain unresolved.

## Broader generated integrity checks — 2026-10-17
- Enumerated 221 public foreign-key constraints where the child or parent table is SchoolPro-prefixed. Generated LEFT/NOT EXISTS checks found **0 orphan rows with non-null FK values across all 221 constraints**.
- Enumerated 86 FK relationships where both child and parent have a `school_id` column, excluding direct school-id-to-school-id FK constraints. All 86 returned **0 child/parent school mismatches**.
- These are read-only current-row checks. Optional null FK values are not treated as orphan defects. They do not prove tenant isolation for future writes, RPC/service-role paths, or storage access.


See the [five-entry source-candidate review supplement](LIVE-ONLY-SOURCE-CANDIDATE-REVIEW-REMAINDER-2026-10-17.md) for the final timestamp-different candidates and their blob SHAs.

## Additional authenticated storage and anonymous probes — 2026-10-17
All tests below were read-only and transaction-scoped; each transaction was rolled back:
- Anonymous role: 0 visible `schoolpro_document_issues` rows and 0 visible `schoolpro-document-outputs` objects.
- A school registrar in school `d342eb87-8d6a-477a-a380-7fab83f586b7`: 141 visible document issues for that school and 0 for the other sampled school; 83 visible document-output objects and 0 objects with the other school's path prefix.
- A proprietor in that same school: 7 visible objects in `schoolpro-document-templates`, all with the proprietor's own school prefix and 0 with the other school's prefix; 2 visible `schoolpro-invoice-templates` objects, both own-school prefix; 8 visible `school-result-templates` objects, all own-school prefix and 0 other-school prefix.
- The same registrar had 0 visible objects in `schoolpro-document-templates`, consistent with the manager-only read policy for that bucket.
- These sampled reads support current-policy school scoping for the tested roles/buckets. They do not test upload/update/delete, object-key tampering, direct signed/public URL exposure, or the proposed issued-document policy on a deliberately mismatched fixture. The two document-output buckets have existing data; the admissions/payment-receipt buckets are empty and remain untested on actual objects.
