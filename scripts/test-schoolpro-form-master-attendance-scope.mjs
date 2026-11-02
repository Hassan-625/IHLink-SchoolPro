import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration=readFileSync('supabase/migrations/20261102090000_schoolpro_form_master_attendance_scope.sql','utf8');
const normalize=(value)=>value.replace(/\s+/g,' ').toLowerCase();
const sql=normalize(migration);
assert.match(sql,/when 'teacher' then array\[[^\]]*'results'[^\]]*'assignments'/);
assert.match(sql,/when 'class_teacher' then array\[[^\]]*'students'[^\]]*'results'[^\]]*'assignments'/);
assert.equal((sql.match(/when 'teacher' then array\[[^\]]*'attendance'/g)||[]).length,0);
assert.equal((sql.match(/when 'class_teacher' then array\[[^\]]*'attendance'/g)||[]).length,0);
assert.match(sql,/c\.form_teacher_id=m\.id/);
assert.match(sql,/drop policy if exists "school educators insert attendance"/);
assert.match(sql,/drop policy if exists "school educators update attendance"/);
assert.match(sql,/m\.user_id=\(select auth\.uid\(\)\)/);
assert.equal((sql.match(/p\.permission='attendance' and p\.allowed=false/g)||[]).length,3);
assert.match(sql,/private\.has_school_access\(school_id,array\['proprietor','administrator'\]::public\.school_member_role\[\]\)/);
console.log('PASS: default teacher roles lack attendance; assigned Form Masters and school leaders retain class-scoped attendance writes.');
