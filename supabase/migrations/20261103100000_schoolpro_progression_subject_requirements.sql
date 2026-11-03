-- Stage B1: optional school-configured subject minimums for year-end progression.
-- A configured subject is evaluated against its three published term averages.
-- No configured rules preserves the existing 45% annual-average-only behaviour.

create table if not exists public.schoolpro_progression_subject_requirements (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  subject_id uuid not null references public.schoolpro_subjects(id) on delete cascade,
  minimum_score numeric(5,2) not null default 45
    check (minimum_score >= 0 and minimum_score <= 100),
  enabled boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schoolpro_progression_subject_requirements_school_subject_unique
    unique (school_id, subject_id)
);

create index if not exists schoolpro_progression_subject_requirements_enabled_idx
  on public.schoolpro_progression_subject_requirements (school_id, subject_id)
  where enabled;

create or replace function private.schoolpro_validate_progression_subject_requirement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_subject_school uuid;
begin
  select school_id into v_subject_school
  from public.schoolpro_subjects
  where id = new.subject_id;
  if v_subject_school is null or v_subject_school is distinct from new.school_id then
    raise exception 'Progression requirement subject must belong to the selected school';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.schoolpro_validate_progression_subject_requirement() from public, anon, authenticated;

drop trigger if exists schoolpro_progression_subject_requirement_tenant_guard
  on public.schoolpro_progression_subject_requirements;
create trigger schoolpro_progression_subject_requirement_tenant_guard
before insert or update of school_id, subject_id
on public.schoolpro_progression_subject_requirements
for each row execute function private.schoolpro_validate_progression_subject_requirement();

alter table public.schoolpro_progression_subject_requirements enable row level security;
alter table public.schoolpro_progression_subject_requirements force row level security;

drop policy if exists "Progression managers read subject requirements"
  on public.schoolpro_progression_subject_requirements;
create policy "Progression managers read subject requirements"
on public.schoolpro_progression_subject_requirements
for select to authenticated
using (
  private.schoolpro_module_allowed(school_id, 'promotions')
  and (
    private.is_admin(array['super_admin'::public.user_role])
    or private.has_school_access(
      school_id,
      array[
        'proprietor'::public.school_member_role,
        'administrator'::public.school_member_role,
        'head_teacher'::public.school_member_role,
        'vice_principal'::public.school_member_role,
        'registrar'::public.school_member_role
      ]
    )
  )
);

drop policy if exists "Progression managers manage subject requirements"
  on public.schoolpro_progression_subject_requirements;
create policy "Progression managers manage subject requirements"
on public.schoolpro_progression_subject_requirements
for all to authenticated
using (
  private.schoolpro_module_allowed(school_id, 'promotions')
  and (
    private.is_admin(array['super_admin'::public.user_role])
    or private.has_school_access(
      school_id,
      array[
        'proprietor'::public.school_member_role,
        'administrator'::public.school_member_role,
        'head_teacher'::public.school_member_role,
        'vice_principal'::public.school_member_role,
        'registrar'::public.school_member_role
      ]
    )
  )
)
with check (
  private.schoolpro_module_allowed(school_id, 'promotions')
  and (
    private.is_admin(array['super_admin'::public.user_role])
    or private.has_school_access(
      school_id,
      array[
        'proprietor'::public.school_member_role,
        'administrator'::public.school_member_role,
        'head_teacher'::public.school_member_role,
        'vice_principal'::public.school_member_role,
        'registrar'::public.school_member_role
      ]
    )
  )
);

grant select, insert, update, delete
on public.schoolpro_progression_subject_requirements
to authenticated;

