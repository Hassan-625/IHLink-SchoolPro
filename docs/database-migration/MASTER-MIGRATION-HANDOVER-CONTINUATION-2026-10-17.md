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


### Scheduled-job reconciliation batch

The [scheduled-job semantic review](LIVE-ONLY-MIGRATION-CRON-SEMANTIC-REVIEW-2026-10-17.md) (commit `18b49bcba3a1b45959e96ede43204778515464ed`) compared all seven current `cron.job` rows to the live migration ledger. Six jobs match a specific version by name, schedule and command text, including both active SchoolPro jobs. The active `datasub-provider-health-5m` job has no matching job-name source in the 476 ledger payloads; its provenance remains unresolved. This is an out-of-band/provenance blocker, not evidence that the job is malfunctioning. The expiry function body has evolved, so the matching schedule source does not authorize replay of the historical function SQL.


### Effective anonymous RPC grants: high-priority security gate

The [anonymous SECURITY DEFINER RPC review](SCHOOLPRO-ANON-SECURITY-DEFINER-RPC-GRANT-REVIEW-2026-10-17.md) (commit `38415c1a7d2fbe279e4e35e224b795a96d284650`) identified six live public SchoolPro `SECURITY DEFINER` RPCs with `anon` EXECUTE: result PIN checking, result-code verification, public admissions submission, document verification, admission-offer retrieval and offer acceptance.

Highest priority is `check_schoolpro_result_pin(text,text,text,text)`: it accepts anonymous RPC calls, has no in-body failed-attempt throttle, and the PIN table has no attempt-count/lockout column. A frontend-only throttle would be bypassable by direct PostgREST RPC calls. The ledger explicitly granted anon execution in `20260924144655 harden_rpc_and_customer_platform_access`. Result-code verification also returns the stored snapshot for valid codes and needs field minimization, entropy and enumeration/rate-limit review. Public admission/document flows require abuse-control review as well.

No grants or functions were changed. This is a current security blocker to reproduce the same public RPC surface in the target; remediation should use a trusted, rate-limited endpoint and avoid unverified client-supplied IP-based database identity.


A follow-up read-only count found zero rows in `schoolpro_result_verifications` and zero rows in `schoolpro_result_access_pins`. No current result snapshot/PIN data was exposed during this review; the concern is a latent public endpoint/grant design risk before these tables are populated, not evidence of exploitation.


### Semantic comparison batch 2 — five missing routines resolved

The new [semantic triage batch 2 report](LIVE-ONLY-MIGRATION-SEMANTIC-TRIAGE-BATCH-2-2026-10-17.md) (commit `87a1b20f704474a59f3f16ff9589295fa2ea3661`) traces all five function declarations previously absent by current routine name to explicit later DROP migrations. These are intentionally retired legacy DataSub payment/provider routines, two retired Academy order finalizers, and the superseded SchoolPro demo-window validator. None should be restored into Aiven merely to mirror a historical SQL payload.

The ownership-transfer RPC's live body matches its later successor `20261013184713 schoolpro_ownership_transfer_upsert_leadership_title`; the UPSERT difference is a versioned evolution, not unresolved drift. The RLS review also traces the SchoolPro module policy family through later role-specific replacements and records that `private.schoolpro_module_allowed` is a module gate, not a tenant-ownership predicate on its own.

This resolves the five missing-name triage cases. It does **not** close the 236 function body/overload mismatches, full effective RLS expression matrix, all ACL/default-privilege changes, trigger wiring, or historical cron transitions. Literal expression-substring matches are not accepted as semantic proofs because PostgreSQL deparses expressions and policies are subsequently altered/replaced.


### Semantic comparison batch 3 — school fee receipt path trust boundary

The [payment RPC and effective RLS review](LIVE-ONLY-MIGRATION-SEMANTIC-TRIAGE-BATCH-3-2026-10-17.md) (commit `0a2c9bb44a10043a703c965f13d718a7437c9f09`) compared the current `submit_schoolpro_payment` body with its recovered declaration and inspected effective policies on payment submissions, allocations and invoices. The function body matches the recovered SQL, and its current EXECUTE grants exclude `anon`; however, it stores client-provided `receipt_path` and `receipt_mime` without verifying bucket, object existence, school/caller path ownership or actual object metadata. The INSERT RLS policy validates the guardian/school relationship but does not validate Storage object ownership. The target must add trusted Storage-path/object validation; do not carry the current trust boundary forward unchanged.

