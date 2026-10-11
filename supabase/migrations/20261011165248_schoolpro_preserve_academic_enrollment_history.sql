create table public.schoolpro_enrollment_history(
 school_id uuid not null references public.schoolpro_schools(id),
 student_id uuid not null references public.schoolpro_students(id),
 session text not null check(session ~ '^[0-9]{4}/[0-9]{4}$'),
 class_id uuid not null references public.schoolpro_classes(id),
 class_name text not null, arm text not null default '', section text not null,
 status text not null check(status in ('active','completed','graduated','repeated')),
 graduation_year integer, promotion_id uuid references public.schoolpro_promotions(id),
 created_at timestamptz not null default now(),
 primary key(school_id,student_id,session)
);
create index schoolpro_enrollment_history_class_period_idx on public.schoolpro_enrollment_history(school_id,session,class_id);
alter table public.schoolpro_enrollment_history enable row level security;
grant select on public.schoolpro_enrollment_history to authenticated;
grant all on public.schoolpro_enrollment_history to service_role;
create policy "Authorized school enrollment history" on public.schoolpro_enrollment_history for select to authenticated using(
 auth.uid() is not null and (
 private.is_admin(array['super_admin'::public.user_role])
 or (private.schoolpro_module_allowed(school_id,'students') and public.schoolpro_member_can_manage(school_id))
 or exists(select 1 from public.schoolpro_students s where s.id=student_id and s.school_id=schoolpro_enrollment_history.school_id and s.user_id=auth.uid())
 or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=schoolpro_enrollment_history.student_id and g.school_id=schoolpro_enrollment_history.school_id and g.guardian_user_id=auth.uid() and g.status='active')
 ));
create function private.schoolpro_archive_progression() returns trigger language plpgsql security definer set search_path='' as $$
declare oldclass public.schoolpro_classes; nextclass public.schoolpro_classes; nextsession text; yearstart integer;
begin
 if new.status<>'applied' or old.status='applied' then return new;end if;
 if new.session !~ '^[0-9]{4}/[0-9]{4}$' then raise exception 'Select a valid source academic session';end if;
 yearstart:=split_part(new.session,'/',1)::integer;
 if split_part(new.session,'/',2)::integer<>yearstart+1 then raise exception 'Academic session must span consecutive years';end if;
 select * into oldclass from public.schoolpro_classes where id=new.from_class_id and school_id=new.school_id;
 if oldclass.id is null then raise exception 'Source class does not belong to this school';end if;
 if not exists(select 1 from public.schoolpro_students where id=new.student_id and school_id=new.school_id) then raise exception 'Student does not belong to this school';end if;
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id,class_name,arm,section,status,graduation_year,promotion_id)
 values(new.school_id,new.student_id,new.session,oldclass.id,oldclass.name,oldclass.arm,oldclass.level,case when new.decision='graduated' then 'graduated' else 'completed' end,case when new.decision='graduated' then yearstart+1 end,new.id)
 on conflict(school_id,student_id,session) do update set status=excluded.status,graduation_year=excluded.graduation_year,promotion_id=excluded.promotion_id;
 if new.decision in ('promoted','repeated') then
 select * into nextclass from public.schoolpro_classes where id=new.to_class_id and school_id=new.school_id;
 if nextclass.id is null then raise exception 'Destination class does not belong to this school';end if;
 nextsession:=(yearstart+1)::text||'/'||(yearstart+2)::text;
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id,class_name,arm,section,status,promotion_id)
 values(new.school_id,new.student_id,nextsession,nextclass.id,nextclass.name,nextclass.arm,nextclass.level,'active',new.id)
 on conflict(school_id,student_id,session) do nothing;
 end if;
 return new;
end $$;
revoke all on function private.schoolpro_archive_progression() from public,anon,authenticated;
create trigger schoolpro_archive_applied_progression after update of status on public.schoolpro_promotions for each row execute function private.schoolpro_archive_progression();
