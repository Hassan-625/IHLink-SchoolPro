# SchoolPro audit batch 7 — deployed source restoration and result-output bucket correction draft — 2026-10-17

## Safety / disposition

No production SQL, Storage object, bucket, policy, Edge Function deployment, Render configuration, merge, export/import or cutover was changed. Two repository source files were restored byte-for-byte from the active deployed function payload first, then a separate follow-up source commit changed only the result-PDF output upload/signing bucket references. The repository commit history preserves the restoration baseline separately from the proposed fix. The changed source is not deployed and has not passed disposable Storage API tests; treat it as a candidate fix, not production resolution.

## Authoritative deployed source recovered to GitHub

Read-only `get_edge_function` retrieval provided the deployed entrypoint source and metadata. Missing source paths were restored on branch `migration/mysql-schoolpro-foundation`:

| Function | Deployed version | Deployed bundle SHA-256 | Source restoration commit | Source path |
|---|---:|---|---|---|
| `schoolpro-render-result` | 6 | `f87b6ad094270eabef3d5f2919e5c9acffb7e911059c28b057068be265542461` | `aa1cc43b54896ea75b53554983222869b58669e3` | `supabase/functions/schoolpro-render-result/index.ts` |
| `schoolpro-result-access` | 1 | `4b45e20029d5cd7fa5f334972fee39eebe2bb0c55c4b989175053d326f36ce9a` | `45073a3b0236a77b72910101601ec511d8156703` | `supabase/functions/schoolpro-result-access/index.ts` |
| `schoolpro-owner-access` | 3 | `7446cdf3322e265ff8ca90536752f24333e728245e7a4504a5af78dc60dfa802` | `da2fc86f000dfd833786c0b8be97f6bdb796bb32` | `supabase/functions/schoolpro-owner-access/index.ts` |
| `auth-handoff` | 12 | `8506d14262c74515d7b7d13b307a30bfa92dce86cb38546df115b1e6ddd95582` | `99a3ff19ab39614fb14017e6fb66fd7db88f1939` | `supabase/functions/auth-handoff/index.ts` |

The hashes above are Supabase's deployed bundle hashes, not independently recalculated hashes of the repository text file. They identify the deployed versions to compare against. The exact deployed source snapshot is represented by the restoration commits; the two result functions then receive a deliberate candidate patch in later commits.

The document-renderer source at `supabase/functions/schoolpro-render-document/index.ts` was already present and matched the retrieved deployed entrypoint during the prior batch. Do not infer that all Edge Functions have been reconciled; this is targeted restoration.

## Result output bucket mismatch — catalog evidence and source correction draft

Current bucket inventory confirms both private buckets exist:
- `school-result-templates`: private, 5 MiB limit, MIME allowlist for XLSX/octet-stream.
- `schoolpro-result-outputs`: private, 15 MiB limit, MIME allowlist for PDF/XLSX.

The current Storage policy catalog assigns template/media upload/download and family report-media access to `school-result-templates`; generated result-output insert/read/update/delete policies explicitly target `schoolpro-result-outputs`. The generated-output read policy joins `schoolpro_generated_result_outputs` to `schoolpro_students` and authorizes platform admin, permitted school roles, the student, active guardian link, or eligible subject teacher. The generated-output upload policy additionally checks school membership and the `results` module.

The one current `schoolpro_generated_result_outputs` record has a storage path ending in `.xlsx`; a read-only exact-object check found that path in `schoolpro-result-outputs`, not `school-result-templates`. This is consistent with the output-bucket policy model, but the single row does not prove all existing output objects are correctly located.

Deployed result-renderer v6 used `school-result-templates` for three distinct operations: template/media download, generated PDF upload, and generated PDF signing. Deployed result-access v1 signed stored output paths from `school-result-templates`. This is internally inconsistent with the output policies and observed output record.

Candidate source correction committed separately:
- Renderer keeps media/template downloads on `school-result-templates`, but uploads generated PDFs and signs the new output using `schoolpro-result-outputs`.
- Result-access signs generated output using `schoolpro-result-outputs`.

Candidate patch commits:
- Renderer bucket alignment: `ea42d7ebdd9c137e3a66e946877f2dd22b764b55`.
- Result-access bucket alignment: `7f826188a786867c125aefc71d81d5b9b93252d9`.

These changes are source-only. Before approving them, validate in a disposable Supabase project that output uploads satisfy Storage RLS and size/MIME constraints; output-row upsert and bucket path align; a signed URL is returned for the exact object; a different tenant cannot download/sign it; and revoked/unpublished output is denied. Also check existing PDF objects currently under `school-result-templates` and decide whether they need a controlled migration later. No object was moved or deleted.

## Role inheritance and ACL note

A corrected `pg_auth_members` traversal found no membership-inheritance edges originating from `anon`, `authenticated`, or `service_role` in the current catalog. Effective privileges should therefore continue to be recorded per these concrete roles using `has_function_privilege`, `has_table_privilege`, and `has_schema_privilege`, plus object ownership and BYPASSRLS/owner context. Do not assume a role inherits a grant merely because it is a Supabase API role. This result does not cover all platform roles or PostgreSQL's owner/superuser semantics.

## Remaining gates

1. Finish the 236 heuristic routine body/overload signals by exact schema + identity-argument signature, later successor migration, definition semantics, owner, SECURITY DEFINER, fixed search_path, effective ACL, and executable test case.
2. Generate and check in the complete 397-version per-object/action matrix. This requires each recovered payload plus later actions; current catalog snapshots alone cannot reconstruct the historical timeline.
3. Complete historical trigger attach/drop/replace reconciliation, not just current 160-row trigger inventory.
4. Reconcile each of seven cron jobs to schedule/unschedule transitions and command/function body evolution; `datasub-provider-health-5m` provenance remains unresolved.
5. Run disposable, cross-tenant API/RPC/Storage tests. No adversarial tests were run in production or claimed passed.
6. Compare deployed function source snapshots with branch files and candidate patches; verify imports, generated response shape, JWT mode and secrets handling before considering deployment. No deployment is authorized.
7. No production SQL/Storage change, Edge Function deploy, merge, data export/import, or cutover is authorized by this report.