A read-only count found zero rows in `schoolpro_payment_submissions`, so this is a latent flaw in the RPC contract, not evidence of an accepted cross-school receipt. The required adversarial cases are specified in the report and must run in a disposable environment through the actual Storage API.


**Correction to batch 2 RLS note (commit `0ea6a73227880bfda18b816fb89a2fcead794451`):** a direct read of the current `private.schoolpro_module_allowed(uuid,text)` definition confirms that the old `20260929203846` implementation was superseded by `20261008152205 schoolpro_plan_access`. The live function does not use the older final `ELSE true` as its overall return path; it requires an authenticated non-null UID, active account, operational school, requested permission from `schoolpro_user_permissions`, and relevant plan feature gates. It remains a module/plan helper, not a substitute for every row-level ownership predicate. The batch 2 report now explicitly corrects this distinction.


### Effective anonymous function ACL inventory expanded

The [anonymous entry-point ACL report](LIVE-FUNCTION-ACL-ANONYMOUS-ENTRYPOINT-REVIEW-2026-10-17.md) (commit `6f944d20f4eb8511c69ff9028d6dd2711f9cc309`) records all 11 public-schema functions currently executable by `anon`, not only the six SchoolPro admission/result/document RPCs. Three additional SECURITY DEFINER endpoints provide candidate-CBT bearer-token access/read/write/submit; their bodies validate attempt token, state, question membership and deadlines, but token entropy/leakage, request throttling and concurrency/replay still require dedicated tests. Two other anon-executable functions are a pure result-comment helper and a trigger function, which are not equivalent to callable public business endpoints.

The catalog also reports 29 `private` functions with anon EXECUTE at the function ACL level, but `anon` lacks `USAGE` on schema `private`; these are not ordinarily directly addressable via anon PostgREST calls. This is a current ACL baseline, not the version-by-version GRANT/REVOKE matrix. Do not copy function ACLs or default privileges into the target without reconciling schema reachability, trigger wiring and the trusted service boundary.


### Semantic comparison batch 4 — class-result submission policy chain

The [class-result policy comparison](LIVE-ONLY-MIGRATION-SEMANTIC-TRIAGE-BATCH-4-2026-10-17.md) (commit `5407bd54989849475c41f9d34c7cac38f161fa06`) compared the current `schoolpro_class_result_submissions` policy and two result RPCs to the exact ledger versions. The original policy used an ambiguous unqualified `school_id`; `20261013130652` explicitly recreates it with `m.school_id = schoolpro_class_result_submissions.school_id`, and the live catalog confirms the corrected correlation. `20261013130436` also revokes anon/PUBLIC execution on the class-submission RPC, granting authenticated/service_role; the current body checks class-school match, leadership/form-teacher permission, eligible unlocked drafts and school/period fingerprint. The schoolwide publish RPC matches its later ledger body and only publishes matching approved, unlocked rows.

Cross-school class IDs, wrong periods, unauthorized teachers, repeat/concurrent submission and direct-anon denial still require execution tests in a disposable environment.


### Semantic audit batch 5 — effective RLS and ACL baseline

Committed [effective policy and ACL matrix baseline](LIVE-ONLY-MIGRATION-EFFECTIVE-POLICY-ACL-MATRIX-BATCH-5-2026-10-17.md) (commit `d2e5e6d88d4111cc9ea5c4528d72b2320048555f`). Read-only production catalog checks confirm 107/107 SchoolPro tables have RLS enabled, with 293 current policies (243 permissive, 50 restrictive); 120 SELECT, 31 INSERT, 26 UPDATE, 19 DELETE and 97 ALL policy rows. Seven policies target anon and 290 target authenticated. These are current catalog counts, not proof that each table's combined policy predicates enforce tenant isolation.

The effective routine privilege query used `has_function_privilege`, not only raw ACL strings: 369 routines across public/private, 302 SECURITY DEFINER; effective EXECUTE counts are public 11 anon / 187 authenticated / 234 service_role and private 29 anon / 80 authenticated / 41 service_role. The private-schema anon EXECUTE count must be read together with the recorded absence of anon USAGE on schema private; function-level EXECUTE does not by itself make these directly reachable through PostgREST. Public anon-executable routines remain a targeted security gate. No production SQL was changed.

