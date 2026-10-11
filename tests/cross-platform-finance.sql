-- Isolated server integration test. Every record and simulated payment rolls back.
begin;
do $$
declare operator_id uuid:=gen_random_uuid(); customer_id uuid:=gen_random_uuid(); outsider_id uuid:=gen_random_uuid(); bank_id uuid:=gen_random_uuid(); platform text; parent_id uuid; invoice_id uuid; replacement_id uuid; submission_id uuid; quote_id uuid; invoice_table text; proof text; version timestamptz; result jsonb; denied boolean; paid_count integer;
begin
 insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
 select v,'authenticated','authenticated','finance-fixture-'||v||'@example.invalid','{}','{"first_name":"Finance","last_name":"Fixture"}',now(),now() from unnest(array[operator_id,customer_id,outsider_id])v;
 update public.profiles set role='super_admin',status='active' where id=operator_id;
 insert into public.ihlink_bank_accounts(id,label,bank_name,account_name,account_number,is_active,is_default)values(bank_id,'ROLLED BACK AUDIT','Fixture Bank','Fixture Account','0000000000',true,false);
 proof:=customer_id::text||'/audit-fixture.pdf';
 insert into storage.objects(bucket_id,name)values('direct-transfer-proofs',proof);
 foreach platform in array array['consult','engineering','print','host','fabrication','compute','academy','digital_business','business_centre'] loop
  execute 'reset role';
  perform set_config('request.jwt.claim.sub','',true);
  perform set_config('request.jwt.claims','{}',true);
  parent_id:=gen_random_uuid(); invoice_id:=gen_random_uuid();
  if platform='consult' then
   insert into public.consult_projects(id,user_id,name,service_category)values(parent_id,customer_id,'Finance fixture','software');
   insert into public.consult_invoices(id,project_id,title,amount,status)values(invoice_id,parent_id,'Fixture invoice',10000,'issued');invoice_table:='consult_invoices';
  elsif platform='engineering' then
   insert into public.engineering_projects(id,user_id,name,discipline)values(parent_id,customer_id,'Finance fixture','control');
   insert into public.engineering_invoices(id,project_id,title,amount,status)values(invoice_id,parent_id,'Fixture invoice',10000,'issued');invoice_table:='engineering_invoices';
  elsif platform='print' then
   insert into public.print_orders(id,user_id,title,status)values(parent_id,customer_id,'Finance fixture','awaiting_payment');
   insert into public.print_invoices(id,order_id,amount,status)values(invoice_id,parent_id,10000,'unpaid');invoice_table:='print_invoices';
  elsif platform='host' then
   insert into public.host_orders(id,user_id,order_type,amount,status)values(parent_id,customer_id,'hosting',10000,'awaiting_payment');
   insert into public.host_invoices(id,order_id,user_id,amount,status)values(invoice_id,parent_id,customer_id,10000,'unpaid');invoice_table:='host_invoices';
  else
   insert into public.business_orders(id,user_id,unit_code,title,requirements,status)values(parent_id,customer_id,platform,'Finance fixture','Isolated audit requirements','awaiting_payment');
   insert into public.business_invoices(id,order_id,amount,status)values(invoice_id,parent_id,10000,'unpaid');invoice_table:='business_invoices';
  end if;
  perform set_config('request.jwt.claim.sub',operator_id::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',operator_id,'role','authenticated')::text,true);
  execute 'set local role authenticated';
  execute format('select updated_at from public.%I where id=$1',invoice_table) into version using invoice_id;
  denied:=false;begin perform public.manage_service_invoice(platform,invoice_id,'regenerate',version,'Fixture regeneration');exception when others then denied:=true;end;
  if not denied then raise exception '% regenerated a live invoice',platform;end if;
  perform public.manage_service_invoice(platform,invoice_id,'cancel',version,'Fixture cancellation');
  execute format('select updated_at from public.%I where id=$1',invoice_table) into version using invoice_id;
  result:=public.manage_service_invoice(platform,invoice_id,'regenerate',version,'Fixture regeneration');replacement_id:=(result->>'invoice_id')::uuid;
  if replacement_id=invoice_id then raise exception '% reused cancelled id',platform;end if;
  result:=public.manage_service_invoice(platform,invoice_id,'regenerate',version,'Fixture retry');
  if (result->>'invoice_id')::uuid<>replacement_id then raise exception '% duplicate replacement',platform;end if;
  execute 'reset role';
  submission_id:=gen_random_uuid();
  insert into public.direct_transfer_submissions(id,user_id,platform_code,invoice_id,source_reference,bank_account_id,amount,sender_name,customer_reference,proof_storage_path)
  values(submission_id,customer_id,platform,replacement_id,'AUDIT-'||parent_id,bank_id,10000,'Fixture customer','AUDIT-'||submission_id,proof);
  perform set_config('request.jwt.claim.sub',outsider_id::text,true);perform set_config('request.jwt.claims',jsonb_build_object('sub',outsider_id,'role','authenticated')::text,true);execute 'set local role authenticated';
  denied:=false;begin perform public.review_direct_bank_transfer(submission_id,'approved','Fixture review');exception when others then denied:=true;end;
  if not denied then raise exception '% permitted outsider settlement',platform;end if;
  perform set_config('request.jwt.claim.sub',operator_id::text,true);perform set_config('request.jwt.claims',jsonb_build_object('sub',operator_id,'role','authenticated')::text,true);
  result:=public.review_direct_bank_transfer(submission_id,'approved','Simulated review, rolled back');
  if result->>'status'<>'approved' then raise exception '% approval failed',platform;end if;
  perform public.review_direct_bank_transfer(submission_id,'approved','Simulated retry, rolled back');
  execute format('select count(*) from public.%I where id=$1 and status=''paid''',invoice_table)into paid_count using replacement_id;
  if paid_count<>1 then raise exception '% invoice did not settle',platform;end if;
  execute format('select updated_at from public.%I where id=$1',invoice_table)into version using replacement_id;
  denied:=false;begin perform public.manage_service_invoice(platform,replacement_id,'cancel',version,'Invalid paid cancellation');exception when others then denied:=true;end;
  if not denied then raise exception '% allowed paid invoice cancellation',platform;end if;
 end loop;
 execute 'reset role';
end $$;
rollback;
