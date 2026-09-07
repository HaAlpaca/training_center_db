-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 3: FUNCTIONS TRUY VẤN VÀ TÍNH TOÁN NGHIỆP VỤ
-- =========================================================================

-- 3.1. Hiển thị kết quả học tập của từng học viên
CREATE OR REPLACE FUNCTION fn_get_student_academic_transcript(p_student_id VARCHAR)
RETURNS TABLE (
    student_id VARCHAR,
    student_name VARCHAR,
    class_id VARCHAR,
    class_name VARCHAR,
    subject_id VARCHAR,
    subject_name VARCHAR,
    attempt_number INT,
    score NUMERIC,
    exam_date DATE,
    evaluation VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.student_id,
        s.full_name AS student_name,
        c.class_id,
        c.class_name,
        sub.subject_id,
        sub.subject_name,
        er.attempt_number,
        er.score,
        er.exam_date,
        er.evaluation
    FROM student s
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN class c ON e.class_id = c.class_id
    JOIN subject sub ON c.program_id = sub.program_id
    LEFT JOIN exam_result er ON s.student_id = er.student_id 
                            AND c.class_id = er.class_id 
                            AND sub.subject_id = er.subject_id
    WHERE s.student_id = p_student_id
    ORDER BY c.class_id, sub.subject_id, er.attempt_number;
END;
$$ LANGUAGE plpgsql;


-- 3.2. Liệt kê các học viên chưa hoàn thành môn học trong khóa
CREATE OR REPLACE FUNCTION fn_get_incomplete_students(p_class_id VARCHAR)
RETURNS TABLE (
    student_id VARCHAR,
    student_name VARCHAR,
    subject_id VARCHAR,
    subject_name VARCHAR,
    latest_score NUMERIC,
    total_attempts BIGINT,
    learning_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH latest_exam AS (
        SELECT 
            er.student_id,
            er.class_id,
            er.subject_id,
            er.score,
            er.attempt_number,
            ROW_NUMBER() OVER(PARTITION BY er.student_id, er.class_id, er.subject_id ORDER BY er.attempt_number DESC) as rn
        FROM exam_result er
        WHERE er.class_id = p_class_id
    ),
    class_subjects AS (
        SELECT c.class_id, s.subject_id, s.subject_name
        FROM class c
        JOIN subject s ON c.program_id = s.program_id
        WHERE c.class_id = p_class_id
    )
    SELECT 
        e.student_id,
        st.full_name AS student_name,
        cs.subject_id,
        cs.subject_name,
        COALESCE(le.score, -1) AS latest_score,
        COALESCE(le.attempt_number, 0)::BIGINT AS total_attempts,
        CASE 
            WHEN le.score IS NULL THEN 'Chưa dự thi'
            WHEN le.score <= 5.0 THEN 'Chưa đạt'
            ELSE 'Đã đạt'
        END AS learning_status
    FROM enrollment e
    JOIN student st ON e.student_id = st.student_id
    CROSS JOIN class_subjects cs
    LEFT JOIN latest_exam le ON e.student_id = le.student_id AND cs.subject_id = le.subject_id AND le.rn = 1
    WHERE e.class_id = p_class_id
      AND (le.score IS NULL OR le.score <= 5.0)
    ORDER BY e.student_id, cs.subject_id;
END;
$$ LANGUAGE plpgsql;


-- 3.3. Tính lương giảng viên (Lương dạy chính = 2 * Lương trợ giảng)
CREATE OR REPLACE FUNCTION fn_calculate_instructor_salary(
    p_month INT,
    p_year INT,
    p_base_hourly_rate NUMERIC
)
RETURNS TABLE (
    instructor_id VARCHAR,
    full_name VARCHAR,
    contract_type VARCHAR,
    teaching_hours BIGINT,
    ta_hours BIGINT,
    total_salary NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH teaching_sessions AS (
        SELECT 
            main_instructor_id AS ins_id,
            2::BIGINT AS teach_hrs,
            0::BIGINT AS ta_hrs
        FROM class_session
        WHERE EXTRACT(MONTH FROM start_time) = p_month 
          AND EXTRACT(YEAR FROM start_time) = p_year 
          AND status = 'COMPLETED'
          AND is_deleted = FALSE

        UNION ALL

        SELECT 
            teaching_assistant_id AS ins_id,
            0::BIGINT AS teach_hrs,
            2::BIGINT AS ta_hrs
        FROM class_session
        WHERE EXTRACT(MONTH FROM start_time) = p_month 
          AND EXTRACT(YEAR FROM start_time) = p_year 
          AND status = 'COMPLETED'
          AND is_deleted = FALSE
          AND teaching_assistant_id IS NOT NULL
    )
    SELECT 
        i.instructor_id,
        i.full_name,
        i.contract_type,
        SUM(ts.teach_hrs)::BIGINT AS teaching_hours,
        SUM(ts.ta_hrs)::BIGINT AS ta_hours,
        ROUND((SUM(ts.teach_hrs) * p_base_hourly_rate) + (SUM(ts.ta_hrs) * (p_base_hourly_rate / 2.0)), 2) AS total_salary
    FROM instructor i
    JOIN teaching_sessions ts ON i.instructor_id = ts.ins_id
    GROUP BY i.instructor_id, i.full_name, i.contract_type
    ORDER BY total_salary DESC;
END;
$$ LANGUAGE plpgsql;


-- 3.4. Tính lương nhân viên (Lương cứng 5tr + Thưởng quản lý CTĐT + 5% x số cấp dưới)
CREATE OR REPLACE FUNCTION fn_calculate_staff_salary(p_rate_per_student NUMERIC DEFAULT 50000)
RETURNS TABLE (
    staff_id VARCHAR,
    full_name VARCHAR,
    staff_position VARCHAR,
    base_salary NUMERIC,
    subordinates_count BIGINT,
    management_bonus NUMERIC,
    managed_students_count BIGINT,
    program_management_pay NUMERIC,
    total_income NUMERIC
) AS $$
DECLARE
    v_base_salary NUMERIC := 5000000;
BEGIN
    RETURN QUERY
    WITH subordinates AS (
        SELECT st.manager_id, COUNT(*)::BIGINT AS cnt
        FROM staff st
        WHERE st.is_deleted = FALSE AND st.status = 'Active' AND st.manager_id IS NOT NULL
        GROUP BY st.manager_id
    ),
    program_students AS (
        SELECT 
            p.manager_id,
            COUNT(DISTINCT e.student_id)::BIGINT AS total_students
        FROM program p
        JOIN class c ON p.program_id = c.program_id
        JOIN enrollment e ON c.class_id = e.class_id
        WHERE p.is_deleted = FALSE AND e.is_deleted = FALSE
        GROUP BY p.manager_id
    )
    SELECT 
        s.staff_id,
        s.full_name,
        s.position AS staff_position,
        v_base_salary,
        COALESCE(sub.cnt, 0)::BIGINT,
        ROUND(COALESCE(sub.cnt, 0) * (0.05 * v_base_salary), 2),
        COALESCE(ps.total_students, 0)::BIGINT,
        ROUND(COALESCE(ps.total_students, 0) * p_rate_per_student, 2),
        ROUND(v_base_salary + (COALESCE(sub.cnt, 0) * 0.05 * v_base_salary) + (COALESCE(ps.total_students, 0) * p_rate_per_student), 2)
    FROM staff s
    LEFT JOIN subordinates sub ON s.staff_id = sub.manager_id
    LEFT JOIN program_students ps ON s.staff_id = ps.manager_id
    WHERE s.is_deleted = FALSE AND s.status = 'Active';
END;
$$ LANGUAGE plpgsql;