**Status remains partial:** the 236 function body/overload mismatch count is a heuristic backlog, not 236 proven defects and not 236 resolved cases. The new report defines the required per-version, per-object/action matrix fields for all 397 versions and carries forward the already-resolved drops, ownership-transfer successor, module-access successor, receipt-path trust defect and class-result policy correction. Signature-aware body comparison and the full historical/effective policy/ACL matrix remain open; no export/import, replay, merge or cutover is authorized.


### Semantic audit batch 6 — trigger wiring, cron, default ACL and deployed Edge Function parity

Committed [Batch 6 trigger/cron/default ACL/Edge parity report](SCHOOLPRO-TRIGGERS-CRON-DEFAULT-ACL-EDGE-PARITY-BATCH-6-2026-10-17.md) (commit `6cb7e98ce7dff23937eb3c85de20e8c39ec9f3ef`). Production remained read-only. Live catalog count is 160 non-internal triggers associated with SchoolPro tables/functions; 141 invoke SECURITY DEFINER functions, 156 point into `private`, four into `public`. The live cron inventory has seven active jobs, including SchoolPro academic-clock refresh and daily subscription-expiry/grace. `datasub-provider-health-5m` provenance remains unresolved against the recovered ledger.

Fresh schema privilege checks confirm `anon` has no USAGE on `private`, while authenticated does. `pg_default_acl` shows broad explicit defaults for postgres-owned public/storage sequences, functions and relations (including anon/authenticated/service_role) plus Supabase platform-owner defaults in other schemas. These must be normalized and deliberately redesigned for a least-privilege target; do not blindly clone platform defaults.

Deployed Edge metadata/source was retrieved for result render/access, document render, owner access, auth handoff and staff invitation. Result renderer v6 and result-access v1 use `school-result-templates`; the frontend/output policy inventory uses `schoolpro-result-outputs`, so the mismatch remains open. The deployed document-renderer entrypoint matches the inspected branch source; result-renderer and result-access source paths return 404 on the inspected branch and need restoration/parity evidence. No deployed function was changed.

**Adversarial tests remain NOT RUN / BLOCKING**, not passed: this batch did not use production to send abusive requests. The report enumerates required disposable-fixture cases for result PIN/code, admissions, CBT, payment receipt ownership and signed result-output access. The 397-version routine/policy/ACL semantic matrix remains incomplete; no replay, export/import, merge or cutover is authorized.


### Semantic audit batch 7 — deployed source restoration and result bucket correction draft

Committed [Batch 7 Edge source restoration / bucket correction report](SCHOOLPRO-EDGE-SOURCE-RESTORATION-RESULT-BUCKET-CORRECTION-BATCH-7-2026-10-17.md) (commit `726cbd08abb89067565f37d20f687cbd9587749e`). Retrieved active deployed source for `schoolpro-render-result` v6, `schoolpro-result-access` v1, `schoolpro-owner-access` v3 and `auth-handoff` v12 and restored the missing expected source paths on the audit branch. Restoration commits are separately recorded in the report; the listed SHA-256 values are Supabase deployed bundle hashes, not independently recomputed source-file hashes.

Read-only Storage catalog confirms both private buckets exist and that generated-output policies target `schoolpro-result-outputs`, while template/media policies target `school-result-templates`. The one current generated-output row references an object present in outputs but absent from templates. Deployed result-renderer v6 was downloading template media, uploading PDF outputs, and signing outputs all through the templates bucket; result-access v1 also signed outputs from templates. Candidate source commits `ea42d7ebdd9c137e3a66e946877f2dd22b764b55` and `7f826188a786867c125aefc71d81d5b9b93252d9` now keep template/media reads on templates but use outputs bucket for generated PDF upload/signing. **This is not deployed and is not yet accepted as resolved** pending disposable Storage API tests, cross-tenant signed-URL denial, existing PDF inventory, and RLS/metadata validation. No Storage objects or buckets were changed.

A corrected role-membership traversal found no membership inheritance edges originating from `anon`, `authenticated` or `service_role` in the inspected catalog. Effective grants continue to require per-role `has_*_privilege` checks plus ownership and BYPASSRLS/SECURITY DEFINER review.

