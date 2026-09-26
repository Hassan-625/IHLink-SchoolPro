create type public.schoolpro_attendance_status as enum ('present','absent','late','excused');

create table public.schoolpro_subject_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  subject_id uuid not null references public.schoolpro_subjects(id) on delete cascade,
  teacher_member_id uuid references public.schoolpro_members(id) on delete set null,
  session text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (class_id, subject_id, session)
);
create index schoolpro_subject_assignments_school_idx on public.schoolpro_subject_assignments (school_id, session);
create index schoolpro_subject_assignments_teacher_idx on public.schoolpro_subject_assignments (teacher_member_id);
alter table public.schoolpro_subject_assignments enable row level security;
create policy "School users read subject assignments" on public.schoolpro_subject_assignments for select to authenticated using (private.has_school_access(school_id));
create policy "School leaders insert subject assignments" on public.schoolpro_subject_assignments for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders update subject assignments" on public.schoolpro_subject_assignments for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders delete subject assignments" on public.schoolpro_subject_assignments for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
grant select,insert,update,delete on public.schoolpro_subject_assignments to authenticated;

create or replace function private.validate_subject_assignment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare class_school uuid; subject_school uuid; member_school uuid; member_role public.school_member_role;
begin
  select school_id into class_school from public.schoolpro_classes where id=new.class_id;
  select school_id into subject_school from public.schoolpro_subjects where id=new.subject_id;
  if class_school is null or subject_school is null or class_school<>new.school_id or subject_school<>new.school_id then raise exception 'Class and subject must belong to the selected school'; end if;
  if new.teacher_member_id is not null then
    select school_id,role into member_school,member_role from public.schoolpro_members where id=new.teacher_member_id;
    if member_school is null or member_school<>new.school_id or member_role not in ('teacher','administrator','proprietor') then raise exception 'Assigned teacher must be an eligible member of this school'; end if;
  end if;
  return new;
end; $$;
revoke all on function private.validate_subject_assignment() from public,anon,authenticated;
create trigger validate_schoolpro_subject_assignment before insert or update on public.schoolpro_subject_assignments for each row execute procedure private.validate_subject_assignment();

create table public.schoolpro_attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  attendance_date date not null default current_date,
  status public.schoolpro_attendance_status not null default 'present',
  notes text,
  marked_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, attendance_date)
);
create index schoolpro_attendance_school_date_idx on public.schoolpro_attendance (school_id, attendance_date desc);
create index schoolpro_attendance_class_date_idx on public.schoolpro_attendance (class_id, attendance_date desc);
create index schoolpro_attendance_marked_by_idx on public.schoolpro_attendance (marked_by);
alter table public.schoolpro_attendance enable row level security;
create policy "School users read attendance" on public.schoolpro_attendance for select to authenticated using (private.has_school_access(school_id));
create policy "School educators insert attendance" on public.schoolpro_attendance for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[]) and marked_by=(select auth.uid()));
create policy "School educators update attendance" on public.schoolpro_attendance for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator','teacher']::public.school_member_role[]) and marked_by=(select auth.uid()));
create policy "School leaders delete attendance" on public.schoolpro_attendance for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
grant select,insert,update,delete on public.schoolpro_attendance to authenticated;

create or replace function private.validate_attendance_record()
returns trigger language plpgsql security definer set search_path = '' as $$
declare selected_student record; class_school uuid;
begin
  select school_id,class_id into selected_student from public.schoolpro_students where id=new.student_id;
  select school_id into class_school from public.schoolpro_classes where id=new.class_id;
  if selected_student.school_id is null or class_school is null or selected_student.school_id<>new.school_id or class_school<>new.school_id then raise exception 'Student and class must belong to the selected school'; end if;
  if selected_student.class_id is distinct from new.class_id then raise exception 'Student is not enrolled in the selected class'; end if;
  return new;
end; $$;
revoke all on function private.validate_attendance_record() from public,anon,authenticated;
create trigger validate_schoolpro_attendance before insert or update on public.schoolpro_attendance for each row execute procedure private.validate_attendance_record();

create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id,email,first_name,last_name,requested_service,role)
  values (new.id,coalesce(new.email,''),new.raw_user_meta_data->>'first_name',new.raw_user_meta_data->>'last_name',new.raw_user_meta_data->>'requested_service',case when lower(coalesce(new.email,''))='hassanisahassan12@gmail.com' then 'super_admin'::public.user_role else 'customer'::public.user_role end);
  insert into public.datasub_wallets (user_id) values (new.id);
  if lower(coalesce(new.email,''))='hassanisahassan12@gmail.com' then
    insert into public.admin_product_access (user_id,product,can_view,can_edit,can_approve)
    select new.id,product,true,true,true from unnest(array['corporate','datasub','schoolpro','consult','host','engineering']) as product;
  end if;
  return new;
end; $$;
revoke all on function private.handle_new_user() from public,anon,authenticated;

insert into public.admin_product_access (user_id,product,can_view,can_edit,can_approve)
select p.id,product,true,true,true from public.profiles p cross join unnest(array['corporate','datasub','schoolpro','consult','host','engineering']) as product
where lower(p.email)='hassanisahassan12@gmail.com'
on conflict (user_id,product) do update set can_view=true,can_edit=true,can_approve=true;
