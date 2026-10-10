alter table public.schoolpro_payroll_records
  add column if not exists approved_by uuid references public.profiles(id),
  add column if not exists approved_at timestamptz,
  add column if not exists paid_at timestamptz,
  add column if not exists payment_reference text;
alter table public.schoolpro_health_records
  add column if not exists follow_up_date date,
  add column if not exists follow_up_notes text,
  add column if not exists status text not null default 'open';
alter table public.schoolpro_calendar_events
  add column if not exists end_date date,
  add column if not exists class_id uuid references public.schoolpro_classes(id);

-- A module permission alone must not reveal confidential clinic records.
create policy "clinic role boundary" on public.schoolpro_health_records as restrictive
for all to authenticated
using (private.schoolpro_module_allowed(school_id,'medical') and private.has_school_access(school_id,array['proprietor','administrator','nurse','counsellor','head_teacher']::public.school_member_role[]))
with check (private.schoolpro_module_allowed(school_id,'medical') and private.has_school_access(school_id,array['proprietor','administrator','nurse','counsellor','head_teacher']::public.school_member_role[]));

create or replace function private.validate_schoolpro_workflow_record()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if tg_op='DELETE' then
    if tg_table_name='schoolpro_payroll_records' and old.status<>'draft' then
      raise exception 'Only draft payroll records can be deleted';
    end if;
    return old;
  end if;
  if tg_op='UPDATE' and new.school_id is distinct from old.school_id then
    raise exception 'A record cannot be moved to another school';
  end if;
  if tg_table_name='schoolpro_payroll_records' then
    if new.member_id is null or not exists(select 1 from public.schoolpro_members where id=new.member_id and school_id=new.school_id) then
      raise exception 'Choose a staff member from this school';
    end if;
    if new.gross<0 or new.deductions<0 or new.deductions>new.gross or new.gross::text in ('NaN','Infinity','-Infinity') or new.deductions::text in ('NaN','Infinity','-Infinity') then
      raise exception 'Check the gross pay and deductions';
    end if;
    if new.status not in ('draft','approved','processed','paid') then raise exception 'Choose a valid payroll status'; end if;
    new.net:=new.gross-new.deductions;
    if tg_op='INSERT' then
      if new.status<>'draft' then raise exception 'Save payroll as a draft before approving it'; end if;
      new.approved_by:=null; new.approved_at:=null; new.paid_at:=null; new.payment_reference:=null;
    else
      if old.status='paid' then raise exception 'Paid payroll records cannot be changed'; end if;
      if old.status in ('approved','processed') and (new.member_id is distinct from old.member_id or new.period is distinct from old.period or new.gross is distinct from old.gross or new.deductions is distinct from old.deductions or new.status='draft') then
        raise exception 'Approved payroll details cannot be changed';
      end if;
      if new.status in ('approved','processed') and old.status='draft' then
        if auth.uid() is null or not private.has_school_access(new.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then raise exception 'Payroll approval is not available for your account'; end if;
        new.approved_by:=auth.uid(); new.approved_at:=now();
      else
        new.approved_by:=old.approved_by; new.approved_at:=old.approved_at;
      end if;
      if new.status='paid' then
        if old.status not in ('approved','processed') or nullif(btrim(new.payment_reference),'') is null then raise exception 'Approve payroll and enter a payment reference before marking it paid'; end if;
        new.paid_at:=now();
      else
        new.paid_at:=old.paid_at; new.payment_reference:=old.payment_reference;
      end if;
    end if;
  elsif tg_table_name='schoolpro_health_records' then
    if not exists(select 1 from public.schoolpro_students where id=new.student_id and school_id=new.school_id) then raise exception 'Choose a student from this school'; end if;
    if new.status not in ('open','follow-up','closed') then raise exception 'Choose a valid clinic status'; end if;
    if new.status='follow-up' and new.follow_up_date is null then raise exception 'Choose a follow-up date'; end if;
    if tg_op='INSERT' then new.recorded_by:=auth.uid(); else new.recorded_by:=old.recorded_by; end if;
  elsif tg_table_name='schoolpro_calendar_events' then
    if new.end_date<new.event_date then raise exception 'The event end date must not be before its start date'; end if;
    if new.class_id is not null and not exists(select 1 from public.schoolpro_classes where id=new.class_id and school_id=new.school_id) then raise exception 'Choose a class from this school'; end if;
  end if;
  return new;
end $$;
revoke all on function private.validate_schoolpro_workflow_record() from public,anon,authenticated;
create trigger validate_schoolpro_payroll_workflow before insert or update or delete on public.schoolpro_payroll_records for each row execute function private.validate_schoolpro_workflow_record();
create trigger validate_schoolpro_clinic_workflow before insert or update on public.schoolpro_health_records for each row execute function private.validate_schoolpro_workflow_record();
create trigger validate_schoolpro_calendar_workflow before insert or update on public.schoolpro_calendar_events for each row execute function private.validate_schoolpro_workflow_record();

-- Retain the existing API, applying the same permissions and approval rules as the UI.
create or replace function public.process_schoolpro_payroll(p_record uuid) returns void
language plpgsql security invoker set search_path='' as $$
begin
  update public.schoolpro_payroll_records set status='approved' where id=p_record and status='draft';
  if not found then raise exception 'Only an accessible draft payroll record can be approved'; end if;
end $$;
revoke all on function public.process_schoolpro_payroll(uuid) from public,anon;
grant execute on function public.process_schoolpro_payroll(uuid) to authenticated;