Remaining blockers unchanged: signature-aware disposition of the 236 heuristic function mismatches; complete historical 397-version per-object/action policy/ACL matrix; trigger and cron transition diff; disposable adversarial RPC/Storage tests; final Edge source parity and candidate patch validation. Production SQL/Storage remains read-only; no Edge deployment, merge, export/import or cutover is authorized.


### Semantic audit batch 8 — signature-aware live routine baseline

Committed [Batch 8 signature-aware routine baseline](SCHOOLPRO-SIGNATURE-AWARE-ROUTINE-BASELINE-BATCH-8-2026-10-17.md) (commit `a700dff89485e200124570db8de4d87755225e92`). Production catalog inventory keyed current routines by schema + identity arguments: 111 current `schoolpro_*` routine signatures in public/private, 111 distinct names and no same-name overload groups in the current live set. This does **not** resolve the historical 236 mismatch heuristic because that set concerns recovered declarations and successor/drop transitions, not merely current overloads. 82 current SchoolPro-prefixed routines are SECURITY DEFINER; 108 of 111 explicitly set empty search_path. Three exceptions are recorded: `public.schoolpro_cbt_is_eligible(uuid,uuid)` and `public.schoolpro_return_library_loan(uuid)` are SECURITY DEFINER with `search_path=public` and unqualified object references; `schoolpro_result_comment(numeric)` is a pure immutable helper with anon EXECUTE, not SECURITY DEFINER. The first two need controlled-search-path review and disposable role/tenant regression tests, not blind production alteration.

The live policy refinement is 293 policies over 101 policy-bearing SchoolPro-prefixed tables (the broader inventory has 107 candidate tables; table existence/RLS and policy-bearing count are separate). Command counts remain 120 SELECT, 31 INSERT, 26 UPDATE, 19 DELETE, 97 ALL. Complete historical per-version policy/ACL matrix and routine timeline remain open.


### Semantic audit batch 9 — Edge parity recheck and adversarial test gate

Committed [Batch 9 parity and adversarial-test gate](SCHOOLPRO-AUDIT-PARITY-AND-ADVERSARIAL-GATE-BATCH-9-2026-10-17.md) (commit `b359752fd945f575237c6dea55f0a8c944436e7d`). Read-only deployed source comparisons verified exact entrypoint text for `schoolpro-owner-access` v3, `auth-handoff` v12, `schoolpro-transfer-ownership` v1, `schoolpro-student-login` v3, `schoolpro-account-login` v2 and `schoolpro-email-worker` v10. `schoolpro-render-document` matches after trimming a trailing newline only. The result renderer/access candidate files match the deployed sources after reversing only the intentional output-bucket substitutions; this validates the bounded text diff, not runtime behavior. `invite-school-staff` v16 still has unresolved source drift (deployed 10,305 chars vs branch 9,416); its deployed snapshot is preserved in commit `583a49605ae4ebde4c633acb1ed7a1feba19ce62`. Missing ownership-transfer source path was restored in commit `269e6719b944b81b2e37f802e45cabe2ad218772`. No Edge function deployed.

Current trigger and cron inventories are confirmed but historical transitions remain open: 160 current relevant non-internal triggers; seven active cron jobs. Full 397-version policy/ACL matrix and 236 historical routine heuristic disposition remain incomplete. Adversarial tests are **NOT RUN**: the only listed Supabase development branch is marked `MIGRATIONS_FAILED`, so it is not a safe test target; a new branch may incur charges and requires explicit cost approval. No production abuse payloads were sent and no production object was changed. Migration/export/import/cutover remains blocked.

### Migration go/no-go gate register — 2026-10-17

Added [SchoolPro migration go/no-go gate register](SCHOOLPRO-MIGRATION-GO-NO-GO-GATE-REGISTER-2026-10-17.md) (commit f6195045dd29750d736f08a8c3162493e1948587). This is an explicit acceptance register for the four requested gates: tenant/role security, source completeness, MySQL destination correctness, and isolated rehearsal/recovery. Current decision remains **NO-GO**. It deliberately distinguishes recovered evidence from passed acceptance tests: 397 SQL payloads recovered does not mean their semantics are reconciled; the 35 marker payloads byte-match the ledger but independent deployment audit evidence is missing; 236 routine mismatches remain heuristic candidates; historical policy/ACL and trigger transitions are incomplete; end-to-end adversarial tests have not run; and the complete MySQL target plus full rehearsal/recovery are not proven.

