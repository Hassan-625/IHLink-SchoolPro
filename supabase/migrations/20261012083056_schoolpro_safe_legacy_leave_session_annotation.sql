CREATE OR REPLACE FUNCTION private.validate_schoolpro_leave()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if new.start_date is null or new.end_date is null or new.end_date<new.start_date then raise exception 'Choose valid leave dates'; end if;
 if not exists(select 1 from public.schoolpro_members m where m.id=new.member_id and m.school_id=new.school_id) then raise exception 'Choose a staff member from this school';end if;
 if new.status not in ('pending','approved','rejected','cancelled') then raise exception 'Choose a valid leave status';end if;
 if tg_op='INSERT' and (new.status<>'pending' or new.reviewed_by is not null or new.reviewed_at is not null) then raise exception 'New leave requests must await approval';end if;
 if tg_op='UPDATE' then
  if new.school_id<>old.school_id or new.member_id<>old.member_id then raise exception 'The school and requester cannot be changed';end if;
  if old.session is null and new.session is not null and (to_jsonb(new)-'session')=(to_jsonb(old)-'session') and (private.is_admin(array['super_admin']::public.user_role[]) or private.has_school_access(new.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[])) then return new;end if;
  if old.status<>'pending' then raise exception 'A reviewed leave request cannot be changed';end if;
  if new.status in ('approved','rejected') then
   if auth.uid() is null or not private.schoolpro_module_allowed(new.school_id,'leave') or not private.has_school_access(new.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]) then raise exception 'School approval is required';end if;
   if exists(select 1 from public.schoolpro_members m where m.id=new.member_id and m.user_id=auth.uid()) then raise exception 'Another authorised person must review your leave';end if;
   new.reviewed_by:=auth.uid();new.reviewed_at:=now();
  elsif new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at then raise exception 'Review details are set during approval';end if;
 end if;
 return new;
end $function$
