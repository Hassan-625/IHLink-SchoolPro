# Live Supabase scheduled-job semantic comparison — 2026-10-17

## Scope

Read-only comparison of all current `cron.job` entries against the 476-row production migration ledger. The current catalog has seven active jobs. Job command strings were compared literally against ledger payloads after matching the job name; no job was executed, rescheduled, or modified.

## Current job reconciliation

| Current job | Schedule | Active | Matching ledger version | Command in that version's SQL | Classification |
|---|---|---:|---|---|---|
| `billstack-pending-funding-5m` | `*/5 * * * *` | yes | `20261007203449 billstack_pending_funding_reconciliation` | exact substring match | **Matched** |
| `datasub-api-callbacks-1m` | `* * * * *` | yes | `20261010160508 datasub_api_access_callbacks` | exact substring match | **Matched** |
| `datasub-provider-health-5m` | `*/5 * * * *` | yes | **none found by job name in the 476 ledger payloads** | not available for comparison | **Unresolved provenance** |
| `datasub-reconcile-2m` | `*/2 * * * *` | yes | `20261002143519 schedule_datasub_transaction_reconciliation` | exact substring match | **Matched** |
| `ihlink-email-delivery-2m` | `*/2 * * * *` | yes | `20261010160509 ecosystem_email_readiness` | exact substring match | **Matched** |
| `schoolpro-academic-calendar` | `7 * * * *` | yes | `20261011215950 schoolpro_academic_calendar_and_student_transfers` | exact substring match | **Matched** |
| `schoolpro-expiry-grace-daily` | `15 0 * * *` | yes | `20261003161802 schoolpro_once_only_four_month_demo_and_expiry_grace` | exact substring match | **Matched; routine body has later semantic evolution documented separately** |

The two SchoolPro jobs are active with the expected names, schedules and command text in their matching ledger payloads. This does not prove their called function bodies are unchanged; `private.enforce_schoolpro_subscription_expiry()` has evolved from the original migration body and must be treated as a later live definition, not replayed.

## Unresolved job

`datasub-provider-health-5m` is active in the live catalog, but a literal scan of every production ledger payload found no matching job-name source. This may have been configured outside the migration ledger or by a later untracked operation; available evidence does not determine which. Recover the provisioning/audit evidence or document the out-of-band origin before treating the job as reproducible. Its command calls the deployed `datasub-provider-health` Edge Function using a secret referenced by name; secret values were not read or exposed.

## Status

Six of seven current jobs match a specific ledger payload by job name, schedule and command text. One current job has unresolved ledger provenance. This closes the current-job inventory pass, not all scheduled-job semantics across the 397 live-only versions: historical unschedule/reschedule transitions, job replacement order, function-body changes and historical job-run outcomes still need version-specific classification. No production changes occurred.