The only listed Supabase branch remains main with status MIGRATIONS_FAILED. A new disposable branch requires the organization-specific cost quote and explicit user agreement before confirmation/creation. No production SQL, Storage objects/buckets, Edge deployment, Render configuration, merge, export/import, or cutover was changed/performed. Do not treat the gate register as test evidence; each gate requires reproducible evidence before it can be marked PASS.

### Target-platform correction to the gate register — 2026-10-17

The authoritative [Master Database Migration Handover](MASTER-MIGRATION-HANDOVER.md) sets the active target to **Supabase PostgreSQL → Aiven PostgreSQL**, while SchoolPro's frontend remains on Render. The MySQL pilot/PR #107 is paused historical reference only. The new gate register has been corrected accordingly (commit 01ba5ae11912c3be102541447fe19912dc02b151). G3 now requires proof for an Aiven PostgreSQL target, including extensions, roles/grants/RLS, functions, triggers, sequences, scheduled jobs and the explicit Supabase Auth/Storage/Edge boundary. The migration decision remains **NO-GO**; target readiness is not established.


### Isolated Supabase branch cost quote — 2026-10-17

Using the organization ID supplied by the user, the Supabase cost endpoint returned a branch estimate of **$0.01344/hour** (approximately **$0.32256 per 24 hours** and **$9.81504 per 30 days** at continuous runtime). These are arithmetic projections from the quoted hourly amount, not a total-bill guarantee; additional usage charges and the organization's reported “Exceeding usage limits” status may affect billing. The quote was retrieved successfully. **No cost confirmation ID was requested, no branch was created, and no production change occurred.** Creation remains blocked until the user explicitly approves the quoted recurring hourly cost; after approval, confirm the exact amount/recurrence and then create only a disposable test branch. The existing `main` branch remains unsuitable as an adversarial test target because its status is `MIGRATIONS_FAILED`.



### User decision: no further Supabase branch spend; proceed toward exit — 2026-10-17

The user explicitly declined the quoted Supabase development-branch cost and stated the priority is to move SchoolPro out of Supabase. Respect this decision: **do not call cost confirmation or create a Supabase branch**, and do not incur new Supabase compute charges for this audit.

The intended target remains **Aiven PostgreSQL** for SchoolPro, with the frontend remaining on Render. This does not authorize production export/import, changes to Render configuration, migration replay, deployment, merge, or cutover. Production Supabase must remain unchanged until a separately approved migration plan has a verified destination, source-to-target reconciliation, rollback/recovery procedure, and acceptance evidence.

Continue without a Supabase branch by:
1. Auditing repository migration/source artifacts and the existing committed gate registers.
2. Verifying whether an Aiven PostgreSQL service already exists and is accessible through authorized tooling; if not, document the exact provisioning/configuration prerequisite rather than guessing credentials or creating a paid resource.
3. Preparing a target-side, isolated PostgreSQL rehearsal using an already-authorized environment, if available, and clearly recording any checks that cannot run without it.
4. Planning explicit replacements or retained boundaries for Supabase Auth, Storage and Edge Functions; moving PostgreSQL data alone does not remove those dependencies.
5. Keeping DataSub outside this SchoolPro migration scope.

The cost quote retrieved for a Supabase branch was $0.01344/hour. The user did not approve it. No branch was created and no production change occurred. Migration status remains **NO-GO** until destination correctness, tenant/role security, source completeness, and recovery rehearsal are supported by evidence.


## Destination readiness and no-cost rehearsal checkpoint — 2026-10-17

### Aiven destination verification outcome

**Status: NOT VERIFIED / BLOCKED — no usable Aiven PostgreSQL destination has been established.** The user confirmed they have not yet established that a database is provisioned and accessible. The available connected-tool inventory has no Aiven account/database inspection or SQL-query integration. A repository search on the default branch for Aiven PostgreSQL, AIVEN_DATABASE_URL, DATABASE_URL Aiven, and migration rehearsal/rollback terms returned no matching artifacts; the active audit branch does contain AIVEN-POSTGRESQL-TARGET-VERIFICATION-2026-10-17.md with owner-reported service details. This is a bounded repository/tool check, not proof that no Aiven service exists.