create or replace function private.schoolpro_bulk_academic_action(
  p_school uuid,
  p_session text,
  p_action text,
  p_students uuid[] default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  h record;
  target uuid;
  v_id uuid;
  v_decision text;
  v_name text;
  v_year int;
  v_average numeric;
  v_subject_average numeric;
  v_subject_terms int;
  v_subject_failures text;
  v_reason text;
  req record;
  terms int;
  processed int := 0;
  omitted jsonb := '[]';
  existing record;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_action not in ('issue_transcripts','prepare_progression','apply_progression')
    or p_session !~ '^[0-9]{4}/[0-9]{4}$' then
    raise exception 'Select a valid action and source session';
  end if;
  v_year := split_part(p_session,'/',1)::int;
  if split_part(p_session,'/',2)::int <> v_year + 1 then
    raise exception 'Select consecutive academic years';
  end if;
  if p_action = 'issue_transcripts' then
    if not private.schoolpro_can_issue_transcript(p_school) then
      raise exception 'Transcript permission required';
    end if;
  else
    if not private.schoolpro_module_allowed(p_school,'promotions')
      or not (
        private.is_admin(array['super_admin'::public.user_role])
        or private.has_school_access(
          p_school,
          array[
            'proprietor'::public.school_member_role,
            'administrator'::public.school_member_role,
            'head_teacher'::public.school_member_role,
            'vice_principal'::public.school_member_role,
            'registrar'::public.school_member_role
          ]
        )
      ) then
      raise exception 'Progression permission required';
    end if;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_school::text || p_session || p_action,0));

  for s in
    select st.*
    from public.schoolpro_students st
    join public.schoolpro_enrollment_history eh
      on eh.student_id = st.id
     and eh.school_id = st.school_id
     and eh.session = p_session
    where st.school_id = p_school
      and (p_students is null or st.id = any(p_students))
    order by st.id
  loop
    begin
      if p_action = 'apply_progression' then
        select * into existing
        from public.schoolpro_promotions
        where school_id = p_school
          and student_id = s.id
          and session = p_session
          and status = 'pending'
        order by created_at desc
        limit 1;
        if existing.id is null then continue; end if;
        perform public.apply_schoolpro_promotion(existing.id);
        processed := processed + 1;
        continue;
      end if;

      select count(*), avg(a.score)
      into terms, v_average
      from (
        select r.term, avg(r.total_score) score
        from public.schoolpro_results r
        where r.school_id = p_school
          and r.student_id = s.id
          and r.session = p_session
          and r.term in ('First Term','Second Term','Third Term')
          and r.status = 'published'
        group by r.term
      ) a;

      if terms <> 3 or exists (
        select 1
        from public.schoolpro_results r
        where r.school_id = p_school
          and r.student_id = s.id
          and r.session = p_session
          and r.status <> 'published'
      ) then
        raise exception 'All three terms must be published';
      end if;

      if p_action = 'issue_transcripts' then
        if exists (
          select 1
          from (values ('First Term'),('Second Term'),('Third Term')) t(term)
          cross join lateral public.schoolpro_result_access(s.id,t.term,p_session) a
          where not a.allowed
        ) then
          raise exception 'Result access is held by the school';
        end if;
        if exists (
          select 1
          from public.schoolpro_transcript_issues i
          where i.student_id = s.id
            and i.school_id = p_school
            and i.revoked_at is null
            and coalesce((i.snapshot->>'format_version')::int,1) >= 2
            and i.issued_at >= coalesce(
              (select max(updated_at)
               from public.schoolpro_results r
               where r.student_id = s.id and r.status = 'published'),
              '-infinity'::timestamptz
            )
        ) then
          continue;
        end if;
        perform private.schoolpro_issue_transcript(s.id);
        processed := processed + 1;
        continue;
      end if;

      if exists (
        select 1
        from public.schoolpro_promotions p
        where p.school_id = p_school
          and p.student_id = s.id
          and p.session = p_session
          and p.status in ('pending','applied')
      ) then
        continue;
      end if;

      select c.* into h
      from public.schoolpro_enrollment_history e
      join public.schoolpro_classes c
        on c.id = e.class_id and c.school_id = e.school_id
      where e.school_id = p_school
        and e.student_id = s.id
        and e.session = p_session;

      if s.status <> 'active' or s.class_id is distinct from h.id then
        raise exception 'Student has already changed class or left';
      end if;

      -- Evaluate only requirements attached to subjects offered for this
      -- student's historical class. Missing term results are skipped for
      -- review rather than silently treated as a zero or a failed subject.
      v_subject_failures := null;
      for req in
        select sub.id, sub.name, rule.minimum_score
        from public.schoolpro_progression_subject_requirements rule
        join public.schoolpro_subjects sub
          on sub.id = rule.subject_id
         and sub.school_id = rule.school_id
        where rule.school_id = p_school
          and rule.enabled
          and upper(trim(sub.class_name)) = upper(trim(h.name))
        order by sub.name
      loop
        select count(*), avg(term_score)
        into v_subject_terms, v_subject_average
        from (
          select r.term, avg(r.total_score) as term_score
          from public.schoolpro_results r
          where r.school_id = p_school
            and r.student_id = s.id
            and r.subject_id = req.id
            and r.session = p_session
            and r.term in ('First Term','Second Term','Third Term')
            and r.status = 'published'
          group by r.term
        ) subject_terms;

        if v_subject_terms <> 3 then
          raise exception 'Required subject "%" does not have published results for all three terms', req.name;
        end if;

        if v_subject_average < req.minimum_score then
          v_subject_failures := concat_ws(
            '; ',
            v_subject_failures,
            req.name || ' ' || round(v_subject_average,2)::text
              || '% (minimum ' || req.minimum_score::text || '%)'
          );
        end if;
      end loop;

      -- The overall annual average remains the default repeat rule.
      -- A failed configured subject minimum also requires the student to repeat.
      if v_average < 45 or v_subject_failures is not null then
        v_decision := 'repeated';
      elsif upper(regexp_replace(h.name,'[^a-zA-Z0-9]','','g')) in ('SS3','SSS3') then
        v_decision := 'graduated';
      else
        v_decision := 'promoted';
      end if;

      target := null;
      if v_decision = 'promoted' then
        v_name := upper(regexp_replace(h.name,'[^a-zA-Z0-9]','','g'));
        v_name := case v_name
          when 'PRENURSERY' then 'NURSERY1'
          when 'NURSERY1' then 'NURSERY2'
          when 'NURSERY2' then 'NURSERY3'
          when 'NURSERY3' then 'BASIC1'
          when 'BASIC1' then 'BASIC2'
          when 'BASIC2' then 'BASIC3'
          when 'BASIC3' then 'BASIC4'
          when 'BASIC4' then 'BASIC5'
          when 'BASIC5' then 'JSS1'
          when 'PRIMARY1' then 'PRIMARY2'
          when 'PRIMARY2' then 'PRIMARY3'
          when 'PRIMARY3' then 'PRIMARY4'
          when 'PRIMARY4' then 'PRIMARY5'
          when 'PRIMARY5' then 'JSS1'
          when 'JSS1' then 'JSS2'
          when 'JSS2' then 'JSS3'
          when 'JSS3' then 'SS1'
          when 'SS1' then 'SS2'
          when 'SS2' then 'SS3'
          when 'SSS1' then 'SSS2'
          when 'SSS2' then 'SSS3'
          else null
        end;
        select c.id into target
        from public.schoolpro_classes c
        where c.school_id = p_school
          and coalesce(c.arm,'') = coalesce(h.arm,'')
          and upper(regexp_replace(c.name,'[^a-zA-Z0-9]','','g')) = v_name
        limit 1;
        if target is null then
          raise exception 'Set the next class manually for this school naming scheme';
        end if;
      end if;

      v_reason := 'Year-end review: three published terms; average '
        || round(v_average,2) || '%.';
      if v_subject_failures is not null then
        v_reason := v_reason || ' Failed subject requirements: ' || v_subject_failures || '.';
      end if;

      v_id := public.create_schoolpro_progression(
        s.id, p_session, v_decision, target, v_reason
      );
      processed := processed + 1;

    exception when others then
      omitted := omitted || jsonb_build_array(jsonb_build_object(
        'student_id',s.id,
        'name',concat_ws(' ',s.first_name,s.last_name),
        'reason',SQLERRM
      ));
    end;
  end loop;

  return jsonb_build_object('processed',processed,'skipped',omitted);
end;
$$;

revoke all on function private.schoolpro_bulk_academic_action(uuid,text,text,uuid[])
  from public, anon;
grant execute on function private.schoolpro_bulk_academic_action(uuid,text,text,uuid[])
  to authenticated;

create or replace function public.schoolpro_bulk_academic_action(
  p_school uuid,
  p_session text,
  p_action text,
  p_students uuid[] default null
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.schoolpro_bulk_academic_action(p_school,p_session,p_action,p_students)
$$;

revoke all on function public.schoolpro_bulk_academic_action(uuid,text,text,uuid[])
  from public, anon;
grant execute on function public.schoolpro_bulk_academic_action(uuid,text,text,uuid[])
  to authenticated;
