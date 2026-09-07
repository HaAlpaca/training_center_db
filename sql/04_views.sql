-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 4: CÁC VIEWS BÁO CÁO THỐNG KÊ NGHIỆP VỤ
-- =========================================================================

-- 4.1. View thống kê sĩ số và doanh thu học phí theo từng lớp học
CREATE OR REPLACE VIEW v_class_enrollment_summary AS
SELECT 
    c.class_id,
    c.class_name,
    p.program_name,
    sem.semester_name,
    c.max_capacity,
    COUNT(e.student_id) AS current_students,
    (c.max_capacity - COUNT(e.student_id)) AS remaining_slots,
    COALESCE(SUM(e.tuition_paid), 0) AS total_tuition_collected,
    c.status AS class_status
FROM class c
JOIN program p ON c.program_id = p.program_id
JOIN semester sem ON c.semester_id = sem.semester_id
LEFT JOIN enrollment e ON c.class_id = e.class_id AND e.is_deleted = FALSE
WHERE c.is_deleted = FALSE
GROUP BY c.class_id, c.class_name, p.program_name, sem.semester_name, c.max_capacity, c.status;


-- 4.2. View tổng quan lịch giảng dạy của giảng viên
CREATE OR REPLACE VIEW v_instructor_schedule_overview AS
SELECT 
    cs.session_id,
    cs.start_time,
    cs.end_time,
    c.class_name,
    sub.subject_name,
    r.room_name,
    r.location AS room_location,
    ins.full_name AS main_instructor,
    ta.full_name AS teaching_assistant,
    cs.session_type,
    cs.status AS session_status
FROM class_session cs
JOIN class c ON cs.class_id = c.class_id
JOIN subject sub ON cs.subject_id = sub.subject_id
JOIN room r ON cs.room_id = r.room_id
JOIN instructor ins ON cs.main_instructor_id = ins.instructor_id
LEFT JOIN instructor ta ON cs.teaching_assistant_id = ta.instructor_id
WHERE cs.is_deleted = FALSE;


-- 4.3. View thống kê tỷ lệ đạt/không đạt của từng môn học trong các lớp
CREATE OR REPLACE VIEW v_subject_pass_rate AS
WITH latest_scores AS (
    SELECT 
        class_id,
        subject_id,
        student_id,
        score,
        ROW_NUMBER() OVER (PARTITION BY class_id, subject_id, student_id ORDER BY attempt_number DESC) as rn
    FROM exam_result
    WHERE is_deleted = FALSE
)
SELECT 
    ls.class_id,
    c.class_name,
    s.subject_id,
    s.subject_name,
    COUNT(ls.student_id) AS total_candidates,
    COUNT(CASE WHEN ls.score > 5.0 THEN 1 END) AS passed_count,
    COUNT(CASE WHEN ls.score <= 5.0 THEN 1 END) AS failed_count,
    ROUND((COUNT(CASE WHEN ls.score > 5.0 THEN 1 END)::NUMERIC / NULLIF(COUNT(ls.student_id), 0)) * 100, 2) AS pass_rate_percent
FROM latest_scores ls
JOIN class c ON ls.class_id = c.class_id
JOIN subject s ON ls.subject_id = s.subject_id
WHERE ls.rn = 1
GROUP BY ls.class_id, c.class_name, s.subject_id, s.subject_name;