No Aiven resource was provisioned by this audit, no new paid service was created, no connection string or secret was requested in chat, and no database connection was attempted. The existing Aiven verification document records owner-reported service pg-33109aa1 and a candidate rehearsal fork pg-3898d936. Their existence/running state is owner-reported, not independently checked through an Aiven API; the fork has a public endpoint and was reported with its IP allowlist open to all. Treat pg-3898d936 as the only existing rehearsal candidate to verify, not as a proven ready/secure destination, and do not create another resource. Do not use Render Postgres or another provider as a silent substitute for the stated Aiven target.

### Aiven readiness gate — evidence required before rehearsal

Record these items from the Aiven Console or through a securely configured, authorized connection; do not paste passwords/connection secrets into chat:

1. Existing service/project identifier and service state; region; PostgreSQL major version; plan/cost and storage capacity.
2. A database and dedicated least-privilege migration/rehearsal roles exist; TLS is required and the connection can be reached from the approved rehearsal runner.
3. Source/target extension inventory and supported versions (including any Supabase-specific extensions or functions); explicitly list unsupported dependencies.
4. Schema and privilege capability check: schemas, owners, roles, grants/default privileges, RLS support and policy translation, sequences/identity, enums/domains, functions/procedures, triggers, generated columns, constraints and indexes.
5. Network allowlist and secret delivery are configured without exposing credentials in GitHub, logs, prompts or artifacts.
6. Destination is empty or has an approved disposable namespace/database; it contains no customer data and is isolated from production.
7. Backup/snapshot or equivalent restore point and a tested recovery route exist before any rehearsal writes.

Until the above is evidenced, Aiven readiness is **BLOCKED**, not assumed PASS.

### Rehearsal plan using an already-authorized isolated PostgreSQL destination

An owner-reported candidate isolated fork exists as pg-3898d936, but no authorized connection/readiness test is available in this session, and its network exposure needs review. The plan is prepared but **not executed**:

- Phase 0 — acquire approved isolated endpoint; record version, extensions, role capabilities, TLS and network reachability. If unavailable, stop without creating resources or touching production.
- Phase 1 — use only an approved, minimized/synthetic fixture set; no unrestricted production export. Keep DataSub/shared payment and profile data out of SchoolPro scope unless a reviewed dependency contract requires a specific reference.
- Phase 2 — build target schema from reviewed, current canonical definitions, not by blindly replaying historical recovered ledger payloads. Record every source version as exact/superseded/dropped/absent/unresolved and resolve all 397 live-only versions object-by-object before migration approval.
- Phase 3 — load fixtures into the isolated target; reconcile per-table row counts, primary/business-key coverage, deterministic checksums where stable, FK/orphan results, same-school ownership aggregates, and academic/results/payment totals. Exercise idempotent rerun and interrupted-run recovery.
- Phase 4 — run negative tenant tests using separate synthetic school A/B credentials and each intended role; verify no cross-tenant read/write, forged-ID/path access, invalid result access, or receipt/Storage cross-tenant access. Include owner, staff, exam officer, guardian/student, super-admin and service boundaries.
- Phase 5 — restore the pre-rehearsal snapshot into a fresh isolated target and prove recovery. Record elapsed time, errors, reconciliation diffs, and rollback steps. No production cutover until an owner explicitly approves all gates.

### Supabase service-boundary disposition — decision matrix

| Dependency | Migration disposition | Required implementation/evidence before cutover |
|---|---|---|
| Supabase PostgreSQL | Replace as SchoolPro system of record with Aiven PostgreSQL | Schema/extension compatibility; reviewed DDL; data reconciliation; tenant/role tests; backups and rollback evidence |
| Supabase Auth | **Unresolved — replace or deliberately retain** | Inventory every Auth API/session/JWT/admin call and auth.users/profiles FK. If replaced, implement and test account migration, password/session reset strategy, token validation, role/school binding and recovery. If retained, document it as an explicit external identity boundary and test Aiven API authorization against trusted validated identity claims |
| Supabase Storage | **Unresolved — replace or deliberately retain** | Inventory buckets, policies, signed URLs, upload/download/delete paths and object ownership. Choose a destination/provider or retain temporarily; define path/tenant authorization, metadata/size/MIME limits, lifecycle, private access and signed URL expiry tests. Do not copy or rename objects until bucket mismatch and ownership tests pass |
| Supabase Edge Functions | **Unresolved — replace or deliberately retain per function** | Inventory all ten recovered/deployed functions and callers, source/config drift, JWT validation, secrets, service-role operations, rate limits, cron and webhook behavior. For each function choose an approved replacement runtime or a time-bounded retained dependency, then test auth, tenant scope, retries/idempotency and observability |
| Supabase Cron / scheduled jobs | **Unresolved per job** | Map seven current jobs and every invoked routine; identify the unresolved datasub-provider-health-5m provenance. Keep DataSub jobs out of this SchoolPro migration. Recreate only approved SchoolPro jobs with single-run/duplicate safeguards and operational monitoring |
| Shared profiles, payments, virtual accounts, email queue, academic clock | External/shared boundaries until specifically approved | Map 79 cross-boundary FKs and adjacent private/shared references to explicit API/bridge or retained service contracts; do not invent physical Aiven FKs to tables that remain in Supabase |
| Realtime and other Supabase-specific capabilities | Inventory not yet complete | Search application, server and generated clients for Realtime subscriptions and platform-specific APIs; choose replacement or documented retention with failure-mode tests |
| Secrets/environment configuration | Must be replaced/re-scoped | Inventory Render and function secrets by consumer; issue new least-privilege target credentials through the secret manager; never commit credentials or print them into handover |

