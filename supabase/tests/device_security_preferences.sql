begin;
select set_config('test.security.uid1',gen_random_uuid()::text,true),set_config('test.security.uid2',gen_random_uuid()::text,true);
insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select current_setting('test.security.uid1')::uuid,'authenticated','authenticated','device-test-'||current_setting('test.security.uid1')||'@example.invalid','{}'::jsonb,'{"first_name":"Device","middle_name":"Security","last_name":"Testing"}'::jsonb,now(),now()
union all select current_setting('test.security.uid2')::uuid,'authenticated','authenticated','device-test-'||current_setting('test.security.uid2')||'@example.invalid','{}'::jsonb,'{"first_name":"Other","middle_name":"Security","last_name":"Testing"}'::jsonb,now(),now();
select set_config('request.jwt.claim.sub',current_setting('test.security.uid1'),true);
set local role authenticated;
do $$
declare a uuid:=current_setting('test.security.uid1')::uuid;b uuid:=current_setting('test.security.uid2')::uuid;device uuid:=gen_random_uuid();
begin
 insert into public.app_device_security_preferences(user_id,product,device_id,platform)values(a,'schoolpro',device,'web');
 update public.app_device_security_preferences set passcode_enabled=true,biometric_enabled=true where user_id=a;
 if not exists(select 1 from public.app_device_security_preferences where user_id=a and passcode_enabled and biometric_enabled)then raise exception 'Own status update failed';end if;
 begin insert into public.app_device_security_preferences(user_id,product,device_id,platform)values(b,'schoolpro',gen_random_uuid(),'web');raise exception 'Other account insert allowed';exception when insufficient_privilege then null;end;
 begin update public.app_device_security_preferences set user_id=b where user_id=a;raise exception 'Ownership reassignment allowed';exception when insufficient_privilege then null;end;
 if exists(select 1 from public.app_device_security_preferences where user_id=b)then raise exception 'Other account visible';end if;
 begin update public.app_device_security_preferences set passcode_enabled=false,biometric_enabled=true where user_id=a;raise exception 'Biometric without passcode allowed';exception when check_violation then null;end;
end $$;
reset role;
select set_config('request.jwt.claim.sub',current_setting('test.security.uid2'),true);
set local role authenticated;
do $$begin if exists(select 1 from public.app_device_security_preferences)then raise exception 'Cross-account read allowed';end if;end $$;
reset role;
set local role anon;
do $$begin begin perform 1 from public.app_device_security_preferences;raise exception 'Anonymous read allowed';exception when insufficient_privilege then null;end;end $$;
reset role;
rollback;
