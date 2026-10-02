-- Cross-tenant relational integrity for CBT, Question Bank and staff permission records.
-- RLS controls who may act; these triggers also ensure related IDs belong to the same school.

create or replace function private.validate_schoolpro_cbt_question_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare test_school uuid; question_school uuid;
begin
 select school_id into test_school from public.schoolpro_cbt_tests where id=new.test_id;
 select school_id into question_school from public.schoolpro_question_bank where id=new.question_id;
 if test_school is null or question_school is null then raise exception 'CBT test or question not found'; end if;
 if test_school<>question_school then raise exception 'CBT question belongs to another school'; end if;
 return new;
end $$;

create or replace function private.validate_schoolpro_cbt_eligibility_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare test_school uuid; ref_school uuid;
begin
 select school_id into test_school from public.schoolpro_cbt_tests where id=new.test_id;
 if test_school is null or test_school<>new.school_id then raise exception 'CBT eligibility school must match the test school'; end if;
 if new.student_id is not null then
   select school_id into ref_school from public.schoolpro_students where id=new.student_id;
   if ref_school is null or ref_school<>new.school_id then raise exception 'Eligible student belongs to another school'; end if;
 end if;
 if new.class_id is not null then
   select school_id into ref_school from public.schoolpro_classes where id=new.class_id;
   if ref_school is null or ref_school<>new.school_id then raise exception 'Eligible class belongs to another school'; end if;
 end if;
 return new;
end $$;

create or replace function private.validate_schoolpro_member_permission_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare member_school uuid;
begin
 select school_id into member_school from public.schoolpro_members where id=new.member_id;
 if member_school is null then raise exception 'School member not found'; end if;
 if member_school<>new.school_id then raise exception 'Permission member belongs to another school'; end if;
 return new;
end $$;

revoke all on function private.validate_schoolpro_cbt_question_tenant() from public,anon,authenticated;
revoke all on function private.validate_schoolpro_cbt_eligibility_tenant() from public,anon,authenticated;
revoke all on function private.validate_schoolpro_member_permission_tenant() from public,anon,authenticated;

drop trigger if exists validate_schoolpro_cbt_question_tenant on public.schoolpro_cbt_test_questions;
create trigger validate_schoolpro_cbt_question_tenant before insert or update of test_id,question_id
on public.schoolpro_cbt_test_questions for each row execute function private.validate_schoolpro_cbt_question_tenant();

drop trigger if exists validate_schoolpro_cbt_eligibility_tenant on public.schoolpro_cbt_eligibility;
create trigger validate_schoolpro_cbt_eligibility_tenant before insert or update of school_id,test_id,student_id,class_id
on public.schoolpro_cbt_eligibility for each row execute function private.validate_schoolpro_cbt_eligibility_tenant();

drop trigger if exists validate_schoolpro_member_permission_tenant on public.schoolpro_member_permissions;
create trigger validate_schoolpro_member_permission_tenant before insert or update of school_id,member_id
on public.schoolpro_member_permissions for each row execute function private.validate_schoolpro_member_permission_tenant();
