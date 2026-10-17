-- Synthetic assessment/template/transcript fixtures for disposable MySQL CI only.
INSERT INTO assessment_schemes
  (id,school_id,name,school_level,components,is_default,created_by,updated_by)
VALUES
  ('b1000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Primary Default','primary',JSON_ARRAY(JSON_OBJECT('key','ca1','label','CA 1','max',20),JSON_OBJECT('key','exam','label','Exam','max',80)),TRUE,'00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');

INSERT INTO grade_scales
  (id,school_id,label,min_score,max_score,remark,overall_remark,position,is_active)
VALUES
  ('b2000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','A',80,100,'Excellent','Excellent performance',1,TRUE),
  ('b2000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','B',60,79.99,'Good','Good performance',2,TRUE);

INSERT INTO result_approvals
  (id,school_id,result_id,status,reviewed_by,reviewed_at,notes)
VALUES
  ('b3000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','90000000-0000-4000-8000-000000000001','approved','00000000-0000-4000-8000-000000000001','2025-09-15 10:00:00','Synthetic approval fixture');

INSERT INTO result_correction_requests
  (id,school_id,result_id,requested_by,reason,status,component_key,proposed_score)
VALUES
  ('b4000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','90000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','Check source mark entry','pending','CA1',18.00);

INSERT INTO result_correction_snapshots
  (id,school_id,result_id,reopened_by,reason,previous_snapshot)
VALUES
  ('b5000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','90000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','Synthetic correction snapshot',JSON_OBJECT('status','published','total_score',17.5));

INSERT INTO result_templates
  (id,school_id,name,education_level,template_kind,storage_path,sheet_name,start_row,field_cells,columns_mapping,component_columns,custom_fields,logo_storage_path,updated_by)
VALUES
  ('b6000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Primary Starter','primary','starter','10000000-0000-4000-8000-000000000001/templates/primary-starter.xlsx','Result',8,
   JSON_OBJECT('student_name','B2','admission_number','B3'),JSON_OBJECT('name','A','admission_number','B','total','C'),JSON_OBJECT('CA1','D','exam','E'),JSON_ARRAY(JSON_OBJECT('key','attendance','label','Attendance')), '10000000-0000-4000-8000-000000000001/branding/logo.png','00000000-0000-4000-8000-000000000001');

INSERT INTO transcript_settings (school_id,officers,updated_by)
VALUES ('10000000-0000-4000-8000-000000000001',JSON_ARRAY(JSON_OBJECT('role','principal','name','Synthetic Principal')), '00000000-0000-4000-8000-000000000001');

INSERT INTO transcript_issues
  (id,school_id,student_id,serial_number,snapshot,issued_by)
VALUES
  ('b7000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','IH-TEST-TRANSCRIPT-0001',JSON_OBJECT('education_level','primary','session','2025/2026','terms',JSON_ARRAY()),'00000000-0000-4000-8000-000000000001');

SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: assessment scheme stored per school' ELSE 'FAIL: assessment scheme fixture mismatch' END AS assertion
FROM assessment_schemes WHERE school_id='10000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: result review and correction records are linked to the same school result' ELSE 'FAIL: review/correction fixture mismatch' END AS assertion
FROM result_approvals WHERE school_id='10000000-0000-4000-8000-000000000001' AND result_id='90000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: workbook template object path is school-scoped' ELSE 'FAIL: template path fixture mismatch' END AS assertion
FROM result_templates WHERE school_id='10000000-0000-4000-8000-000000000001' AND SUBSTRING_INDEX(storage_path,'/',1)=school_id;
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: transcript snapshot is retained' ELSE 'FAIL: transcript fixture mismatch' END AS assertion
FROM transcript_issues WHERE serial_number='IH-TEST-TRANSCRIPT-0001';
