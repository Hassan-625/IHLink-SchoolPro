# Issued-document RLS correction — review and adversarial test plan (2026-10-17)

## Status
- The SQL draft is in separate [draft PR #108](https://github.com/Hassan-625/IHLink-SchoolPro/pull/108), branch `security/issued-document-rls-fix-2026-10-17`. This audit copy remains on the migration branch as supporting evidence only.
- No production DDL or policy change was executed.
- The existing live policy `students read own issued documents` contains the tautology `st.school_id = st.school_id`.
- Proposed predicate replaces it with `st.school_id = schoolpro_document_issues.school_id` while preserving issued/revoked status and authenticated student ownership checks.
- Existing read-only row audit: 141 document issues; 0 orphan student references, 0 null student references, 0 student/issue school mismatches; 141 template references, 0 orphan template references, 0 null template references, 0 school mismatches. This does not prove policy behavior.

## Required approval and preconditions
1. Review the proposed policy against all current permissive and restrictive policies on `schoolpro_document_issues`.
2. Verify the current student portal's identity mapping: `schoolpro_students.user_id = auth.uid()`.
3. Run in a disposable Supabase/Postgres rehearsal seeded with two schools, one student identity per school, and issued/revoked/draft documents.
4. Confirm the test role has no table-owner, BYPASSRLS, service-role, or superuser privileges.
5. Obtain explicit production rollout approval only after all negative tests pass; this draft is not authorization to apply it.

## Required adversarial tests
- Student A can select only issued/revoked issues where the linked student has both `user_id = A` and the same `school_id` as the issue.
- Student A cannot select Student B's issued or revoked documents, even if a fixture deliberately creates a mismatched issue/student school pair.
- Student A cannot select draft documents for self or another student.
- Anonymous role cannot select the rows through this policy.
- A student with a null `student_id` receives no row through this policy.
- Existing staff/guardian policies retain their intended independent access; evaluate the full permissive-policy OR semantics rather than testing this policy in isolation.
- Test direct PostgREST select plus any RPC/view/document-download path that can expose the same issued document.
- Storage object access for any `output_storage_path` must independently deny cross-school access; database RLS alone is insufficient.

## Current read-only storage evidence
Storage buckets observed: `schoolpro-document-outputs` (83 objects), `schoolpro-document-templates` (9), `schoolpro-demo-documents` (2), `schoolpro-result-outputs` (1), `school-result-templates` (8), and `schoolpro-admissions` (0). These counts are not proof of object ownership. A naive UUID-prefix scan is only a heuristic; bucket policy definitions and each database storage path must be correlated exactly before clearance.

## Gate
**Not approved for production.** Read-only authenticated probes of existing production data found no cross-school issue/output rows for two sampled student identities and a registrar, and anonymous access returned zero issue/output rows. These probes test current policy only; they do not test the proposed correction with a deliberately mismatched fixture. No production data was changed. A disposable two-school rehearsal is still required for the proposed fix, full policy composition, and write/update/delete/RPC/download tests. Do not use production data mutations to simulate adversarial cases.

## Additional live checks completed after drafting
- `schoolpro_document_issues`: 141 rows; all 141 have a matching student and template, with zero orphan/null references and zero school mismatches.
- `schoolpro_document_issue_events`: 83 rows; zero orphan issue references and zero event/issue school mismatches.
- `schoolpro_academic_documents`: 96 rows; zero orphan student references and zero student/document school mismatches.
- `schoolpro_admission_documents`: 0 rows; this is an empty table, so it provides no positive evidence that admission upload/download ownership works.
- `schoolpro_document_issues.output_storage_path`: 83 non-null paths, all 83 match an object in `schoolpro-document-outputs`; no missing objects or wrong-bucket matches.
- `schoolpro-admission-documents` bucket has 0 objects; `schoolpro-admissions` bucket has 0 objects. Thus no current admission-upload objects could be tested.
- Storage RLS catalog has school-folder scoping for admissions objects and school-scoped output-path reads. This is policy-definition evidence only; no authenticated adversarial object read/upload/delete test was run.
- A second repository (`Hassan-625/IHLink_Design_System_1`) has 139 migration files, but none of the 35 exact marker version timestamps is present in that branch tree. It is a divergent history, not recovery of those 35 original SQL files.

- Additional path-prefix audit: all 83 linked document-output objects have first path segment equal to the corresponding issue `school_id`; 0 prefix mismatches.
- Document template table: 3 rows, all 3 have a matching object in `schoolpro-document-templates`, with 0 missing objects and 0 school-prefix mismatches. This does not account for other unreferenced objects in that bucket (9 total objects), which still need classification.

## Read-only authenticated two-identity production probe — 2026-10-17
A transaction-scoped probe used `SET LOCAL ROLE authenticated` and a transaction-local `request.jwt.claim.sub` for two existing student identities from different schools. Each transaction ended with `ROLLBACK`; no data was changed.
- Identity in school `7a340a27-9184-420a-b566-8fc0d3dac555`: 0 visible `schoolpro_document_issues` rows and 0 visible `schoolpro-document-outputs` objects.
- Identity in school `d342eb87-8d6a-477a-a380-7fab83f586b7`: 1 visible issue row and 1 visible `schoolpro-document-outputs` object; 0 visible issue rows from another school and 0 visible output objects with another school's first path segment.
- This is useful current-policy negative-read evidence for the sampled identities, not full acceptance: the test data contains zero issue/student school mismatches, so it does not exercise the tautology with a deliberately mismatched fixture. It also does not test write/update/delete, guardian/member roles, RPC/view paths, or the proposed policy before application. No production data was changed.

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

## Additional authenticated storage and anonymous probes — 2026-10-17
All tests below were read-only and transaction-scoped; each transaction was rolled back:
- Anonymous role: 0 visible `schoolpro_document_issues` rows and 0 visible `schoolpro-document-outputs` objects.
- A school registrar in school `d342eb87-8d6a-477a-a380-7fab83f586b7`: 141 visible document issues for that school and 0 for the other sampled school; 83 visible document-output objects and 0 objects with the other school's path prefix.
- A proprietor in that same school: 7 visible objects in `schoolpro-document-templates`, all with the proprietor's own school prefix and 0 with the other school's prefix; 2 visible `schoolpro-invoice-templates` objects, both own-school prefix; 8 visible `school-result-templates` objects, all own-school prefix and 0 other-school prefix.
- The same registrar had 0 visible objects in `schoolpro-document-templates`, consistent with the manager-only read policy for that bucket.
- These sampled reads support current-policy school scoping for the tested roles/buckets. They do not test upload/update/delete, object-key tampering, direct signed/public URL exposure, or the proposed issued-document policy on a deliberately mismatched fixture. The two document-output buckets have existing data; the admissions/payment-receipt buckets are empty and remain untested on actual objects.
