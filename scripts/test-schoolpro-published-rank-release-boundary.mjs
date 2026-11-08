import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const migration=readFileSync('supabase/migrations/20261108105000_schoolpro_published_rank_requires_locked_results.sql','utf8');
const printable=readFileSync('supabase/migrations/20261011230828_schoolpro_print_historical_results_with_caller_row_permissions.sql','utf8');
const family=readFileSync('supabase/migrations/20261009222727_private_family_result_rpcs.sql','utf8');
for (const fn of ['schoolpro_result_class_rank','schoolpro_broadsheet']) {
 const start=migration.indexOf(`function public.${fn}`);
 assert.ok(start>=0,`${fn} must be redefined`);
 const end=migration.indexOf('$function$;',start);
 assert.ok(end>start,`${fn} definition must be complete`);
 assert.ok(migration.slice(start,end).includes("r.status='published'::public.schoolpro_result_status and r.locked=true"),`${fn} must rank only published and locked results`);
}
assert.ok(printable.includes("r.status='published' and r.locked=true"),'Report cards must use the same release boundary');
assert.ok(family.includes("r.status='published' and r.locked"),'Family period discovery must use the same release boundary');
console.log('PASS: report cards, family visibility, broadsheet and class ranking all use published-and-locked results.');

const rankGuard=readFileSync('supabase/migrations/20261108117000_schoolpro_hide_unreleased_student_rankings.sql','utf8');
assert.match(rankGuard,/nullif\(trim\(p_term\),' '\) is null/,'Ranking must reject a blank term');
assert.match(rankGuard,/nullif\(trim\(p_session\),' '\) is null/,'Ranking must reject a blank session');
assert.match(rankGuard,/not exists\(select 1 from public\.schoolpro_results r[\s\S]*r\.status='published'::public\.schoolpro_result_status and r\.locked=true\)/,'Student and guardian rank must require their own published and locked result');
assert.match(rankGuard,/schoolpro_can_view_result_output\(p_student_id,trim\(p_term\),trim\(p_session\)\)/,'Ranking must preserve attendance and finance release checks');
