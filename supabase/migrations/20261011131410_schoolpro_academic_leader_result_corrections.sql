CREATE OR REPLACE FUNCTION private.enforce_result_workflow()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.status = 'published' and (new.ca_score <> old.ca_score or new.exam_score <> old.exam_score or new.assessment_scores is distinct from old.assessment_scores or new.assessment_scheme_id is distinct from old.assessment_scheme_id) then
    raise exception 'Published results are locked';
  end if;
  if new.status is distinct from old.status and not (private.is_admin(array['super_admin']::public.user_role[]) or private.has_school_access(new.school_id, array['proprietor','administrator','exam_officer','head_teacher','vice_principal']::public.school_member_role[])) then
    raise exception 'Only school leaders can approve or publish results';
  end if;
  if new.status = 'approved' and old.status <> 'approved' then new.approved_by := auth.uid(); new.approved_at := now(); end if;
  if new.status = 'published' and old.status <> 'published' then new.published_at := now(); end if;
  return new;
end;
$function$
;
