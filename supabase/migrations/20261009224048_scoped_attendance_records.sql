create policy "Scoped attendance records" on public.schoolpro_attendance as restrictive for all to authenticated
using(private.schoolpro_can_read_student(student_id))
with check(private.schoolpro_can_read_student(student_id) and exists(select 1 from public.schoolpro_students s where s.id=schoolpro_attendance.student_id and s.school_id=schoolpro_attendance.school_id and s.class_id=schoolpro_attendance.class_id));
