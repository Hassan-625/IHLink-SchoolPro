-- Defense-in-depth for guardian/parent access.
-- A guardian link must match both the student and the tenant of the target row.

drop policy if exists "Guardians read linked students" on public.schoolpro_students;
create policy "Guardians read linked students" on public.schoolpro_students for select to authenticated using (
  exists(select 1 from public.schoolpro_guardian_links g
    where g.student_id=schoolpro_students.id
      and g.school_id=schoolpro_students.school_id
      and g.guardian_user_id=(select auth.uid()) and g.status='active')
);

drop policy if exists "Guardians read linked invoices" on public.schoolpro_invoices;
create policy "Guardians read linked invoices" on public.schoolpro_invoices for select to authenticated using (
  exists(select 1 from public.schoolpro_guardian_links g
    where g.student_id=schoolpro_invoices.student_id
      and g.school_id=schoolpro_invoices.school_id
      and g.guardian_user_id=(select auth.uid()) and g.status='active')
);

drop policy if exists "Guardians read linked payments" on public.schoolpro_fee_payments;
create policy "Guardians read linked payments" on public.schoolpro_fee_payments for select to authenticated using (
  exists(select 1 from public.schoolpro_guardian_links g
    where g.student_id=schoolpro_fee_payments.student_id
      and g.school_id=schoolpro_fee_payments.school_id
      and g.guardian_user_id=(select auth.uid()) and g.status='active')
);

drop policy if exists "Guardians read linked attendance" on public.schoolpro_attendance;
create policy "Guardians read linked attendance" on public.schoolpro_attendance for select to authenticated using (
  exists(select 1 from public.schoolpro_guardian_links g
    where g.student_id=schoolpro_attendance.student_id
      and g.school_id=schoolpro_attendance.school_id
      and g.guardian_user_id=(select auth.uid()) and g.status='active')
);

drop policy if exists "Guardians read linked subjects" on public.schoolpro_subjects;
create policy "Guardians read linked subjects" on public.schoolpro_subjects for select to authenticated using (
  exists(select 1 from public.schoolpro_guardian_links g
    where g.school_id=schoolpro_subjects.school_id
      and g.guardian_user_id=(select auth.uid()) and g.status='active')
);

drop policy if exists "Guardians read linked assessment schemes" on public.schoolpro_assessment_schemes;
create policy "Guardians read linked assessment schemes" on public.schoolpro_assessment_schemes for select to authenticated using (
  exists(select 1 from public.schoolpro_guardian_links g
    where g.school_id=schoolpro_assessment_schemes.school_id
      and g.guardian_user_id=(select auth.uid()) and g.status='active')
);

drop policy if exists "Guardians read published linked results" on public.schoolpro_results;
create policy "Guardians read published linked results" on public.schoolpro_results for select to authenticated using (
 status='published'::public.schoolpro_result_status
 and exists(select 1 from public.schoolpro_guardian_links g
   where g.student_id=schoolpro_results.student_id
     and g.school_id=schoolpro_results.school_id
     and g.guardian_user_id=(select auth.uid()) and g.status='active')
 and (
  not coalesce((select f.block_results_when_owing from public.schoolpro_finance_settings f where f.school_id=schoolpro_results.school_id limit 1),false)
  or coalesce((select sum(greatest(i.amount_due-i.discount-i.scholarship-i.amount_paid,0))
               from public.schoolpro_invoices i
               where i.school_id=schoolpro_results.school_id
                 and i.student_id=schoolpro_results.student_id
                 and i.term=schoolpro_results.term and i.session=schoolpro_results.session
                 and i.status<>'waived'::public.schoolpro_invoice_status),0)
     <= coalesce((select f.allowed_outstanding from public.schoolpro_finance_settings f where f.school_id=schoolpro_results.school_id limit 1),0)
 )
);

create or replace function private.validate_schoolpro_guardian_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare student_school uuid;
begin
 select school_id into student_school from public.schoolpro_students where id=new.student_id;
 if student_school is null then raise exception 'Student not found'; end if;
 if student_school<>new.school_id then raise exception 'Guardian link school must match the student school'; end if;
 return new;
end $$;
revoke all on function private.validate_schoolpro_guardian_tenant() from public,anon,authenticated;
drop trigger if exists validate_schoolpro_guardian_tenant on public.schoolpro_guardian_links;
create trigger validate_schoolpro_guardian_tenant before insert or update of school_id,student_id
on public.schoolpro_guardian_links for each row execute function private.validate_schoolpro_guardian_tenant();
