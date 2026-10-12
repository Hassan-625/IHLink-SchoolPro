create or replace function private.validate_attendance_record() returns trigger language plpgsql security definer set search_path='' as $$
declare selected_student record; class_school uuid; historical_class uuid;
begin
 select school_id,class_id into selected_student from public.schoolpro_students where id=new.student_id;
 select school_id into class_school from public.schoolpro_classes where id=new.class_id;
 if selected_student.school_id is null or class_school is null or selected_student.school_id<>new.school_id or class_school<>new.school_id then raise exception 'Student and class must belong to the selected school';end if;
 if nullif(new.session,'') is not null then select class_id into historical_class from public.schoolpro_enrollment_history where school_id=new.school_id and student_id=new.student_id and session=new.session;end if;
 if coalesce(historical_class,selected_student.class_id) is distinct from new.class_id then raise exception 'Student is not enrolled in the selected class and session';end if;
 return new;
end $$;