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


## Continuation update — source recovery and exact frontend revision check (2026-10-17)

### Five missing deployed Edge Function sources recovered as forensic snapshots

The live Supabase Edge Function source endpoint returned these currently deployed versions. Exact returned source files have now been committed under [recovered-deployed-edge-functions-2026-10-17](recovered-deployed-edge-functions-2026-10-17/README.md), deliberately under `docs/database-migration/` rather than `supabase/functions/` so they cannot be mistaken for approved deployment candidates:

| Function | Deployed version | `verify_jwt` | Supabase-reported source SHA-256 |
|---|---:|---|---|
| `schoolpro-owner-access` | 3 | true | `7446cdf3322e265ff8ca90536752f24333e728245e7a4504a5af78dc60dfa802` |
| `auth-handoff` | 12 | false (function manually validates bearer/session) | `8506d14262c74515d7b7d13b307a30bfa92dce86cb38546df115b1e6ddd95582` |
| `schoolpro-transfer-ownership` | 1 | true | `8b075a7706217a7aabd72862c2445fc3e43db26a7089bdad325e56b3cd0d442b` |
| `schoolpro-render-result` | 6 | true | `f87b6ad094270eabef3d5f2919e5c9acffb7e911059c28b057068be265542461` |
| `schoolpro-result-access` | 1 | true | `4b45e20029d5cd7fa5f334972fee39eebe2bb0c55c4b989175053d326f36ce9a` |

Snapshot commits: `68ad598db93b06b4901de7bf7199e3c2cf7d70e7`, `fc00f7a3a48c5888220c0b977c3d5be9c77814d7`, `dab69a96dc45fe3e8e4ac377e47b65e3016c03dc`, `c41402ed9f75f12403e9516286bc2fd1707282a7`, `467ac36a644fa352971e49adcbe950e56685eecd`; snapshot index/readme commit `1e34c9b0795b9dcc81d61a81926212a6838e3a94`. These are recoveries only, not deploys or source approval.

### Exact deployed frontend commit comparison

At Render's recorded frontend commit `29856dff17ea8a3bc8bb31b7900967b7df9d316b`, GitHub returned the same blob SHA/content for each of the following files at that commit, `main`, and `migration/mysql-schoolpro-foundation`:

- `src/pages/schoolpro/SchoolProDocumentStudio.tsx` — `53646266fd4aea9bdf2370f48ddfbe9581249f48`
- `src/pages/schoolpro/SchoolProInvoiceStudio.tsx` — `6570c11dc9dde1319dfa89b19cc458f9dbe9bfaf`
- `src/pages/schoolpro/SchoolProBrandingSettings.tsx` — `d8f74a722d53bead9aeeef2ab8950445a08022a7`
- `src/pages/schoolpro/SchoolProResultTemplates.tsx` — `9d148eb22ad96d4ab6c633553bf998d61d0d8027`

This establishes file-level parity for these four relevant frontend call sites at the recorded commit, not parity of the full built artifact, runtime environment, or all application files.

### Deployed Edge Function vs repository source comparison

Live Supabase source retrieval compared with GitHub `main` found:

- `invite-school-staff` v16: **drift**; deployed source 10,305 chars vs repository source 9,416 chars.
- `schoolpro-render-document` v14: **drift**; deployed source 9,084 chars vs repository source 9,085 chars.
- `schoolpro-student-login` v3: **exact source match**; 5,953 chars.
- `schoolpro-account-login` v2: **exact source match**; 4,693 chars.
- `schoolpro-email-worker` v10: the deployed source was retrieved under file name `schoolpro-email-worker/index.ts`; the prior comparison did not match the filename when extracting the content, so its equality check is **not yet valid** and must be rerun using that exact nested path.

This confirms two known drifts and two exact matches, with the email-worker parity item still unverified. Source drift needs a line-level diff and dependency/config comparison before source restoration. The five recovered snapshots above address missing *source availability* only; they do not yet restore canonical source paths or establish a reviewed target implementation.

### Storage/output authorization remains untested end-to-end

The live `schoolpro-render-result` v6 and `schoolpro-result-access` v1 snapshots use bucket `school-result-templates`; frontend result-template/output code references `school-result-templates` for templates and `schoolpro-result-outputs` for generated outputs. The result-access function signs the recorded output path against `school-result-templates`. Do not change bucket names or move objects based only on code inspection. Required evidence is a two-school adversarial test through the actual Storage API, including expected and unexpected bucket/path combinations, owner vs unrelated school user, issued-result authorization, signed URL creation, download, and expiry. No such live API/signed-URL test was performed in this continuation.

### Gates unchanged

- **397-version semantic reconciliation:** still open; this update does not claim full function-body/overload, RLS policy, grant, trigger, cron-job or dependency parity for all versions.
- **18 no-direct-school-id tables:** live counts and proposed dispositions are documented, but the identity/payment/security exceptions still need final target ownership and retention/bridge decisions.
- **79 cross-boundary FKs:** all 79 are validated in the source catalog; this is referential integrity only, not tenant authorization. Exact target schema reconciliation and negative tenant tests remain open.
- **Migration/cutover:** blocked. No SQL replay, export/import, Aiven writes, Render configuration change/deployment, merge, or cutover occurred.


### Target ownership and FK target mapping added

Two additional committed decision registers make the target dispositions explicit without treating them as cutover approval:

- [18-table target ownership disposition register](SCHOOLPRO-TARGET-OWNERSHIP-DISPOSITION-2026-10-17.md) — commit `af65f673e91262ac2966a57f74cf8a8c00b4af7b`. Every no-direct-`school_id` table now has a target disposition category and an ownership/validation rule. The 27,440 assignment submissions, 2,800 CBT answers, 280 CBT attempts and 504 fee items require tenant-filtered reconciliation; transient credential challenges are excluded; plan/subscription catalogs require reviewed seeds; login telemetry is excluded by default.
- [79-FK target-schema disposition](SCHOOLPRO-FK-TARGET-SCHEMA-DISPOSITION-2026-10-17.md) — commit `1d2fce24d13fd0bbc0d2e1737ae829ddc31835af`. Exact target distribution from the 79-row source register is 52 references to `auth.users`, 21 to `profiles`, 3 to `virtual_accounts`, 2 inbound references to `schoolpro_schools`, and 1 reference to `schoolpro_payment_intents`. These relationships cannot all remain physical FKs if identity/payment/email/clock services stay in Supabase. The register specifies the external-identity and idempotent-adapter disposition; exact target DDL and adversarial tenant tests remain open.

### Additional ledger-level catalog baseline

A read-only query against `supabase_migrations.schema_migrations` confirmed 476 total ledger rows and counted version payloads mentioning these SQL constructs: functions 301, policies 202, grants/revokes 289, triggers 78, schedule/cron 22. These are **overlapping category counts across all 476 ledger versions**, not semantic pass counts for the 397 live-only versions. They establish the scale of the remaining definition-level audit and are not a substitute for comparing overload signatures/bodies, effective grants, policy expressions, trigger wiring or active job commands.

### Immediate remaining work

1. Build and preserve a version-by-version semantic matrix for all 397 live-only SQL payloads, distinguishing exact, changed/superseded, absent, dropped, and unresolved definitions. Include function identity signatures and bodies, RLS policy expressions, effective grants/revokes, trigger-to-function wiring, cron command/schedule, and dependencies. Do not replay historical SQL.
2. Reconcile every target-internal FK action/column tuple and nullable data relationship against the proposed Aiven schema; then run tenant-authorization tests separately from FK/orphan checks.
3. Finish line-level diffs for `invite-school-staff` v16 and `schoolpro-render-document` v14; rerun `schoolpro-email-worker` v10 parity using its actual deployed nested filename; compare deployed source with callers and environment configuration.
4. Execute approved two-school Storage API/signed-URL adversarial tests for the result-output bucket mismatch. Do not mutate bucket names, objects, or production function versions before evidence and review.


### Edge Function source comparison corrected after exact diff

The detailed [Edge Function source parity report](SCHOOLPRO-EDGE-FUNCTION-SOURCE-PARITY-2026-10-17.md) (commit `ea300ca9ed345fa5c6e8315d4732184480b045de`) refines the earlier preliminary comparison:

- `invite-school-staff` v16 has an actual source diff, but the inspected changes are request/stage diagnostics and sanitized error logging/response correlation; no changed authorization/data-operation expression was identified in the diff. This still needs full security review, not an automatic “safe” conclusion.
- `schoolpro-render-document` v14 differs only by one trailing newline; normalized source is identical. This is not a behavioral drift.
- `schoolpro-email-worker` v10 is now confirmed exact after using its actual deployed nested file name.
- `schoolpro-student-login` v3 and `schoolpro-account-login` v2 are exact matches.

Thus, among these five functions there is one instrumentation-only source difference and four source matches after whitespace normalization; deployment config/runtime parity remains unverified.


### 397-version SQL semantic triage batch 1

The new [semantic triage report](LIVE-ONLY-MIGRATION-SEMANTIC-TRIAGE-BATCH-1-2026-10-17.md) (commit `78f6e91f6b8487f3a21f971bb0f73de69e77d194`) ran a catalog-oriented pass over the exact 397 versions in the recovered SQL dependency register. It found 504 parsed function declarations across 240 versions; 263 had a current function body substring match, 236 had a current overload name but no such match, and five names were absent. It also counted 144 parsed policy declarations, 43 trigger declarations, 256 versions containing GRANT/REVOKE, and five versions containing cron scheduling calls. These are **triage signals only**, not semantic pass counts; dynamic SQL and overloads make the basic parser incomplete.

A direct comparison of `20261013181250 secure_schoolpro_ownership_transfer` found a material live evolution: current `schoolpro_transfer_ownership(uuid,uuid)` upserts `schoolpro_leadership_settings`, while the recovered version only updates an existing row. Live ACL additionally permits `service_role` execution while denying `anon`; the recovered payload explicitly grants `authenticated` and revokes `PUBLIC/anon`. That later grant and the function's `SECURITY DEFINER` behavior need provenance review. No DDL or grants were changed.

This is progress across the whole 397-version set, but it **does not close task 1**: every unresolved function overload/body, policy expression, effective grant, trigger wiring and cron command still needs a version-specific disposition. The parser's dynamic-policy/trigger false positives are not treated as actual missing objects.


### Separate live tenant-authorization test evidence

The [read-only two-school RLS test report](SCHOOLPRO-TENANT-AUTHORIZATION-READ-ONLY-TESTS-2026-10-17.md) (commit `96fe190bf93107e6a672a08f5893a6dae4c34fbb`) tested SELECT behavior as `authenticated` for two school proprietors in a rolled-back, read-only context. Both identities saw their own school root and zero rows from the other school for the tested root/student/result/invoice queries. Targeted sample-row checks also returned one visible row for the IH Academy owner and zero for the HASSAN ACADEMY owner across assignment submissions, CBT attempts, CBT answers and fee items.

This is distinct from the 79 validated foreign keys and therefore provides actual, limited source-side authorization evidence. It remains a **partial** test: no writes were attempted, no broad role matrix was tested, and no Aiven trusted-API tenant tests have run. A wide aggregate child-table join timed out while evaluating `is_admin` / `schoolpro_can_read_student`; targeted row checks completed. Record this as an RLS query-performance signal, not as proof of disclosure.
