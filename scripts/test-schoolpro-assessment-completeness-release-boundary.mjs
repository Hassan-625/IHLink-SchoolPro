import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration=readFileSync('supabase/migrations/20261108110000_schoolpro_require_complete_assessments_for_approval_and_publication.sql','utf8');
const helper=migration.slice(migration.indexOf('function private.schoolpro_result_assessment_complete'),migration.indexOf('$function$;',migration.indexOf('function private.schoolpro_result_assessment_complete')));
assert.ok(helper.includes("r.assessment_scheme_id is null"),'Results without a configured scheme must not be approved');
assert.ok(helper.includes("jsonb_typeof(r.assessment_scores)<>'object'"),'Assessment score map must be an object');
assert.ok(helper.includes("jsonb_typeof(configured)<>'array'"),'Scheme components must be a JSON array');
assert.ok(helper.includes("jsonb_array_length(configured)=0"),'An empty assessment scheme cannot be approved');
assert.ok(helper.includes('configured_count<>distinct_key_count'),'Duplicate component keys must fail closed');
assert.ok(helper.includes("not (r.assessment_scores ? component_key)"),'Every configured component must have a score');
assert.ok(helper.includes("jsonb_typeof(r.assessment_scores->component_key)<>'number'"),'Every component score must be numeric');
assert.ok(helper.includes('score_value>max_value'),'Component scores must respect the configured maximum');
assert.ok(helper.includes('jsonb_object_keys(r.assessment_scores)'),'Unknown score keys must be rejected');
assert.ok(helper.includes('return coalesce(r.total_score=calculated_total,false)'),'Stored total must equal the sum of component scores');
assert.ok(helper.includes('exception when others then'),'Malformed schemes must fail closed');

const review=migration.slice(migration.indexOf('function public.review_schoolpro_result'),migration.indexOf('$function$;',migration.indexOf('function public.review_schoolpro_result')));
assert.ok(review.includes("p_status='approved' and not private.schoolpro_result_assessment_complete(r.id)"),'Approval must reject incomplete scores');
assert.ok(review.includes('Incomplete assessment:'),'Approval must explain why it was blocked');
assert.ok(review.includes("p_status not in('approved','rejected')"),'Rejection remains an allowed review outcome for incomplete drafts');

for (const fn of ['publish_schoolpro_class_results','publish_schoolpro_selected_results','publish_schoolpro_results']) {
 const start=migration.indexOf(`function public.${fn}`);
 const end=migration.indexOf('$function$;',start);
 assert.ok(start>=0&&end>start,`${fn} must be redefined`);
 const body=migration.slice(start,end);
 assert.ok(body.includes('private.schoolpro_result_assessment_complete(r.id)'),`${fn} must revalidate completeness before release`);
 assert.ok(body.includes('for update'),`${fn} must lock the publication scope before checking completeness`);
 if(fn==='publish_schoolpro_class_results'){
  assert.ok(body.includes("s.status='active'"),'Class publication must retain the active-roster fallback');
  assert.ok(body.includes('not exists(select 1 from public.schoolpro_enrollment_history h'), 'Active students without a history row must remain eligible for their current class');
  assert.equal((body.match(/not exists\(select 1 from public\.schoolpro_enrollment_history h/g)||[]).length,3,'Class publication completeness check and update must use the same historical-roster fallback');
 }
 assert.ok(body.includes('incomplete approved assessments')||body.includes('incomplete approved assessments')||body.includes('incomplete approved'),`${fn} must fail with a clear incomplete-assessment error`);
}
assert.ok(migration.includes('revoke all on function private.schoolpro_result_assessment_complete(uuid) from public,anon,authenticated'),'Internal completeness helper must not be directly executable by clients');
assert.ok(migration.includes('grant execute on function public.review_schoolpro_result(uuid,text,text) to authenticated'));
console.log('PASS: incomplete, malformed, out-of-range or inconsistent assessment scores cannot be approved or published.');