### Reconciliation work continuing without production changes

- The 397 live-only SQL payloads remain recovered in eight JSONL bundles. Complete semantic comparison remains open for exact function signatures/bodies, policies, effective grants, triggers, cron commands and dependency/scope per version.
- The 35-version marker payloads match their ledger payloads, but original independent deployment actor/time/request/result evidence remains unavailable.
- The live issued-document SELECT policy tautology st.school_id = st.school_id remains a high-priority source-side defect. It must be fixed through an approved change and tested for cross-tenant access; no production policy was changed in this checkpoint.
- Existing tenant evidence is partial: targeted source-side SELECT tests passed for selected tables, but broad role/write adversarial tests, Storage API/signed URL tests and target-side tests are not complete.
- Production export/import, migration replay, DDL/DML, policy/grant changes, Storage mutation, Edge deployment, Render configuration/deployment, merge and cutover remain prohibited without separate explicit authorization.

### Gate status after this checkpoint

- **G1 Tenant/role security: BLOCKED** — issued-document policy defect and adversarial role/Storage/RPC coverage remain open.
- **G2 Source completeness: BLOCKED** — all 397 payloads are recovered, but complete semantic dispositions and the 35-version deployment provenance are not closed.
- **G3 Destination/schema/workflow correctness: BLOCKED** — Aiven endpoint/version/capabilities/access have not been verified; Auth/Storage/Edge boundaries remain undecided.
- **G4 Isolated rehearsal/recovery: BLOCKED / NOT RUN** — no authorized isolated Aiven-compatible target has been established.
- Overall migration decision remains **NO-GO**. No Supabase branch or charges, new Aiven resource, production mutation, export/import, deployment, merge or cutover occurred.


## Issued-document policy patch and CI provenance recheck — 2026-10-17

Read-only review of draft PR #108 (https://github.com/Hassan-625/IHLink-SchoolPro/pull/108) confirms the proposed change corrects more than the student tautology: it adjusts student, guardian and staff permissive SELECT policies to require relationship-school consistency, and hardens generated document-output object policy checks. This broader scope is necessary because permissive policies combine with OR semantics; fixing only the student policy would leave alternate policy paths.

The isolated PostgreSQL 17 RLS/storage regression reported as passing ran against commit 1dfa6f73ebb8b3deb3c8dd5a203ee693f0632220. The current PR head is 018af841733e094a634955b199ac590bac9f95ff. A GitHub commit comparison shows exactly one commit ahead and only one changed file: docs/database-migration/ISSUED-DOCUMENT-RLS-CORRECTION-TEST-PLAN-2026-10-17.md (7 additions, 0 deletions). The migration SQL, regression SQL and workflow were unchanged between the tested commit and current head, so the recorded synthetic regression remains applicable to those code/test assets. The current head's reported Vercel success is not a substitute for security CI; no separate new regression run was observed for the latest head.

**Disposition:** keep PR #108 draft and unmerged. The disposable regression proves the modeled two-school policy behavior and path-tampering cases, but does not emulate Supabase Storage API/signed URLs, JWT/PostgREST behavior, deployed helper ACLs, or app download/RPC paths. Those are still open before production approval or data export. No production policy or Storage change was made.


