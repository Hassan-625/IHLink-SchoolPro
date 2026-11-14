-- Class-result submission metadata follows the same class/section review boundary
-- as the authoritative result workflow. The former policy granted every active
-- teacher, class teacher, head teacher and vice principal school-wide reads.
drop policy if exists "School result leaders read class submissions"
  on public.schoolpro_class_result_submissions;

create policy "School result leaders read class submissions"
  on public.schoolpro_class_result_submissions
  for select
  to authenticated
  using (
    private.schoolpro_can_review_class(school_id, class_id)
  );

comment on policy "School result leaders read class submissions"
  on public.schoolpro_class_result_submissions is
  'Class result submission metadata is visible only to school result reviewers, the assigned section leader, or the assigned Form Master through the authoritative class-review helper.';
