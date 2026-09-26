-- SchoolPro production authorization hardening captured from the verified live project.
-- Student result access must honor the same configured debt threshold as guardian access.
drop policy if exists "students view own published results" on public.schoolpro_results;
create policy "students view own published results" on public.schoolpro_results for select to authenticated using (
 status='published'::public.schoolpro_result_status
 and exists(select 1 from public.schoolpro_students s where s.id=schoolpro_results.student_id and s.user_id=(select auth.uid()))
 and (
  not coalesce((select fs.block_results_when_owing from public.schoolpro_finance_settings fs where fs.school_id=schoolpro_results.school_id limit 1),false)
  or coalesce((select sum(greatest(inv.amount_due-inv.discount-inv.scholarship-inv.amount_paid,0)) from public.schoolpro_invoices inv where inv.student_id=schoolpro_results.student_id and inv.term=schoolpro_results.term and inv.session=schoolpro_results.session and inv.status<>'waived'::public.schoolpro_invoice_status),0)
     <= coalesce((select fs.allowed_outstanding from public.schoolpro_finance_settings fs where fs.school_id=schoolpro_results.school_id limit 1),0)
 )
);

drop policy if exists "school member access schoolpro_admissions" on public.schoolpro_admissions;
drop policy if exists "school members read admissions" on public.schoolpro_admissions;
drop policy if exists "admissions staff manage admissions" on public.schoolpro_admissions;
create policy "school members read admissions" on public.schoolpro_admissions for select to authenticated using (private.has_school_access(school_id));
create policy "admissions staff manage admissions" on public.schoolpro_admissions for all to authenticated using (private.has_school_access(school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[]));

drop policy if exists "admission docs staff" on public.schoolpro_admission_documents;
create policy "admission docs staff" on public.schoolpro_admission_documents for all to authenticated using (exists(select 1 from public.schoolpro_admissions a where a.id=application_id and private.has_school_access(a.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[]))) with check (exists(select 1 from public.schoolpro_admissions a where a.id=application_id and private.has_school_access(a.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[])));
drop policy if exists "admission events staff" on public.schoolpro_admission_events;
create policy "admission events staff" on public.schoolpro_admission_events for all to authenticated using (exists(select 1 from public.schoolpro_admissions a where a.id=application_id and private.has_school_access(a.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[]))) with check (exists(select 1 from public.schoolpro_admissions a where a.id=application_id and private.has_school_access(a.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[])));
drop policy if exists "admission offers staff" on public.schoolpro_admission_offers;
create policy "admission offers staff" on public.schoolpro_admission_offers for all to authenticated using (exists(select 1 from public.schoolpro_admissions a where a.id=application_id and private.has_school_access(a.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[]))) with check (exists(select 1 from public.schoolpro_admissions a where a.id=application_id and private.has_school_access(a.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[])));

drop policy if exists "school member access schoolpro_cbt_tests" on public.schoolpro_cbt_tests;
drop policy if exists "school members read cbt tests" on public.schoolpro_cbt_tests;
drop policy if exists "cbt managers manage tests" on public.schoolpro_cbt_tests;
create policy "school members read cbt tests" on public.schoolpro_cbt_tests for select to authenticated using (private.has_school_access(school_id));
create policy "cbt managers manage tests" on public.schoolpro_cbt_tests for all to authenticated using (public.schoolpro_can_manage_cbt(school_id)) with check (public.schoolpro_can_manage_cbt(school_id));

drop policy if exists "School finance records payments" on public.schoolpro_fee_payments;
create policy "School finance records payments" on public.schoolpro_fee_payments for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) and recorded_by=(select auth.uid()));
drop policy if exists "School finance creates structures" on public.schoolpro_fee_structures;
create policy "School finance creates structures" on public.schoolpro_fee_structures for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) and created_by=(select auth.uid()));
drop policy if exists "School finance updates structures" on public.schoolpro_fee_structures;
create policy "School finance updates structures" on public.schoolpro_fee_structures for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]));
drop policy if exists "School finance creates invoices" on public.schoolpro_invoices;
create policy "School finance creates invoices" on public.schoolpro_invoices for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) and created_by=(select auth.uid()));
drop policy if exists "School finance updates invoices" on public.schoolpro_invoices;
create policy "School finance updates invoices" on public.schoolpro_invoices for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]));
drop policy if exists "Payers school and corporate finance read fee intents" on public.schoolpro_payment_intents;
create policy "Payers school and corporate finance read fee intents" on public.schoolpro_payment_intents for select to authenticated using (payer_user_id=(select auth.uid()) or private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) or private.has_product_access('corporate','view'));
