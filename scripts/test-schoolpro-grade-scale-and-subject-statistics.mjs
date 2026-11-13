import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const helper=readFileSync('src/lib/schoolproGradeScale.ts','utf8');
const report=readFileSync('src/pages/schoolpro/SchoolProReportCard.tsx','utf8');
const checker=readFileSync('src/pages/schoolpro/SchoolProResultChecker.tsx','utf8');
const results=readFileSync('src/pages/schoolpro/SchoolProResults.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261108111000_schoolpro_consistent_subject_statistics_and_grade_bands.sql','utf8');

assert.ok(helper.includes('findSchoolProGradeBand'),'A shared grade-band resolver must exist');
assert.ok(helper.includes("if (activeBands.length) return 'Ungraded'"),'Configured gaps must not silently fall back to generic grades');
assert.ok(helper.includes('band.is_active !== false'),'Inactive historical bands must not affect grade selection');
assert.ok(helper.includes('score <= Number(band.max_score)'),'Maximum boundaries must be inclusive');
assert.ok(report.includes('const gradeBand=band(gradeScore)'),'Report card subject grades must resolve the selected-term or cumulative score through the school grade bands');
assert.ok(report.includes('gradeBand?.label||schoolProGradeLabel(gradeScore,details?.grade_scale||[])'),'Report card subject grades must use the shared resolver when no active band matches');
assert.ok(report.includes('schoolProGradeLabel(average,details?.grade_scale||[])'),'Report card overall grade must use the shared resolver');
assert.ok(checker.includes('schoolProGradeLabel(n, scale || [])'),'Public PIN result checker must use the shared resolver');
assert.ok(results.includes('schoolProGradeLabel(score,gradeScale)'),'Staff results must use the shared resolver');

const statsStart=migration.indexOf('function private.schoolpro_subject_statistics');
const statsEnd=migration.indexOf('$function$;',statsStart);
const stats=migration.slice(statsStart,statsEnd);
assert.ok(stats.includes('max(r.total_score) filter(where r.term=trim(p_term)) current_score'),'Current-term subject score must be explicit');
assert.ok(stats.includes("'current_position',case when o.current_score is not null then"),'Missing current-term subject score must have no position, not position one');
assert.ok(stats.includes('m.current_score>o.current_score'),'Current subject rank must compare the actual current-term score');
assert.ok(stats.includes('r.status=\'published\' and r.locked'),'Only published and locked scores may contribute');
assert.ok(stats.includes('case when count(*)=idx then avg(r.total_score) else null end'),'Cumulative subject average requires every term up to the selected term');
assert.ok(migration.includes('pg_advisory_xact_lock(hashtextextended(new.school_id::text,0))'),'Grade range writes must serialize per school');
assert.ok(migration.includes('g.min_score<=new.max_score and g.max_score>=new.min_score'),'Active grade ranges must reject inclusive overlap');
assert.ok(migration.includes('before insert or update of school_id,min_score,max_score,is_active'),'Grade overlap guard must run on insert and relevant updates');

const integration=readFileSync('scripts/test-schoolpro-assessment-completeness-release.integration.sql','utf8');
assert.ok(integration.includes('20261108111000_schoolpro_consistent_subject_statistics_and_grade_bands.sql'),'PostgreSQL integration must apply grade and statistics migration');
assert.ok(integration.includes('Expected overlapping active grade range to fail'),'Integration must exercise overlapping inserts');
assert.ok(integration.includes('Expected overlapping grade update to fail'),'Integration must exercise overlapping updates');
console.log('PASS: shared grade resolution, cumulative subject statistics and database grade-band guard contracts.');
