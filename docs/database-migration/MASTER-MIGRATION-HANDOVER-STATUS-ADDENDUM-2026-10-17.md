# Master migration handover status addendum — 2026-10-17

This checkpoint supplements `MASTER-MIGRATION-HANDOVER.md`; the large master file itself has not been rewritten in this pass.

## Evidence status
- Production Supabase ledger: 476 versions. The current migration branch has 123 numbered files, 79 exact version intersections, 397 live-only versions and 44 branch-only versions. The issued-document RLS correction is tracked separately in [draft PR #108](https://github.com/Hassan-625/IHLink-SchoolPro/pull/108), branch `security/issued-document-rls-fix-2026-10-17`; it is not deployed.
- The remote marker enumerates 35 distinct versions, all matching the live ledger by exact version/name. Exact SQL was recovered from the production ledger for all 35, saved to the non-executable forensic folder and byte-compared against the ledger. Separately, all 397 live-only payloads are now preserved in eight JSONL bundles and indexed in a per-version SQL-derived dependency report.
- The related `Hassan-625/IHLink_Design_System_1` repository contains 139 migrations. Eleven exact-version/name and 95 timestamp-different same-name candidates were reviewed; additionally, the 35 marker SQL payloads were recovered directly from the live migration ledger and byte-verified against their saved files.
- The live ledger records `created_by=hassanisahassan12@gmail.com` and NULL idempotency keys for all 35, but has no deployment timestamp field; no separate timestamped API request/response audit event has been recovered.

## Tenant and storage evidence
- Prior 17 cross-school relationship checks: zero mismatches.
- 141 document issues: no orphan/null student refs, no student/issue school mismatch, no orphan/null template refs, and no template/issue school mismatch.
- 83 document issue events: no orphan issue refs or event/issue school mismatch.
- 96 academic documents: no orphan student refs or school mismatch. Admission-document table has zero rows.
- All 83 document output paths match an object in `schoolpro-document-outputs`; all 83 first path segments match the corresponding issue `school_id`.
- Three document-template rows match storage objects and school prefixes; the bucket contains nine objects total, so six objects remain to be classified.
- Admission and payment-receipt buckets have zero objects. Read-only authenticated probes of student, registrar, proprietor and anonymous roles found no cross-school issue/output/template/invoice objects in the sampled paths; these do not test writes, signed URLs, path tampering, or the proposed policy correction.
- The live `students read own issued documents` policy contains `st.school_id = st.school_id`. A correction is proposed in draft PR #108 only.

## Approval gates remain open
1. **SQL recovery complete:** exact ledger payloads for all 35 marker versions are saved and byte-verified. Remaining provenance gate: recover independent timestamped migration-API audit evidence (the live ledger does not retain execution time/request ID).
2. Complete object/dependency review for all 397 live-only versions. 106 live-only versions have same-name source candidates reviewed (11 exact-version and 95 timestamp-different); 291 have no same-name SQL candidate in inspected repositories. Unresolved scope buckets remain provisional.
3. Test the draft policy correction in a disposable rehearsal with two authenticated school identities, including full policy composition, PostgREST reads and document-download paths. Do not apply to production before explicit rollout approval.
4. Generated checks cover 221 public FK constraints (0 orphan rows) and 86 school-paired FK relationships (0 school mismatches). Classify remaining unreferenced storage objects and run adversarial cross-tenant write/update/delete, signed URL/download, RPC and path-tampering tests in rehearsal.
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

## Separate RLS-fix review lane — 2026-10-17
The issued-document policy correction has been moved out of the MySQL migration branch into [draft PR #108](https://github.com/Hassan-625/IHLink-SchoolPro/pull/108) on `security/issued-document-rls-fix-2026-10-17`. Its exact-head [SchoolPro CI](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39045818073) and [payment-page validation](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39045818161) passed. Those workflows do not test PostgreSQL RLS behavior. The PR remains draft and the required disposable two-school policy regression tests have not passed; do not merge or apply the migration to production.


## Remote-batch SQL recovery update
The [35-version provenance register](REMOTE-BATCH-SQL-DEPLOYMENT-PROVENANCE-REGISTER-2026-10-17.md) now records exact SQL recovery from the production migration ledger, creator metadata, NULL idempotency keys and the missing timestamped API audit event. The [recovered payload manifest](RECOVERED-REMOTE-BATCH-SQL-MANIFEST-2026-10-17.md) links all 35 non-executable evidence files. Export/import remains blocked by the unresolved deployment-time provenance, full object/dependency review, RLS regression tests and storage/adversarial access tests.


## Issued-document policy correction and adversarial test — 2026-10-17
- Live policy review found three SELECT-policy paths to harden because permissive policies are OR-combined: student self-read had the tautology \`st.school_id = st.school_id\`; guardian read lacked \`guardian_links.school_id = issue.school_id\`; staff read authorized by issue school without confirming the referenced student belongs to that school.
- Draft PR #108 now changes all three policies while preserving role authorization: [PR #108](https://github.com/Hassan-625/IHLink-SchoolPro/pull/108).
- The disposable PostgreSQL 17 [adversarial RLS regression](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39048035679) passed on code commit \`bcdf42de6ea2c7b24b07618d904642f604634e5f\`. The test used two synthetic schools, demonstrated that the old policy composition exposed a deliberately mismatched issue/student row to Student B, Guardian B and School A staff, applied the exact draft migration, and then confirmed all three were denied the mismatched row. Own-school status behavior and anonymous denial also passed.
- This validates the SQL predicates in the disposable test model only. Authenticated storage read/write/delete, signed URL/path tampering, PostgREST/RPC/download routes, live helper ACLs and production identity plumbing remain open. PR #108 remains draft; no production change or merge occurred.

## Complete live-only SQL evidence index
The [SQL-derived dependency review](LIVE-ONLY-MIGRATION-SQL-DEPENDENCY-REVIEW-2026-10-17.md) now has 397 rows, one per live-only version. Exact ledger payloads for all 397 versions are preserved in eight JSONL bundles under [recovered-live-only-sql](recovered-live-only-sql/); all bundles were fetched back and validated as 397 valid JSONL records with one statement-array entry each. The 35 marker versions also have individual SQL copies and a dedicated provenance manifest. This is source recovery plus static dependency extraction, not final semantic export approval. All migration payloads remain unexecuted.


## Expanded issued-document and storage RLS regression — 2026-10-17
The separate draft [PR #108](https://github.com/Hassan-625/IHLink-SchoolPro/pull/108) now hardens four permissive SELECT-policy paths: student issue reads, guardian issue reads, staff issue reads, and \`schoolpro-document-outputs\` object reads. The storage policy previously used a LEFT JOIN to students and a guardian-link predicate without school equality, allowing the synthetic mismatched issue/output to pass via alternate permissive branches.

The updated [disposable PostgreSQL 17 regression](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39048506722) passed on code commit \`1dfa6f73ebb8b3deb3c8dd5a203ee693f0632220\`. It demonstrated the old row/object visibility, applied the draft migration, and then verified that Student B, Guardian B and School A staff could not see the mismatched issue/object. It also passed own-school issued/revoked behavior, draft visibility rules, anonymous denial, cross-school storage insert denial, path-rename denial, and cross-school delete no-op.

This is a synthetic RLS regression, not proof of actual Supabase Storage API behavior. Signed URLs, real upload/download endpoints, app RPC/view paths, helper ownership/ACLs and the full current production policy catalog still need review. PR #108 remains draft; no production changes or merge occurred.

## SQL-derived scope totals — 2026-10-17
The 397 SQL-derived scope labels are deliberately **non-exclusive** because a single migration can touch multiple products and shared dependencies. Counting rows whose label includes each family yields: SchoolPro 208; shared platform/core 233; DataSub/BillStack 90; business/commerce 57; hosting 35; consult 35; print 30; engineering 29; IHLink Academy 20. These are candidate touch counts, not separate export sets; totals overlap. The current labels classify all 397 rows, but the review is not final: inspect dynamic SQL and called-routine side effects, compare every DDL target with the live catalog, verify shared-table row ownership, and decide each object/record's export treatment. Any mixed/shared migration or table remains excluded from an automatic SchoolPro-only export until explicitly reconciled.

## Latest issued-document policy regression status — 2026-10-17
GitHub reports all three workflows completed successfully on PR #108 head commit `018af841733e094a634955b199ac590bac9f95ff`: Issued-document RLS regression run `39048638982`, SchoolPro CI run `39048638923`, and payment-page validation run `39048638917`. The dedicated regression uses disposable PostgreSQL 17 with synthetic two-school data and tests the exact draft migration. PR #108 remains **open and draft**, has no recorded reviews, and is not approved for merge or production rollout. The test still does not emulate Supabase Storage API/signed URLs or prove the production app's complete RPC/download route behavior.

## Live catalog name reconciliation for extracted dependencies — 2026-10-17
A catalog comparison of the 634 distinct schema-qualified names extracted from the 397 recovered SQL payloads found 622 names present in current catalog relations, routines, types, sequences and other queried objects, and 12 absent names. Historical migration evidence resolves 11 of the absences as intentional removals in later ledger payloads:
- `public.datasub_payment_intents` and `public.finalize_datasub_payment` — removed by `20261002143824_remove_legacy_flutterwave_datasub_payment`.
- `public.datasub_public_catalog` — removed by `20260920195305_remove_security_definer_catalog_view`.
- `public.datasub_admin_set_provider_state` — removed by `20261002144053_remove_obsolete_manual_datasub_provider_activation`.
- `public.schoolpro_one_pending_billstack_per_account` — index explicitly dropped by `20260927105705_schoolpro_direct_school_bank_collection`.
- `public.academy_course_orders` and `public.finalize_academy_payment` — removed by `20261002132735_academy_use_shared_commerce`.
- `public.finalize_academy_course_order` — removed by `20261002135612_remove_obsolete_academy_order_finalizer`.
- `public.create_datasub_purchase` and `private.create_datasub_purchase` — removed by `20261002143940_remove_obsolete_datasub_purchase_rpc`.
- `private.validate_schoolpro_demo_window` — removed by `20261003161802_schoolpro_once_only_four_month_demo_and_expiry_grace`.

The remaining absent name is `public.activity_logs`. The extracted SQL historically references it in shared/service lifecycle migrations, but no current relation with that name exists and the current stored routine bodies inspected did not contain an exact `public.activity_logs` reference. The present live shared log table is `public.audit_logs`, while product-specific logs also exist (e.g. `public.consult_activity_logs`). Treat the historical `public.activity_logs` reference as an unresolved compatibility/history question until the exact ledger SQL and application call sites are traced end-to-end; do not create a replacement table just to satisfy a historical reference.

This name-level comparison is not a full semantic equivalence proof: overload signatures, dropped/recreated routines, dynamic SQL, row-level data ownership, grants and runtime call paths require separate checks. All 397 migration payloads remain unexecuted.

## Security PR current state
PR #108 (`security/issued-document-rls-fix-2026-10-17`) is open, draft, mergeable, and has no recorded reviews. Its current head is `018af841733e094a634955b199ac590bac9f95ff`; the dedicated RLS regression, SchoolPro CI, and payment-page validation all passed on that head. This is a tested proposal, not production approval. Real Supabase Storage API/signed URL and app endpoint checks remain open.

## Per-object storage ownership register
The new [SchoolPro storage object ownership register](SCHOOLPRO-STORAGE-OBJECT-OWNERSHIP-REGISTER-2026-10-17.md) enumerates all 105 objects in relevant SchoolPro/result-template buckets and matches exact object paths against 25 known database path columns. 91 objects have an exact path plus expected-bucket reference and 14 have none in the checked columns after adding demo-request paths, template JSON image paths and signature paths. 97 objects have NULL Storage owner metadata (not automatically a defect), 2 demo-document objects use profile-ID path prefixes, and 2 document-template objects have prefixes that do not match a known school ID or profile. All 83 document outputs and the single result output have exact database references. Unreferenced result templates, demo documents, document templates and invoice templates remain excluded from automatic export until manually classified. Empty admissions, payment-receipt and branding buckets remain untested for real upload behavior.

## Authenticated result-output object access and deployed Edge Function alignment — 2026-10-17
Read-only transaction-scoped `authenticated` probes (each rolled back) checked the one existing object referenced by `schoolpro_generated_result_outputs`:
- Same-school exam officer: **1 visible object**.
- Same-school teacher with no subject assignment: **0 visible objects**.
- Teacher from another school: **0 visible objects**.
- The linked student identity: **0 visible objects**, consistent with `schoolpro_can_view_result_output(student_id, term, session)=false` for this current record (result not released); this is not evidence of an unintended denial for a released result.
These are SQL RLS checks, not actual Storage API download tests.

A separate high-priority compatibility finding: the only current `schoolpro_generated_result_outputs.storage_path` points to an object in bucket `schoolpro-result-outputs`, but the deployed `schoolpro-render-result` function writes generated PDFs to `school-result-templates`, and `schoolpro-result-access` attempts to create signed URLs from `school-result-templates`. The existing path was not found in that bucket. This suggests the deployed writer/accessor bucket and the stored output object's bucket are out of sync; signed retrieval for this row is likely to fail. In addition, `school-result-templates` has a broad `School users download result templates` policy based on school membership, which is suitable for template access but would be too broad for generated student-result outputs if those continue to be written into the same bucket. Do not change the production Edge Functions or bucket policies during this audit; resolve by restoring the exact deployed source into version control, choosing one canonical output bucket, and testing student/guardian/reviewer/unassigned-teacher/cross-school access through the real Storage API and signed-URL path.


## Storage-reference audit correction — 2026-10-17
The first per-object pass used 25 path columns and did not include `schoolpro_demo_requests.calendar_path/letter_path`, JSON image paths in `schoolpro_document_templates.settings`, or result-term signature paths. The register was regenerated with bucket-aware matching across the additional fields. Corrected totals: 105 objects; 91 have an exact path reference in the expected bucket; 14 have no exact expected-bucket reference; 1 path has a reference that expects a different bucket; 97 have NULL Storage owner metadata. The two demo-document objects are now correctly matched to their demo-request rows. The invoice-bucket v2 logo is **not** counted as referenced by the document-template JSON path because that reference expects the document-template bucket.
