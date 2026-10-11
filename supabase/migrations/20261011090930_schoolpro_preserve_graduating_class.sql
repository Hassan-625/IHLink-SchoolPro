CREATE OR REPLACE FUNCTION public.apply_schoolpro_promotion(p_promotion uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare p public.schoolpro_promotions;c public.schoolpro_classes;s public.schoolpro_students;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into p from public.schoolpro_promotions where id=p_promotion for update;
 if p.id is null then raise exception 'Progression not found';end if;
 if not private.schoolpro_module_allowed(p.school_id,'promotions') then raise exception 'Module permission denied';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(p.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role,'registrar'::public.school_member_role])) then raise exception 'Not authorized';end if;
 if p.status='applied' then return;end if;
 if p.status<>'pending' then raise exception 'Progression is not pending';end if;
 select * into s from public.schoolpro_students where id=p.student_id and school_id=p.school_id for update;
 if s.id is null then raise exception 'Student not found';end if;
 if s.status<>'active' then raise exception 'Only active students can receive progression decisions';end if;
 if s.class_id is distinct from p.from_class_id then raise exception 'Student class changed after progression decision; create a new decision';end if;
 if p.decision in('promoted','repeated') then
  select * into c from public.schoolpro_classes where id=p.to_class_id and school_id=p.school_id;
  if c.id is null then raise exception 'Destination class invalid';end if;
  update public.schoolpro_students set class_id=c.id,class_name=concat_ws(' ',c.name,nullif(c.arm,'')),status='active' where id=s.id;
 elsif p.decision='graduated' then
  update public.schoolpro_students set status='graduated' where id=s.id;
 end if;
 update public.schoolpro_promotions set status='applied',applied_by=auth.uid(),applied_at=now() where id=p.id;
end $function$

