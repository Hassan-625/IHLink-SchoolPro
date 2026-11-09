-- Let a requester track only their own class/section correction requests.
-- The Exam Officer and school administrators retain their existing review visibility.
drop policy if exists schoolpro_result_correction_batches_requester_read
  on public.schoolpro_result_correction_batches;
create policy schoolpro_result_correction_batches_requester_read
on public.schoolpro_result_correction_batches for select to authenticated
using (requested_by = auth.uid());
