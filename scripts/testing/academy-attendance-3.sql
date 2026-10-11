begin;
select set_config('request.jwt.claim.sub','7a65cdab-a9c3-412d-b5d8-7d1bcd857c1d',true);
select set_config('request.jwt.claims','{"sub":"7a65cdab-a9c3-412d-b5d8-7d1bcd857c1d","role":"authenticated"}',true);
do $$ begin if not exists(select 1 from public.schoolpro_schools where id='d342eb87-8d6a-477a-a380-7fab83f586b7' and owner_id='7a65cdab-a9c3-412d-b5d8-7d1bcd857c1d' and name='IHLINK ACADEMY (Testing)') then raise exception 'Expected testing school not found; refusing to seed';end if;end $$;

with days as(select d::date attendance_date,row_number()over(order by d)day_no from generate_series(date '2026-04-20',date '2026-07-10',interval '1 day') d where extract(isodow from d)<6)
insert into public.schoolpro_attendance(school_id,class_id,student_id,attendance_date,status,notes,marked_by)
select 'd342eb87-8d6a-477a-a380-7fab83f586b7',s.class_id,s.id,d.attendance_date,
 (case when mod(right(s.admission_number,3)::int*7+d.day_no+3,20)=0 then 'excused' when mod(right(s.admission_number,3)::int*7+d.day_no+3,20)in(1,2) then 'absent' when mod(right(s.admission_number,3)::int*7+d.day_no+3,20)=3 then 'late' else 'present' end)::public.schoolpro_attendance_status,
 'Synthetic attendance for Academy testing only','7a65cdab-a9c3-412d-b5d8-7d1bcd857c1d' from public.schoolpro_students s cross join days d where s.school_id='d342eb87-8d6a-477a-a380-7fab83f586b7' and s.admission_number like 'IH-TST-2026-%' on conflict(student_id,attendance_date)do nothing;
commit;
select 'Third Term attendance saved' as result;
