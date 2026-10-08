alter table public.schoolpro_demo_requests
 add column if not exists term_start date,
 add column if not exists term_end date,
 add column if not exists exam_start date,
 add column if not exists exam_end date,
 add column if not exists calendar_path text,
 add column if not exists letter_path text,
 add column if not exists reviewed_by uuid references auth.users(id),
 add column if not exists reviewed_at timestamptz,
 add column if not exists review_reason text;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('schoolpro-demo-documents','schoolpro-demo-documents',false,10485760,array['application/pdf','image/jpeg','image/png']) on conflict(id) do nothing;
create policy schoolpro_demo_document_upload on storage.objects for insert to authenticated
with check(bucket_id='schoolpro-demo-documents' and (storage.foldername(name))[1]=auth.uid()::text and coalesce(private.is_active_account(),false));
create policy schoolpro_demo_document_read on storage.objects for select to authenticated
using(bucket_id='schoolpro-demo-documents' and coalesce(private.is_active_account(),false) and ((storage.foldername(name))[1]=auth.uid()::text or coalesce(private.has_product_access('schoolpro','approve'),false)));
create or replace function public.submit_schoolpro_term_demo(p_request uuid,p_tier text,p_term_start date,p_term_end date,p_exam_start date,p_exam_end date,p_calendar text,p_letter text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb; did uuid;begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Active account required';end if;
 if p_term_start is null or p_term_end is null or p_exam_start is null or p_exam_end is null or p_term_end<(p_term_start+interval '3 months')::date or p_exam_start<p_term_start or p_exam_end<p_exam_start or p_exam_end>p_term_end or p_term_end<current_date then raise exception 'Submit a current term of at least three months with exams inside the term';end if;
 if p_calendar is null or p_letter is null or p_calendar=p_letter or split_part(p_calendar,'/',1)<>auth.uid()::text or split_part(p_letter,'/',1)<>auth.uid()::text or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=p_calendar) or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=p_letter) then raise exception 'Upload your calendar and request letter';end if;
 result:=public.request_schoolpro_workspace_demo(p_request,p_tier);did:=(result->>'demo_request_id')::uuid;
 update public.schoolpro_demo_requests set term_start=p_term_start,term_end=p_term_end,exam_start=p_exam_start,exam_end=p_exam_end,calendar_path=p_calendar,letter_path=p_letter,updated_at=now() where id=did and user_id=auth.uid() and activated_at is null and status='new' and calendar_path is null;
 if not found then raise exception 'A submitted or activated demo cannot be changed';end if;
 return result||jsonb_build_object('status','awaiting_calendar_review');end $$;
revoke all on function public.submit_schoolpro_term_demo(uuid,text,date,date,date,date,text,text) from public,anon;
grant execute on function public.submit_schoolpro_term_demo(uuid,text,date,date,date,date,text,text) to authenticated,service_role;
create or replace function public.activate_schoolpro_demo(p_school uuid,p_tier text,p_days integer,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.schoolpro_demo_requests%rowtype; finish timestamptz; result jsonb;begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) or not coalesce(private.has_product_access('schoolpro','approve'),false) then raise exception 'Authorized school administrator required';end if;
 if length(trim(coalesce(p_reason,'')))<3 then raise exception 'Calendar review reason required';end if;
 perform 1 from public.schoolpro_schools where id=p_school for update;if not found then raise exception 'School unavailable';end if;
 if exists(select 1 from public.schoolpro_demo_requests where school_id=p_school and activated_at is not null) then raise exception 'This school has already used its demo';end if;
 if exists(select 1 from public.schoolpro_subscriptions where school_id=p_school and status='active' and amount>0 and renews_at>now()) then raise exception 'Paid subscription cannot be replaced by a demo';end if;
 select * into d from public.schoolpro_demo_requests where school_id=p_school and status='new' order by created_at desc limit 1 for update;
 if d.id is null or d.term_start is null or d.term_end is null or d.exam_start is null or d.exam_end is null or d.term_end<(d.term_start+interval '3 months')::date or d.exam_start<d.term_start or d.exam_end<d.exam_start or d.exam_end>d.term_end or d.calendar_path is null or d.letter_path is null then raise exception 'A complete term calendar and request letter are required';end if;
 if not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=d.calendar_path and split_part(name,'/',1)=d.user_id::text) or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=d.letter_path and split_part(name,'/',1)=d.user_id::text) then raise exception 'Review documents unavailable';end if;
 finish:=greatest((d.term_end+1)::timestamp at time zone 'Africa/Lagos',(d.exam_end+15)::timestamp at time zone 'Africa/Lagos');
 if finish<=now() then raise exception 'Submitted demo term has ended';end if;
 result:=public.control_center_activate_schoolpro(p_school,p_tier,p_reason);
 update public.schoolpro_subscriptions set amount=0,billing_cycle='termly',starts_at=d.term_start::timestamp at time zone 'Africa/Lagos',renews_at=finish,updated_at=now() where school_id=p_school;
 update public.schoolpro_onboarding_requests set status='active',updated_at=now() where school_id=p_school;
 update public.schoolpro_demo_requests set status='completed',activated_at=now(),free_access_ends_at=finish,reviewed_by=auth.uid(),reviewed_at=now(),review_reason=trim(p_reason),updated_at=now() where id=d.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'schoolpro_calendar_demo_approved','schoolpro','schoolpro_school',p_school::text,jsonb_build_object('demo_request_id',d.id,'term_end',d.term_end,'exam_end',d.exam_end,'access_ends_at',finish,'payment_recorded',false));
 return result||jsonb_build_object('source','calendar_demo','renews_at',finish);end $$;
create or replace function public.activate_schoolpro_demo(p_request uuid,p_school uuid)
returns jsonb language plpgsql security definer set search_path='' as $$ begin raise exception 'Use calendar-reviewed term demo approval';end $$;
-- Owners submit through the validated RPC, not a client-supplied activation record.
drop policy if exists "Users create demo requests" on public.schoolpro_demo_requests;
