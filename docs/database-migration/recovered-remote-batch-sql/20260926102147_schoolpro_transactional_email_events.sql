create or replace function public.queue_schoolpro_transactional_email() returns trigger language plpgsql security definer set search_path=public,auth as $$
declare sid uuid; sch uuid; email text; nm text; subj text; msg text; key text;
begin
 if tg_table_name='schoolpro_fee_payments' then sid:=new.student_id; sch:=new.school_id; key:='payment_receipt'; subj:='SchoolPro payment receipt'; msg:='A payment of NGN '||new.amount||' has been recorded. Reference: '||coalesce(new.reference,'N/A')||'.';
 elsif tg_table_name='schoolpro_results' and new.status::text='published' and old.status::text is distinct from 'published' then sid:=new.student_id; sch:=new.school_id; key:='result_published'; subj:='SchoolPro result published'; msg:='A result has been published for '||new.term||', '||new.session||'.';
 else return new; end if;
 select u.email,concat_ws(' ',s.first_name,s.last_name) into email,nm from schoolpro_students s left join auth.users u on u.id=s.user_id where s.id=sid;
 if email is not null then insert into schoolpro_email_queue(school_id,recipient_email,recipient_name,template_key,subject,payload,status) values(sch,email,nm,key,subj,jsonb_build_object('message',msg,'student_id',sid),'pending'); end if;
 return new;
end $$;
drop trigger if exists trg_schoolpro_payment_email on public.schoolpro_fee_payments;
create trigger trg_schoolpro_payment_email after insert on public.schoolpro_fee_payments for each row execute function public.queue_schoolpro_transactional_email();
drop trigger if exists trg_schoolpro_result_email on public.schoolpro_results;
create trigger trg_schoolpro_result_email after update of status on public.schoolpro_results for each row execute function public.queue_schoolpro_transactional_email();