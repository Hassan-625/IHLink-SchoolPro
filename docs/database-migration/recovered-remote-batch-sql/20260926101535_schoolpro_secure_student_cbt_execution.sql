alter table public.schoolpro_cbt_attempts drop constraint if exists schoolpro_cbt_attempts_test_id_student_id_key;
alter table public.schoolpro_cbt_attempts add column if not exists attempt_no integer not null default 1;
alter table public.schoolpro_cbt_attempts add column if not exists expires_at timestamptz;
create unique index if not exists schoolpro_cbt_attempt_no_uq on public.schoolpro_cbt_attempts(test_id,student_id,attempt_no);
create index if not exists schoolpro_cbt_attempt_lookup_idx on public.schoolpro_cbt_attempts(test_id,student_id,status);

create or replace function public.start_schoolpro_cbt(p_test uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_student schoolpro_students%rowtype; v_test schoolpro_cbt_tests%rowtype; v_attempt schoolpro_cbt_attempts%rowtype; v_count int; v_allowed boolean; v_questions jsonb;
begin
 select * into v_student from schoolpro_students where user_id=auth.uid() and status='active' limit 1;
 if v_student.id is null then raise exception 'Student account is not linked to an active student record'; end if;
 select * into v_test from schoolpro_cbt_tests where id=p_test and school_id=v_student.school_id;
 if v_test.id is null then raise exception 'Test not found'; end if;
 if v_test.status <> 'published' then raise exception 'This test is not published'; end if;
 if v_test.opens_at is not null and now()<v_test.opens_at then raise exception 'This test is not open yet'; end if;
 if v_test.closes_at is not null and now()>v_test.closes_at then raise exception 'This test has closed'; end if;
 select (not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=p_test and e.eligible=true)
   or exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=p_test and e.eligible=true and (e.student_id=v_student.id or e.class_id=v_student.class_id)))
   and not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=p_test and e.student_id=v_student.id and e.eligible=false) into v_allowed;
 if not v_allowed then raise exception 'You are not eligible to take this test'; end if;
 select * into v_attempt from schoolpro_cbt_attempts where test_id=p_test and student_id=v_student.id and status='in_progress' order by attempt_no desc limit 1;
 if v_attempt.id is not null and v_attempt.expires_at is not null and now()>v_attempt.expires_at then
   update schoolpro_cbt_attempts set status='submitted',submitted_at=coalesce(submitted_at,v_attempt.expires_at) where id=v_attempt.id;
   v_attempt.id:=null;
 end if;
 if v_attempt.id is null then
   select count(*) into v_count from schoolpro_cbt_attempts where test_id=p_test and student_id=v_student.id;
   if v_count>=greatest(v_test.attempts_allowed,1) then raise exception 'Maximum attempts reached'; end if;
   insert into schoolpro_cbt_attempts(test_id,student_id,attempt_no,expires_at,status) values(p_test,v_student.id,v_count+1,now()+make_interval(mins=>greatest(v_test.duration_minutes,1)),'in_progress') returning * into v_attempt;
 end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'question_text',q.question_text,'question_type',q.question_type,'options',q.options,'marks',q.marks,'position',tq.position) order by case when v_test.randomize_questions then random() else tq.position end),'[]'::jsonb)
 into v_questions from schoolpro_cbt_test_questions tq join schoolpro_question_bank q on q.id=tq.question_id where tq.test_id=p_test;
 return jsonb_build_object('attempt_id',v_attempt.id,'attempt_no',v_attempt.attempt_no,'expires_at',v_attempt.expires_at,'test',jsonb_build_object('id',v_test.id,'title',v_test.title,'instructions',v_test.instructions,'duration_minutes',v_test.duration_minutes,'total_marks',v_test.total_marks,'randomize_options',v_test.randomize_options),'questions',v_questions,'answers',(select coalesce(jsonb_object_agg(a.question_id::text,a.answer),'{}'::jsonb) from schoolpro_cbt_answers a where a.attempt_id=v_attempt.id));
end $$;

create or replace function public.save_schoolpro_cbt_answer(p_attempt uuid,p_question uuid,p_answer text)
returns void language plpgsql security definer set search_path=public as $$
declare v_attempt schoolpro_cbt_attempts%rowtype; v_student uuid;
begin
 select id into v_student from schoolpro_students where user_id=auth.uid() and status='active' limit 1;
 select * into v_attempt from schoolpro_cbt_attempts where id=p_attempt and student_id=v_student;
 if v_attempt.id is null or v_attempt.status<>'in_progress' then raise exception 'Active attempt not found'; end if;
 if v_attempt.expires_at is not null and now()>v_attempt.expires_at then raise exception 'Time has expired'; end if;
 if not exists(select 1 from schoolpro_cbt_test_questions where test_id=v_attempt.test_id and question_id=p_question) then raise exception 'Question is not part of this test'; end if;
 insert into schoolpro_cbt_answers(attempt_id,question_id,answer) values(p_attempt,p_question,p_answer)
 on conflict(attempt_id,question_id) do update set answer=excluded.answer;
end $$;

create or replace function public.submit_schoolpro_cbt(p_attempt uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_attempt schoolpro_cbt_attempts%rowtype; v_student uuid; v_auto numeric:=0; v_theory int:=0; v_total numeric:=0;
begin
 select id into v_student from schoolpro_students where user_id=auth.uid() and status='active' limit 1;
 select * into v_attempt from schoolpro_cbt_attempts where id=p_attempt and student_id=v_student;
 if v_attempt.id is null then raise exception 'Attempt not found'; end if;
 if v_attempt.status='submitted' then return jsonb_build_object('submitted',true,'score',v_attempt.score,'already_submitted',true); end if;
 update schoolpro_cbt_answers a set is_correct=(lower(trim(coalesce(a.answer,'')))=lower(trim(coalesce(q.correct_answer,'')))),marks_awarded=case when lower(trim(coalesce(a.answer,'')))=lower(trim(coalesce(q.correct_answer,''))) then q.marks else 0 end
 from schoolpro_question_bank q where a.attempt_id=p_attempt and a.question_id=q.id and q.question_type in ('objective','true_false');
 select coalesce(sum(a.marks_awarded),0) into v_auto from schoolpro_cbt_answers a join schoolpro_question_bank q on q.id=a.question_id where a.attempt_id=p_attempt and q.question_type in ('objective','true_false');
 select count(*) into v_theory from schoolpro_cbt_answers a join schoolpro_question_bank q on q.id=a.question_id where a.attempt_id=p_attempt and q.question_type='theory';
 select coalesce(sum(q.marks),0) into v_total from schoolpro_cbt_test_questions tq join schoolpro_question_bank q on q.id=tq.question_id where tq.test_id=v_attempt.test_id;
 update schoolpro_cbt_attempts set status='submitted',submitted_at=now(),score=v_auto where id=p_attempt;
 return jsonb_build_object('submitted',true,'objective_score',v_auto,'total_marks',v_total,'theory_answers',v_theory,'theory_pending',v_theory>0);
end $$;

revoke all on function public.start_schoolpro_cbt(uuid) from public,anon;
revoke all on function public.save_schoolpro_cbt_answer(uuid,uuid,text) from public,anon;
revoke all on function public.submit_schoolpro_cbt(uuid) from public,anon;
grant execute on function public.start_schoolpro_cbt(uuid) to authenticated;
grant execute on function public.save_schoolpro_cbt_answer(uuid,uuid,text) to authenticated;
grant execute on function public.submit_schoolpro_cbt(uuid) to authenticated;