# Live-only SQL semantic comparison — batch 3: school fee receipt RPC and effective RLS — 2026-10-17

## Scope

Read-only comparison of `20260927113725 schoolpro_multi_child_payment_workflows` with the current `public.submit_schoolpro_payment(uuid,uuid,numeric,date,text,text,text,text,jsonb)` definition and effective RLS policy catalog for payment submissions, allocations and invoices. No RPC was invoked and no production rows/policies/grants were changed.

## Routine body comparison

The current live function body matches the recovered version's payment workflow logic: authenticated guardian linkage to the supplied school, active school bank-account validation, invoice and student-link validation for each allocation, positive amount/balance checks, allocation-total equality, insertion of payment submission and allocation rows. Its signature is SECURITY DEFINER with an empty search path.

The function's current execute ACL is limited to authenticated/service-role access; anonymous execution is not granted. This is consistent with a parent/guardian-submitted school-fee workflow, subject to the missing checks below.

## Material authorization/data-integrity gap

The function accepts `p_receipt_path` and `p_receipt_mime` and inserts those values directly into `schoolpro_payment_submissions`. Neither the recovered function body nor the current body verifies that:

- the receipt object exists in the expected Storage bucket;
- the object path belongs to `p_school` and the submitting guardian/user;
- the path is not a path from another school's receipt or another product's bucket;
- the MIME type matches the actual uploaded object's content type/allowed list; or
- a trusted Storage API object ownership check succeeds before the row is accepted.

The table's INSERT policy verifies `submitted_by = auth.uid()` and an active guardian link for the specified school, while the restrictive module policy checks the finance module. These checks do **not** prove that the receipt path belongs to the same school or caller. Because this is a SECURITY DEFINER RPC, RLS on the row does not compensate for missing path validation inside the function.

**Disposition:** retain the historical function only as a source artifact; do not reproduce this receipt-path trust boundary unchanged in the target API. The target design must validate a canonical bucket + school-prefixed object path, ownership/uploader identity and object metadata through a trusted Storage boundary before accepting the payment record. Never trust a client-supplied path or MIME label alone.

## Effective policy snapshot

Current policies relevant to the workflow:

- `schoolpro_payment_submissions`: permissive INSERT policy binds `submitted_by` to `auth.uid()` and requires an active guardian link in the supplied school; SELECT is for the submitter or school finance roles; restrictive module policy applies to all commands.
- `schoolpro_payment_allocations`: SELECT is for the submitter or finance roles; restrictive finance-module policy applies to all commands.
- `schoolpro_invoices`: school finance roles can create/update and leaders can delete; guardian/student reads are mediated through `schoolpro_owns_invoice_student`; restrictive finance-module policy governs school finance operations with the separately reviewed family-read exception.
- These policies are not interchangeable with a Storage object authorization check. The object path is stored as ordinary text and the row-level policy does not dereference the Storage object.

## Data-state qualifier

The live `schoolpro_payment_submissions` table contains zero rows at audit time, including zero receipt paths. The missing path check is therefore a latent integrity/authorization flaw in the current RPC contract, not evidence that a cross-school receipt was accepted.

## Required test before target approval

In a disposable environment, upload a receipt to the correct school bucket and submit successfully; then try a different school's path, an unrelated product bucket, a nonexistent object, a path with a mismatched owner prefix, a MIME mismatch, and an object removed between upload and RPC. Each invalid case must fail without creating submission/allocation rows. Repeat through the actual Storage API, not just direct SQL. Do not perform these adversarial mutations against production.

## Semantic-comparison status

This batch is an exact live-body comparison with a security disposition. It does not close the overall 397-version routine/policy/ACL audit.
