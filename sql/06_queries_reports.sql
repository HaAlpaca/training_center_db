-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 6: KỊCH BẢN TRUY VẤN MẪU & BÁO CÁO NGHIỆP VỤ (DEMO & TESTING)
-- =========================================================================

-- 1. Xem bảng điểm chi tiết của học viên (Gọi Function)
SELECT * FROM fn_get_student_academic_transcript('STU_001');

-- 2. Liệt kê các học viên chưa đạt hoặc chưa thi trong một khóa học (Gọi Function)
SELECT * FROM fn_get_incomplete_students('PRG_DATA_FALL_2026');

-- 3. Bảng tính thù lao giảng dạy của giảng viên trong tháng 09/2026 với đơn giá 200,000 VND/giờ (Gọi Function)
SELECT * FROM fn_calculate_instructor_salary(9, 2026, 200000);

-- 4. Bảng lương nhân sự cơ sở đào tạo kèm thưởng quản lý học viên (Gọi Function)
SELECT * FROM fn_calculate_staff_salary(50000);

-- 5. Xem báo cáo tổng hợp sĩ số và doanh thu các lớp học (Từ View)
SELECT * FROM v_class_enrollment_summary;

-- 6. Xem lịch giảng dạy chi tiết theo phòng và giảng viên (Từ View)
SELECT * FROM v_instructor_schedule_overview;

-- 7. Xem thống kê tỷ lệ đỗ của từng môn học (Từ View)
SELECT * FROM v_subject_pass_rate;

-- 8. Truy vấn nâng cao: Tìm top 3 học viên có điểm thi trung bình cao nhất
WITH student_avg AS (
    SELECT 
        s.student_id,
        s.full_name,
        ROUND(AVG(er.score), 2) AS gpa,
        DENSE_RANK() OVER (ORDER BY AVG(er.score) DESC) AS rank
    FROM student s
    JOIN exam_result er ON s.student_id = er.student_id
    GROUP BY s.student_id, s.full_name
)
SELECT student_id, full_name, gpa, rank
FROM student_avg
WHERE rank <= 3;
