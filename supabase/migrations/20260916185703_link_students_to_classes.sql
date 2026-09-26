alter table public.schoolpro_students add column class_id uuid references public.schoolpro_classes(id) on delete set null;
create index schoolpro_students_class_idx on public.schoolpro_students (class_id);

create or replace function private.validate_student_class()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare selected_class record;
begin
  if new.class_id is null then return new; end if;
  select school_id,name,arm into selected_class from public.schoolpro_classes where id=new.class_id;
  if selected_class.school_id is null or selected_class.school_id<>new.school_id then raise exception 'Selected class does not belong to this school'; end if;
  new.class_name:=selected_class.name||case when selected_class.arm='' then '' else ' '||selected_class.arm end;
  return new;
end; $$;
revoke all on function private.validate_student_class() from public,anon,authenticated;
create trigger validate_schoolpro_student_class before insert or update of class_id on public.schoolpro_students for each row execute procedure private.validate_student_class();
