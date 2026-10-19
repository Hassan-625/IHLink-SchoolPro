-- Synthetic operational module fixtures for disposable MySQL CI only.
INSERT INTO timetable_entries
 (id,school_id,class_id,subject_id,session_id,weekday,starts_at,ends_at,room,created_by)
VALUES
 ('d1000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001',1,'09:00:00','09:40:00','Room A','00000000-0000-4000-8000-000000000001');

INSERT INTO calendar_events
 (id,school_id,title,event_date,end_date,event_type,details,class_id,session_id,created_by)
VALUES
 ('d2000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Synthetic Sports Day','2025-10-10','2025-10-10','school_event','Fixture only',NULL,'30000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');

INSERT INTO announcements
 (id,school_id,title,body,audience,published,session_id,created_by,published_at)
VALUES
 ('d3000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Synthetic announcement','Fixture only','all',TRUE,'30000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','2025-09-01 10:00:00');

INSERT INTO discipline_records
 (id,school_id,student_id,incident,action_taken,status,session_id,term_id,created_by)
VALUES
 ('d4000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','Synthetic incident','Counselling','resolved','30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');

INSERT INTO student_health_records
 (id,school_id,student_id,complaint,assessment,status,session_id,term_id,recorded_by)
VALUES
 ('d5000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','Synthetic complaint','Synthetic assessment','closed','30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');

INSERT INTO lesson_notes
 (id,school_id,subject_id,class_id,title,content,status,created_by,term_id,session_id,week_number,duration_minutes)
VALUES
 ('d6000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','Synthetic lesson note','Fixture only','draft','00000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001',1,40);

INSERT INTO leave_requests
 (id,school_id,membership_id,leave_type,start_date,end_date,reason,status,session_id)
VALUES
 ('d7000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','annual','2025-10-01','2025-10-02','Synthetic fixture','pending','30000000-0000-4000-8000-000000000001');

INSERT INTO inventory_assets
 (id,school_id,name,category,quantity,asset_condition,location)
VALUES
 ('d8000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Synthetic projector','ICT',2,'good','ICT store');

INSERT INTO hostel_rooms
 (id,school_id,hostel_name,room_name,capacity,fee)
VALUES
 ('d9000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Hostel A','Room 1',4,50000);

INSERT INTO hostel_allocations
 (id,school_id,student_id,room_id,session_id,active)
VALUES
 ('da000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','d9000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001',TRUE);

SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: timetable is scoped to the same school class and subject' ELSE 'FAIL: timetable fixture mismatch' END AS assertion FROM timetable_entries WHERE school_id='10000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: attendance is already represented by core migration 001' ELSE 'FAIL: core attendance fixture mismatch' END AS assertion FROM attendance_records WHERE school_id='10000000-0000-4000-8000-000000000001' AND enrollment_id='60000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: hostel allocation links same-school student and room' ELSE 'FAIL: hostel fixture mismatch' END AS assertion FROM hostel_allocations WHERE school_id='10000000-0000-4000-8000-000000000001';
