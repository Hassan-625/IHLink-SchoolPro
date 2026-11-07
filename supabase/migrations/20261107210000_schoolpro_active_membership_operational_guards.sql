-- Stage C0: active-membership enforcement for attendance, CBT, timetable, leave and payroll.
-- Requires the class/member lifecycle foundation and ended-appointment guards.
-- No production rows are modified by this migration.

begin;

-- CBT helper predicates were legacy direct membership readers. Keep the
-- platform Super Admin and school-owner paths, but require active profile and
-- active school membership for the membership path.
create or replace function public.schoolpro_can_author_cbt(p_school uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or exists (
        select 1 from public.schoolpro_schools s
        where s.id=p_school and s.owner_id=auth.uid()
      )
      or exists (
        select 1 from public.schoolpro_members m
        where m.school_id=p_school and m.user_id=auth.uid()
          and m.status='active'
          and m.role::text in (
            'proprietor','administrator','teacher','class_teacher',
            'exam_officer','head_teacher','vice_principal'
          )
      )
    );
$function$;

create or replace function public.schoolpro_can_manage_cbt(p_school uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or exists (
        select 1 from public.schoolpro_schools s
        where s.id=p_school and s.owner_id=auth.uid()
      )
      or exists (
        select 1 from public.schoolpro_members m
        where m.school_id=p_school and m.user_id=auth.uid()
          and m.status='active'
          and m.role::text in (
            'proprietor','administrator','exam_officer','head_teacher','vice_principal'
          )
      )
    );
$function$;

-- Attendance relation validation now also rejects archived classes for
-- operational writes. Historical enrollment is still used for session checks.
create or replace function private.validate_attendance_record()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
declare
  selected_student record;
  selected_class record;
  historical_class uuid;
begin
  select school_id,class_id,status,transferred_out_at
    into selected_student
  from public.schoolpro_students where id=new.student_id;

  select school_id,archived_at into selected_class
  from public.schoolpro_classes where id=new.class_id;

  if selected_student.school_id is null or selected_class.school_id is null
     or selected_student.school_id<>new.school_id
     or selected_class.school_id<>new.school_id then
    raise exception 'Student and class must belong to the selected school';
  end if;

  if selected_class.archived_at is not null then
    raise exception 'Archived classes cannot receive attendance changes';
  end if;

  if selected_student.status<>'active' or selected_student.transferred_out_at is not null then
    raise exception 'Inactive or transferred students cannot receive new attendance activity';
  end if;

  if nullif(new.session,'') is not null then
    select class_id into historical_class
    from public.schoolpro_enrollment_history
    where school_id=new.school_id and student_id=new.student_id
      and session=new.session;
  end if;

  if coalesce(historical_class,selected_student.class_id) is distinct from new.class_id then
    raise exception 'Student is not enrolled in the selected class and session';
  end if;
  return new;
end;
$function$;

-- CBT eligibility may be assigned only to active students and non-archived
-- classes. Test execution/history remains untouched.
create or replace function private.validate_schoolpro_cbt_eligibility()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
begin
  if not exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=new.test_id and t.school_id=new.school_id
  ) then raise exception 'CBT test does not belong to eligibility school'; end if;

  if new.student_id is not null and not exists (
    select 1 from public.schoolpro_students s
    where s.id=new.student_id and s.school_id=new.school_id
      and s.status='active' and s.transferred_out_at is null
  ) then raise exception 'Eligible student must be active in this school'; end if;

  if new.class_id is not null and not exists (
    select 1 from public.schoolpro_classes c
    where c.id=new.class_id and c.school_id=new.school_id
      and c.archived_at is null
  ) then raise exception 'Choose an active class from this school'; end if;

  if new.student_id is null and new.class_id is null then
    raise exception 'Eligibility must target a student or class';
  end if;
  return new;
end;
$function$;

-- Timetable staff reads are scoped to active membership. Teachers only see
-- classes for which they retain an active Form Master or subject appointment.
drop policy if exists "manager timetable" on public.schoolpro_timetable_entries;
drop policy if exists "member read timetable" on public.schoolpro_timetable_entries;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_timetable_entries;

