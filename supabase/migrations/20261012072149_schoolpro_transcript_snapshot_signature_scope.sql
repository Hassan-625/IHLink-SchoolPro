CREATE OR REPLACE FUNCTION private.schoolpro_transcript_enrichment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
new.snapshot:=new.snapshot||jsonb_build_object('school_id',new.school_id,'format_version',2,'officers',coalesce((select officers from public.schoolpro_transcript_settings where school_id=new.school_id),'[]'::jsonb),'logo_url',(select logo_url from public.schoolpro_branding where school_id=new.school_id limit 1),
'period_details',coalesce((select jsonb_agg(jsonb_build_object('session',p.session,'term',p.term,'attendance',(select jsonb_build_object('recorded',count(*),'present',count(*)filter(where a.status::text in('present','late')),'absent',count(*)filter(where a.status::text='absent'),'excused',count(*)filter(where a.status::text='excused')) from public.schoolpro_attendance a where a.school_id=new.school_id and a.student_id=new.student_id and a.session=p.session and a.term=p.term),
'ratings',coalesce((select jsonb_agg(jsonb_build_object('name',d.name,'domain',d.domain_type,'rating',coalesce(nullif(r.rating_label,''),r.rating::text))order by d.position)from public.schoolpro_result_domain_ratings r join public.schoolpro_result_domain_definitions d on d.id=r.definition_id and d.school_id=r.school_id where r.school_id=new.school_id and r.student_id=new.student_id and r.session=p.session and r.term=p.term),'[]'::jsonb),
'teacher_comments',coalesce((select jsonb_agg(distinct teacher_comment) filter(where nullif(teacher_comment,'')is not null)from public.schoolpro_results r where r.student_id=new.student_id and r.school_id=new.school_id and r.session=p.session and r.term=p.term and r.status='published'),'[]'::jsonb),
'principal_comments',coalesce((select jsonb_agg(distinct head_teacher_comment) filter(where nullif(head_teacher_comment,'')is not null)from public.schoolpro_results r where r.student_id=new.student_id and r.school_id=new.school_id and r.session=p.session and r.term=p.term and r.status='published'),'[]'::jsonb))
 order by p.session,p.term) from(select distinct r.session,r.term from public.schoolpro_results r where r.student_id=new.student_id and r.school_id=new.school_id and r.status='published')p),'[]'::jsonb));
return new;
end $function$
;