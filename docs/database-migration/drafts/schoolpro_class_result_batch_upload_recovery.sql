-- Recover interrupted class-result batch uploads without leaving an unusable
-- uploading record. Only the creator may fail their own incomplete upload.
create or replace function public.schoolpro_fail_class_result_batch_upload(p_batch_id uuid)
returns text
language plpgsql
security definer
set search_path=''
as $$
declare
  v_batch public.schoolpro_class_result_batches%rowtype;
begin
  if auth.uid() is null or not coalesce(private.is_active_account(),false) then
    raise exception 'An active account is required';
  end if;

  select b.* into v_batch
  from public.schoolpro_class_result_batches b
  where b.id=p_batch_id
  for update;

  if not found
     or v_batch.created_by<>(select auth.uid())
     or v_batch.status<>'uploading'
     or not private.schoolpro_can_manage_class_result_batch(v_batch.school_id,v_batch.class_id,v_batch.session)
     or not private.schoolpro_module_allowed(v_batch.school_id,'results') then
    raise exception 'Only the creator of an active uploading batch may mark it failed';
  end if;

  update public.schoolpro_class_result_batches
  set status='failed',updated_at=now()
  where id=p_batch_id;

  return 'failed';
end;
$$;
revoke all on function public.schoolpro_fail_class_result_batch_upload(uuid) from public,anon;
grant execute on function public.schoolpro_fail_class_result_batch_upload(uuid) to authenticated;

-- Permit cleanup of both the register workbook and every per-student workbook
-- after a batch has entered a terminal failed/cancelled state.
drop policy if exists schoolpro_class_result_batches_storage_delete_failed on storage.objects;
create policy schoolpro_class_result_batches_storage_delete_failed
  on storage.objects for delete to authenticated
  using (
    bucket_id='schoolpro-class-result-batches'
    and exists (
      select 1 from public.schoolpro_class_result_batches b
      where b.status in ('failed','cancelled')
        and (b.storage_path=name or exists (
          select 1 from public.schoolpro_class_result_batch_reviews r
          where r.batch_id=b.id and r.student_storage_path=name
        ))
        and private.schoolpro_can_manage_class_result_batch(b.school_id,b.class_id,b.session)
        and private.schoolpro_module_allowed(b.school_id,'results')
    )
  );

comment on function public.schoolpro_fail_class_result_batch_upload(uuid) is
  'Marks only the authenticated creator''s incomplete class-result upload as failed so its private artifacts can be cleaned up and a new batch can be created.';

-- A browser/process exit cannot run the upload catch handler. On the next
-- batch attempt, retire uploads older than 45 minutes and return their exact
-- private object paths so the authorized client can remove partial artifacts.
create or replace function public.schoolpro_recover_stale_class_result_batch_uploads(
  p_school uuid,p_class uuid,p_term text,p_session text
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_recovered jsonb;
begin
  if auth.uid() is null or not coalesce(private.is_active_account(),false)
     or not private.schoolpro_can_manage_class_result_batch(p_school,p_class,p_session)
     or not private.schoolpro_module_allowed(p_school,'results') then
    raise exception 'An authorized active results staff member is required';
  end if;

  with stale as (
    update public.schoolpro_class_result_batches b
    set status='failed',updated_at=now()
    where b.school_id=p_school and b.class_id=p_class
      and b.term=p_term and b.session=p_session
      and b.status='uploading'
      and b.created_at<now()-interval '45 minutes'
    returning b.id,b.storage_path
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'batch_id',s.id,
    'paths',array(
      select p.path from (
        select s.storage_path as path
        union all
        select r.student_storage_path
        from public.schoolpro_class_result_batch_reviews r
        where r.batch_id=s.id
      ) p
    )
  )),'[]'::jsonb)
  into v_recovered
  from stale s;

  return v_recovered;
end;
$$;
revoke all on function public.schoolpro_recover_stale_class_result_batch_uploads(uuid,uuid,text,text) from public,anon;
grant execute on function public.schoolpro_recover_stale_class_result_batch_uploads(uuid,uuid,text,text) to authenticated;

comment on function public.schoolpro_recover_stale_class_result_batch_uploads(uuid,uuid,text,text) is
  'Fails incomplete class-result uploads older than 45 minutes for the authorized school/class/term/session and returns only their exact private object paths for cleanup.';
