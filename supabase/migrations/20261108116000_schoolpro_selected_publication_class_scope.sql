-- Selected-student publication must remain inside the selected class/session roster.
-- The old five-argument overload is removed so callers cannot bypass the new scope.
drop function if exists public.publish_schoolpro_selected_results(uuid,text,text,uuid[],boolean);

create function public.publish_schoolpro_selected_results(
  p_school uuid,
  p_term text,
  p_session text,
  p_students uuid[] default null,
  p_all boolean default false,
  p_class uuid default null
) returns integer
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_published integer;
begin
  if auth.uid() is null
     or not coalesce(private.schoolpro_module_allowed(p_school,'results'),false)
     or not (
       public.schoolpro_member_can_manage(p_school)
       or exists (
         select 1 from public.schoolpro_members m
         where m.school_id=p_school and m.user_id=auth.uid()
           and m.status='active'
           and m.role::text in ('exam_officer','head_teacher','vice_principal')
       )
     ) then
    raise exception 'Result publication permission required';
  end if;

  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
    raise exception 'Select an academic period';
  end if;

  if p_all then
    if coalesce(cardinality(p_students),0)>0 or p_class is not null then
      raise exception 'Choose one publication scope';
    end if;
  else
    if p_class is null or not exists (
      select 1 from public.schoolpro_classes c
      where c.id=p_class and c.school_id=p_school
    ) then
      raise exception 'Select a class in this school';
    end if;
    if coalesce(cardinality(p_students),0)=0 then
      raise exception 'Select students to publish';
    end if;
    if cardinality(p_students)>5000 then
      raise exception 'Select no more than 5000 students at a time';
    end if;
    if exists(select 1 from unnest(p_students) x(id) where x.id is null)
       or (select count(distinct x.id) from unnest(p_students) x(id))<>cardinality(p_students) then
      raise exception 'Invalid or duplicate student selection';
    end if;
    perform s.id from public.schoolpro_students s
    where s.school_id=p_school and s.id=any(p_students)
    order by s.id for update;
    if (
      select count(*)
      from unnest(p_students) x(id)
      join public.schoolpro_students s on s.id=x.id and s.school_id=p_school
      where exists (
        select 1 from public.schoolpro_enrollment_history h
        where h.school_id=p_school and h.student_id=s.id
          and h.session=trim(p_session) and h.class_id=p_class
      )
      or (
        s.status='active' and s.class_id=p_class
        and not exists (
          select 1 from public.schoolpro_enrollment_history h
          where h.school_id=p_school and h.student_id=s.id
            and h.session=trim(p_session)
        )
      )
    )<>cardinality(p_students) then
      raise exception 'Every selected student must belong to this class roster for the selected session';
    end if;
  end if;

  -- Lock the exact result rows that will be published.
  perform r.id
  from public.schoolpro_results r
  join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  where r.school_id=p_school and r.term=trim(p_term)
    and r.session=trim(p_session) and r.status='approved' and not r.locked
    and (s.status='active' or exists (
      select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id and h.session=r.session
    ))
    and (
      p_all
      or (
        s.id=any(p_students)
        and (
          exists (
            select 1 from public.schoolpro_enrollment_history h
            where h.school_id=p_school and h.student_id=s.id
              and h.session=r.session and h.class_id=p_class
          )
          or (
            s.status='active' and s.class_id=p_class
            and not exists (
              select 1 from public.schoolpro_enrollment_history h
              where h.school_id=p_school and h.student_id=s.id and h.session=r.session
            )
          )
        )
      )
    )
  order by r.id
  for update of r;

  if exists (
    select 1
    from public.schoolpro_results r
    join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
    where r.school_id=p_school and r.term=trim(p_term)
      and r.session=trim(p_session) and r.status='approved' and not r.locked
      and (s.status='active' or exists (
        select 1 from public.schoolpro_enrollment_history h
        where h.school_id=p_school and h.student_id=s.id and h.session=r.session
      ))
      and (
        p_all
        or (
          s.id=any(p_students)
          and (
            exists (
              select 1 from public.schoolpro_enrollment_history h
              where h.school_id=p_school and h.student_id=s.id
                and h.session=r.session and h.class_id=p_class
            )
            or (
              s.status='active' and s.class_id=p_class
              and not exists (
                select 1 from public.schoolpro_enrollment_history h
                where h.school_id=p_school and h.student_id=s.id and h.session=r.session
              )
            )
          )
        )
      )
      and not private.schoolpro_result_assessment_complete(r.id)
  ) then
    raise exception 'Selected students contain incomplete approved assessments; return them for correction before publication';
  end if;

  update public.schoolpro_results r
  set status='published',published_at=now(),locked=true
  from public.schoolpro_students s
  where s.id=r.student_id and s.school_id=r.school_id
    and r.school_id=p_school and r.term=trim(p_term)
    and r.session=trim(p_session) and r.status='approved' and not r.locked
    and (s.status='active' or exists (
      select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id and h.session=r.session
    ))
    and (
      p_all
      or (
        s.id=any(p_students)
        and (
          exists (
            select 1 from public.schoolpro_enrollment_history h
            where h.school_id=p_school and h.student_id=s.id
              and h.session=r.session and h.class_id=p_class
          )
          or (
            s.status='active' and s.class_id=p_class
            and not exists (
              select 1 from public.schoolpro_enrollment_history h
              where h.school_id=p_school and h.student_id=s.id and h.session=r.session
            )
          )
        )
      )
    );

  get diagnostics v_published=row_count;
  insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
  values(
    auth.uid(),'Selected results published','schoolpro','school',p_school::text,
    jsonb_build_object(
      'term',p_term,'session',p_session,'all_students',p_all,
      'class_id',p_class,'students',p_students,'published',v_published
    )
  );
  return v_published;
end
$function$;

revoke all on function public.publish_schoolpro_selected_results(uuid,text,text,uuid[],boolean,uuid) from public,anon;
grant execute on function public.publish_schoolpro_selected_results(uuid,text,text,uuid[],boolean,uuid) to authenticated;