create policy "C0 active staff timetable read"
on public.schoolpro_timetable_entries for select to authenticated
using (
  private.is_admin(array['super_admin']::public.user_role[])
  or exists (
    select 1 from public.schoolpro_schools s
    where s.id=schoolpro_timetable_entries.school_id and s.owner_id=auth.uid()
  )
  or exists (
    select 1 from public.schoolpro_members m
    where m.school_id=schoolpro_timetable_entries.school_id
      and m.user_id=auth.uid() and m.status='active'
      and (
        m.role::text not in ('teacher','class_teacher')
        or exists (
          select 1 from public.schoolpro_classes c
          where c.id=schoolpro_timetable_entries.class_id
            and c.school_id=schoolpro_timetable_entries.school_id
            and c.archived_at is null
            and (
              c.form_teacher_id=m.id
              or exists (
                select 1 from public.schoolpro_subject_assignments a
                where a.school_id=c.school_id and a.class_id=c.id
                  and a.teacher_member_id=m.id and a.ended_at is null
              )
            )
        )
      )
  )
);

create policy "C0 timetable manager insert"
on public.schoolpro_timetable_entries for insert to authenticated
with check (
  private.schoolpro_module_allowed(school_id,'timetable')
  and (
    private.has_school_access(school_id,array[
      'proprietor','administrator','head_teacher','vice_principal'
    ]::public.school_member_role[])
  )
  and (class_id is null or exists (
    select 1 from public.schoolpro_classes c
    where c.id=schoolpro_timetable_entries.class_id and c.school_id=schoolpro_timetable_entries.school_id and c.archived_at is null
  ))
);

create policy "C0 timetable manager update"
on public.schoolpro_timetable_entries for update to authenticated
using (
  private.schoolpro_module_allowed(school_id,'timetable')
  and private.has_school_access(school_id,array[
    'proprietor','administrator','head_teacher','vice_principal'
  ]::public.school_member_role[])
)
with check (
  private.schoolpro_module_allowed(school_id,'timetable')
  and private.has_school_access(school_id,array[
    'proprietor','administrator','head_teacher','vice_principal'
  ]::public.school_member_role[])
  and (class_id is null or exists (
    select 1 from public.schoolpro_classes c
    where c.id=schoolpro_timetable_entries.class_id and c.school_id=schoolpro_timetable_entries.school_id and c.archived_at is null
  ))
);

create policy "C0 timetable manager delete"
on public.schoolpro_timetable_entries for delete to authenticated
using (
  private.schoolpro_module_allowed(school_id,'timetable')
  and private.has_school_access(school_id,array[
    'proprietor','administrator','head_teacher','vice_principal'
  ]::public.school_member_role[])
);

-- Attendance write policies used to permit writes through broad ALL policies.
-- Split reads from writes and require an active Form Master assignment or
-- active school leadership. Family historical reads remain in their own policy.
drop policy if exists "School educators insert attendance" on public.schoolpro_attendance;
drop policy if exists "School educators update attendance" on public.schoolpro_attendance;
drop policy if exists "Scoped attendance records" on public.schoolpro_attendance;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_attendance;

create policy "C0 attendance scoped read"
on public.schoolpro_attendance for select to authenticated
using (
  private.schoolpro_can_read_student(student_id)
  or private.has_school_access(school_id)
);

create policy "C0 attendance active staff insert"
on public.schoolpro_attendance for insert to authenticated
with check (
  marked_by=auth.uid()
  and private.schoolpro_module_allowed(school_id,'attendance')
  and (
    private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
    or exists (
      select 1 from public.schoolpro_classes c
      join public.schoolpro_members m
        on m.id=c.form_teacher_id and m.school_id=c.school_id
      where c.id=schoolpro_attendance.class_id
        and c.school_id=schoolpro_attendance.school_id
        and c.archived_at is null
        and m.user_id=auth.uid() and m.status='active'
        and m.role::text in ('teacher','class_teacher')
        and not exists (
          select 1 from public.schoolpro_member_permissions p
          where p.member_id=m.id and p.permission='attendance' and p.allowed=false
        )
    )
  )
);

