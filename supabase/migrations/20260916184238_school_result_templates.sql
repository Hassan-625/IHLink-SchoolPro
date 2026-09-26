create table public.schoolpro_result_templates (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null unique references public.schoolpro_schools(id) on delete cascade,
  name text not null check (char_length(name) between 3 and 120),
  storage_path text not null unique,
  sheet_name text not null default 'Result',
  start_row integer not null default 10 check (start_row between 1 and 1000),
  field_cells jsonb not null default '{"school_name":"B2","student_name":"B4","admission_number":"B5","class_name":"F5","term":"B6","session":"F6"}'::jsonb,
  columns jsonb not null default '{"subject":"A","total":"G","grade":"H","status":"I"}'::jsonb,
  component_columns jsonb not null default '{}'::jsonb,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index schoolpro_result_templates_school_idx on public.schoolpro_result_templates (school_id);
alter table public.schoolpro_result_templates enable row level security;
create policy "School users read result templates" on public.schoolpro_result_templates for select to authenticated using (private.has_school_access(school_id));
create policy "School leaders insert result templates" on public.schoolpro_result_templates for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]) and updated_by=(select auth.uid()));
create policy "School leaders update result templates" on public.schoolpro_result_templates for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]) and updated_by=(select auth.uid()));
create policy "School leaders delete result templates" on public.schoolpro_result_templates for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
grant select,insert,update,delete on public.schoolpro_result_templates to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('school-result-templates','school-result-templates',false,5242880,array['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/octet-stream'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create policy "School users download result templates" on storage.objects for select to authenticated using (
 bucket_id='school-result-templates' and private.has_school_access(((storage.foldername(name))[1])::uuid)
);
create policy "School leaders upload result templates" on storage.objects for insert to authenticated with check (
 bucket_id='school-result-templates' and owner_id=(select auth.uid())::text and private.has_school_access(((storage.foldername(name))[1])::uuid,array['proprietor','administrator']::public.school_member_role[])
);
create policy "School leaders replace result templates" on storage.objects for update to authenticated using (
 bucket_id='school-result-templates' and private.has_school_access(((storage.foldername(name))[1])::uuid,array['proprietor','administrator']::public.school_member_role[])
) with check (
 bucket_id='school-result-templates' and owner_id=(select auth.uid())::text and private.has_school_access(((storage.foldername(name))[1])::uuid,array['proprietor','administrator']::public.school_member_role[])
);
create policy "School leaders delete result templates" on storage.objects for delete to authenticated using (
 bucket_id='school-result-templates' and private.has_school_access(((storage.foldername(name))[1])::uuid,array['proprietor','administrator']::public.school_member_role[])
);