## Supabase service-boundary inventory refinement — 2026-10-17

The current source notes use two scopes: ten SchoolPro/auth functions with recovered live source/version records, plus earlier inventory mentions of schoolpro-payment and schoolpro-subscription. This discrepancy means the final deployed-function inventory must be re-enumerated before cutover; do not call the list complete from either note alone. The ten recovered functions and required disposition evidence are:

| Deployed function | Known source/auth evidence | Required target disposition before cutover |
|---|---|---|
| invite-school-staff v16 | verify_jwt=false; manually validates bearer through Supabase Auth; deployed source has instrumentation/logging differences from repository source | Decide replace with Render server API or retain as an explicitly time-bounded Supabase Auth invitation adapter. Test token validation, school-owner/staff-role authorization, duplicate invitation, rate limit and safe error logging. Resolve source diff first. |
| schoolpro-owner-access v3 | verify_jwt=true; recovered forensic snapshot, no canonical source path in main at time of comparison | Restore reviewed source into canonical version control (not deploy folder yet); choose Render API replacement or retained adapter; test owner-to-school binding and deny cross-school workspace selection. |
| auth-handoff v12 | verify_jwt=false; manually validates bearer/session; recovered forensic snapshot | Retain only if Supabase Auth is deliberately retained during a transition; otherwise replace with supported identity/session flow. Test token replay, expiry, audience and user/school role resolution. |
| schoolpro-transfer-ownership v1 | verify_jwt=true; recovered forensic snapshot | Port transaction/authorization semantics to a trusted server-side API plus reviewed Aiven transaction/routine; preserve audit events and prevent arbitrary user/school IDs. Test concurrent transfer and former-owner privilege boundaries. |
| schoolpro-render-document v14 | verify_jwt=true; source differs from repo by trailing newline only after normalization | Candidate move to Render worker/API after document-template Storage disposition is explicit. Preserve template/branding authorization and output metadata; test cross-school template/output paths and retries. |
| schoolpro-email-worker v10 | verify_jwt=true; exact deployed source match after nested filename correction | Replace with Render worker/cron or retain temporarily only with a defined queue boundary. Verify idempotency, retry/dead-letter behavior, email secrets and whether the queue remains in Supabase. |
| schoolpro-student-login v3 | verify_jwt=false; source match; rate-limits, resolves school/student, consumes challenge and issues Supabase Auth session | Retain only if Supabase Auth is an explicitly approved identity dependency; otherwise replace the whole challenge/session lifecycle, not just the database lookup. Test replay, brute force, surname initial credential expiry and account lockout. |
| schoolpro-account-login v2 | verify_jwt=false; source match; rate-limits account challenges/initial credentials and returns Auth session | Same explicit Auth decision as student login. Test challenge one-time use, expiry, lockout, account enumeration and session revocation. |
| schoolpro-render-result v6 | verify_jwt=true; recovered forensic snapshot; deployed source writes generated output to school-result-templates | Candidate move to Render API/worker. Resolve canonical output bucket first; test role/student/guardian access, publication state, object ownership and signed download path. |
| schoolpro-result-access v1 | verify_jwt=true; recovered forensic snapshot; signs output against school-result-templates while frontend references schoolpro-result-outputs | Candidate move to trusted API or retain only with a documented Storage boundary; block until bucket mismatch is resolved and signed-URL/expiry/cross-school tests pass. |

Additional payment/subscription function names are mentioned by the broader inventory but are not yet reconciled in the ten-function forensic list; enumerate their deployed versions, verify_jwt configuration, source hashes, caller paths, secrets, and database/storage side effects before assigning dispositions. Also reconcile every Edge Function not prefixed schoolpro that is called by SchoolPro (including auth-handoff and invitation/email dependencies). Do not include DataSub/BillStack functions or cron jobs in the SchoolPro move.

**Default transition architecture proposal, not approved:** keep Supabase Auth temporarily as the identity provider for the first isolated Aiven rehearsal; keep Storage temporarily only if each bucket/path policy and signed-URL boundary is explicitly tested; move database reads/writes behind a trusted Render server API with least-privilege Aiven credentials. Then replace or formally retain each Edge Function one by one with parity and rollback evidence. This avoids treating an Aiven connection-string swap as a safe migration. The user has not yet approved permanent retention of Auth or Storage; final cutover remains blocked until those choices are explicit.