create policy "C0 attendance active staff update"
on public.schoolpro_attendance for update to authenticated
using (
  private.schoolpro_module_allowed(school_id,'attendance')
  and (
    private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
    or exists (
      select 1 from public.schoolpro_classes c
      join public.schoolpro_members m
        on m.id=c.form_teacher_id and m.school_id=c.school_id
      where c.id=schoolpro_attendance.class_id
        and c.school_id=schoolpro_attendance.school_id
        and c.archived_at is null
        and m.user_id=auth.uid() and m.status='active'
        and m.role::text in ('teacher','class_teacher')
        and not exists (
          select 1 from public.schoolpro_member_permissions p
          where p.member_id=m.id and p.permission='attendance' and p.allowed=false
        )
    )
  )
)
with check (
  marked_by=auth.uid()
  and private.schoolpro_module_allowed(school_id,'attendance')
  and (
    private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
    or exists (
      select 1 from public.schoolpro_classes c
      join public.schoolpro_members m
        on m.id=c.form_teacher_id and m.school_id=c.school_id
      where c.id=schoolpro_attendance.class_id
        and c.school_id=schoolpro_attendance.school_id
        and c.archived_at is null
        and m.user_id=auth.uid() and m.status='active'
        and m.role::text in ('teacher','class_teacher')
        and not exists (
          select 1 from public.schoolpro_member_permissions p
          where p.member_id=m.id and p.permission='attendance' and p.allowed=false
        )
    )
  )
);

-- Remove the legacy plan-feature ALL policy from CBT eligibility; its manager
-- policy now delegates to the active-membership-aware helper above.
drop policy if exists "schoolpro_plan_access" on public.schoolpro_cbt_eligibility;

-- A staff member can update the reason on their own still-pending leave request.
-- This is deliberately not an approval path; review remains leadership/HR only.
drop policy if exists "leave own request" on public.schoolpro_leave_requests;
create policy "leave own request"
on public.schoolpro_leave_requests for insert to authenticated
with check (
  private.schoolpro_module_allowed(school_id,'leave')
  and status='pending'
  and exists (
    select 1 from public.schoolpro_members m
    where m.id=schoolpro_leave_requests.member_id and m.school_id=schoolpro_leave_requests.school_id
      and m.user_id=auth.uid() and m.status='active'
  )
);

create policy "C0 leave own pending update"
on public.schoolpro_leave_requests for update to authenticated
using (
  status='pending'
  and exists (
    select 1 from public.schoolpro_members m
    where m.id=schoolpro_leave_requests.member_id and m.school_id=schoolpro_leave_requests.school_id
      and m.user_id=auth.uid() and m.status='active'
  )
)
with check (
  status='pending'
  and exists (
    select 1 from public.schoolpro_members m
    where m.id=schoolpro_leave_requests.member_id and m.school_id=schoolpro_leave_requests.school_id
      and m.user_id=auth.uid() and m.status='active'
  )
);

-- Payroll rows may only be created for active staff memberships. Existing
-- approved/paid history is retained and the original workflow validator still
-- controls transitions and payment references.
create or replace function private.guard_schoolpro_active_payroll_member()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
begin
  if tg_op='INSERT' or new.member_id is distinct from old.member_id then
    if new.member_id is null or not exists (
      select 1 from public.schoolpro_members m
      where m.id=new.member_id and m.school_id=new.school_id
        and m.status='active'
    ) then
      raise exception 'Payroll must reference an active staff membership';
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists schoolpro_active_payroll_member on public.schoolpro_payroll_records;
create trigger schoolpro_active_payroll_member
before insert or update of member_id,school_id on public.schoolpro_payroll_records
for each row execute function private.guard_schoolpro_active_payroll_member();

-- Leave creation must belong to an active member. Existing pending requests
-- retain their original ownership and can be reviewed through the HR policy.
create or replace function private.guard_schoolpro_active_leave_member()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
begin
  if tg_op='INSERT' or new.member_id is distinct from old.member_id then
    if new.member_id is null or not exists (
      select 1 from public.schoolpro_members m
      where m.id=new.member_id and m.school_id=new.school_id
        and m.status='active'
    ) then
      raise exception 'Leave requests must belong to an active staff membership';
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists schoolpro_active_leave_member on public.schoolpro_leave_requests;
create trigger schoolpro_active_leave_member
before insert or update of member_id,school_id on public.schoolpro_leave_requests
for each row execute function private.guard_schoolpro_active_leave_member();

revoke all on function private.guard_schoolpro_active_payroll_member() from public,anon,authenticated;
revoke all on function private.guard_schoolpro_active_leave_member() from public,anon,authenticated;

commit;
