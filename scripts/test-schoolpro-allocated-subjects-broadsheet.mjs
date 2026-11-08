import fs from 'node:fs';
import assert from 'node:assert/strict';
const migration=fs.readFileSync('supabase/migrations/20261108112000_schoolpro_show_allocated_subjects_in_broadsheet.sql','utf8');
const page=fs.readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8');
assert.match(migration,/schoolpro_subject_assignments[\s\S]*sa\.school_id=p_school[\s\S]*sa\.class_id=p_class[\s\S]*sa\.session=trim\(p_session\)/);
assert.match(migration,/union all[\s\S]*select distinct m\.subject_id,false assigned from marks/);
assert.match(migration,/avg\(m\.total_score\) average,count\(m\.id\) recorded/);
assert.match(migration,/published_total[\s\S]*published_average[\s\S]*published_subjects[\s\S]*published_scores/);
assert.match(migration,/rank\(\) over\(order by published_total desc\) published_position/);
assert.match(migration,/group by su\.id,su\.name,su\.code,ss\.assigned/);
assert.match(page,/s\.assigned\s*\?\s*'Allocated'\s*:\s*'Recorded only'/);
assert.match(page,/missing marks are not counted as zero/);
assert.match(page,/Number\(r\.published_average\)/);
assert.match(page,/publishedScoreCount=scored\.reduce\(\(sum,r\)=>sum\+Number\(r\.published_subjects\),0\)/);
assert.match(page,/scored\.reduce\(\(sum,r\)=>sum\+Number\(r\.published_total\),0\)\/publishedScoreCount/);
assert.doesNotMatch(page,/scored\.reduce\(\(sum,r\)=>sum\+Number\(r\.published_average\),0\)\/scored\.length/);
assert.match(page,/r\.published_position/);
assert.match(page,/r\.published_scores\?\.\[s\.id\]/);
console.log('SchoolPro allocated-subject broadsheet regression passed.');

const rosterMigrations=[
 'supabase/migrations/20261108100000_schoolpro_consistent_result_ranking_totals.sql',
 'supabase/migrations/20261108105000_schoolpro_published_rank_requires_locked_results.sql',
 'supabase/migrations/20261108111000_schoolpro_consistent_subject_statistics_and_grade_bands.sql',
 'supabase/migrations/20261108112000_schoolpro_show_allocated_subjects_in_broadsheet.sql'
];
for(const file of rosterMigrations){
 const sql=fs.readFileSync(file,'utf8');
 assert.match(sql,/left join lateral \(select h\.class_id,true has_history[\s\S]*h\.session=trim\(p_session\) limit 1\) e on true/,file+' must deduplicate the selected-session enrollment join');
 assert.match(sql,/e\.has_history is true/,file+' must preserve a historical enrollment row even if its class_id is null');
 assert.match(sql,/h\.session=trim\(p_session\)/,file+' must scope active-student fallback to the selected session');
}
console.log('SchoolPro historical roster deduplication regression passed.');
