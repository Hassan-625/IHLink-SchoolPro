-- Defensive tenant-isolation hardening for SchoolPro operational modules.
-- Every school-scoped row is protected at the database layer. UI filters are not a security boundary.
-- IHLink super_admin access remains available through private.has_school_access().

do $$
declare t text;
begin
  foreach t in array array[
    'schoolpro_library_books','schoolpro_transport_routes','schoolpro_hostel_rooms',
    'schoolpro_inventory_assets','schoolpro_calendar_events','schoolpro_lesson_notes',
    'schoolpro_result_approvals','schoolpro_promotions'
  ] loop
    if to_regclass('public.'||t) is not null then
      execute format('alter table public.%I enable row level security',t);
      execute format('alter table public.%I force row level security',t);
    end if;
  end loop;
end $$;

-- Remove permissive legacy catch-all policies on these modules before installing explicit tenant policies.
do $$
declare t text; p record;
begin
  foreach t in array array[
    'schoolpro_library_books','schoolpro_transport_routes','schoolpro_hostel_rooms',
    'schoolpro_inventory_assets','schoolpro_calendar_events','schoolpro_lesson_notes',
    'schoolpro_result_approvals','schoolpro_promotions'
  ] loop
    if to_regclass('public.'||t) is not null then
      for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
        execute format('drop policy if exists %I on public.%I',p.policyname,t);
      end loop;
    end if;
  end loop;
end $$;

create policy "tenant read library" on public.schoolpro_library_books for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage library" on public.schoolpro_library_books for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','librarian']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','librarian']::public.school_member_role[]));

create policy "tenant read transport" on public.schoolpro_transport_routes for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage transport" on public.schoolpro_transport_routes for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','transport_manager']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','transport_manager']::public.school_member_role[]));

create policy "tenant read hostel" on public.schoolpro_hostel_rooms for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage hostel" on public.schoolpro_hostel_rooms for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','hostel_manager']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','hostel_manager']::public.school_member_role[]));

create policy "tenant read inventory" on public.schoolpro_inventory_assets for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage inventory" on public.schoolpro_inventory_assets for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','inventory_officer']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','inventory_officer']::public.school_member_role[]));

create policy "tenant read calendar" on public.schoolpro_calendar_events for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage calendar" on public.schoolpro_calendar_events for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[]));

create policy "tenant read lesson notes" on public.schoolpro_lesson_notes for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage lesson notes" on public.schoolpro_lesson_notes for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[]));

create policy "tenant read result approvals" on public.schoolpro_result_approvals for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage result approvals" on public.schoolpro_result_approvals for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','exam_officer','head_teacher','vice_principal']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','exam_officer','head_teacher','vice_principal']::public.school_member_role[]));

create policy "tenant read promotions" on public.schoolpro_promotions for select to authenticated
using (private.has_school_access(school_id));
create policy "tenant manage promotions" on public.schoolpro_promotions for all to authenticated
using (private.has_school_access(school_id,array['proprietor','administrator','registrar','head_teacher','vice_principal']::public.school_member_role[]))
with check (private.has_school_access(school_id,array['proprietor','administrator','registrar','head_teacher','vice_principal']::public.school_member_role[]));

-- Cross-table integrity: a caller cannot smuggle a foreign-school FK into an allowed tenant row.
create or replace function private.schoolpro_validate_operational_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare ref_school uuid;
begin
  if tg_table_name='schoolpro_lesson_notes' then
    if new.subject_id is not null then select school_id into ref_school from public.schoolpro_subjects where id=new.subject_id; if ref_school is distinct from new.school_id then raise exception 'Subject belongs to another school'; end if; end if;
    if new.class_id is not null then select school_id into ref_school from public.schoolpro_classes where id=new.class_id; if ref_school is distinct from new.school_id then raise exception 'Class belongs to another school'; end if; end if;
  elsif tg_table_name='schoolpro_result_approvals' then
    select school_id into ref_school from public.schoolpro_results where id=new.result_id;
    if ref_school is distinct from new.school_id then raise exception 'Result belongs to another school'; end if;
  elsif tg_table_name='schoolpro_promotions' then
    select school_id into ref_school from public.schoolpro_students where id=new.student_id;
    if ref_school is distinct from new.school_id then raise exception 'Student belongs to another school'; end if;
  end if;
  return new;
end $$;
revoke all on function private.schoolpro_validate_operational_tenant() from public,anon,authenticated;

drop trigger if exists validate_schoolpro_lesson_notes_tenant on public.schoolpro_lesson_notes;
create trigger validate_schoolpro_lesson_notes_tenant before insert or update on public.schoolpro_lesson_notes for each row execute function private.schoolpro_validate_operational_tenant();
drop trigger if exists validate_schoolpro_result_approvals_tenant on public.schoolpro_result_approvals;
create trigger validate_schoolpro_result_approvals_tenant before insert or update on public.schoolpro_result_approvals for each row execute function private.schoolpro_validate_operational_tenant();
drop trigger if exists validate_schoolpro_promotions_tenant on public.schoolpro_promotions;
create trigger validate_schoolpro_promotions_tenant before insert or update on public.schoolpro_promotions for each row execute function private.schoolpro_validate_operational_tenant();
