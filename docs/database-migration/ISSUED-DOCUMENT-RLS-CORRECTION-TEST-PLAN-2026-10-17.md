# Issued-document RLS correction — review and adversarial test plan (2026-10-17)

## Status
- Draft SQL is committed on `migration/mysql-schoolpro-foundation` only.
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
**Not approved for production.** No cross-tenant authenticated negative test has yet been executed because the current tools do not provide a safe authenticated two-user test harness against production, and no disposable rehearsal has been proven available in this run. Do not use production data mutations to simulate adversarial cases.

## Additional live checks completed after drafting
- `schoolpro_document_issues`: 141 rows; all 141 have a matching student and template, with zero orphan/null references and zero school mismatches.
- `schoolpro_document_issue_events`: 83 rows; zero orphan issue references and zero event/issue school mismatches.
- `schoolpro_academic_documents`: 96 rows; zero orphan student references and zero student/document school mismatches.
- `schoolpro_admission_documents`: 0 rows; this is an empty table, so it provides no positive evidence that admission upload/download ownership works.
- `schoolpro_document_issues.output_storage_path`: 83 non-null paths, all 83 match an object in `schoolpro-document-outputs`; no missing objects or wrong-bucket matches.
- `schoolpro-admission-documents` bucket has 0 objects; `schoolpro-admissions` bucket has 0 objects. Thus no current admission-upload objects could be tested.
- Storage RLS catalog has school-folder scoping for admissions objects and school-scoped output-path reads. This is policy-definition evidence only; no authenticated adversarial object read/upload/delete test was run.
- A second repository (`Hassan-625/IHLink_Design_System_1`) has 139 migration files, but none of the 35 exact marker version timestamps is present in that branch tree. It is a divergent history, not recovery of those 35 original SQL files.
