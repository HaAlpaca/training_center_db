-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (TRAINING CENTER DATABASE)
-- TẬP HỢP TẤT CẢ CÁC CÂU TRUY VẤN (SQL QUERIES) THEO YÊU CẦU ĐỀ BÀI
-- =========================================================================

-- =========================================================================
-- YÊU CẦU 1: THỰC HIỆN CÁC CHỨC NĂNG THÊM / XOÁ / SỬA / TÌM KIẾM (CRUD)
-- VỚI CÁC ĐỐI TƯỢNG VÀ RÀNG BUỘC TOÀN VẸN
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1.1. CHƯƠNG TRÌNH ĐÀO TẠO (PROGRAM)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm chương trình đào tạo mới
INSERT INTO program (program_id, program_name, description, version, manager_id, status)
VALUES ('PRG_AI_2026', 'Trí Tuệ Nhân Tạo & Học Máy', 'Chương trình đào tạo AI ứng dụng chuyên sâu', '1.0', 'STF_002', 'ACTIVE');

-- [UPDATE] Cập nhật thông tin chương trình đào tạo
UPDATE program
SET program_name = 'Trí Tuệ Nhân Tạo & Deep Learning Nâng Cao',
    version = '1.1',
    updated_at = CURRENT_TIMESTAMP
WHERE program_id = 'PRG_AI_2026' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm (Soft Delete - Khuyên dùng)
UPDATE program
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE program_id = 'PRG_AI_2026';

-- [SEARCH] Tìm kiếm chương trình theo từ khóa tên hoặc mã, kèm tên nhân sự quản lý
SELECT 
    p.program_id,
    p.program_name,
    p.description,
    p.version,
    p.status,
    s.full_name AS manager_name,
    s.email AS manager_email
FROM program p
JOIN staff s ON p.manager_id = s.staff_id
WHERE p.is_deleted = FALSE
  AND (p.program_name ILIKE '%Data%' OR p.program_id ILIKE '%DATA%')
ORDER BY p.created_at DESC;


-- -------------------------------------------------------------------------
-- 1.2. MÔN HỌC (SUBJECT)
-- Ràng buộc: total_hours > 0 và là số chẵn (mỗi buổi 2h); Tối đa 10 môn/CTĐT
-- -------------------------------------------------------------------------

-- [CREATE] Thêm môn học vào chương trình đào tạo
INSERT INTO subject (subject_id, subject_name, program_id, total_hours, subject_type)
VALUES ('PRG_DATA_BI', 'PowerBI & Trực quan hóa dữ liệu', 'PRG_DATA', 30, 'ELECTIVE');

-- [UPDATE] Cập nhật thời lượng hoặc tên môn học
UPDATE subject
SET subject_name = 'PowerBI & Trực quan hóa dữ liệu nâng cao',
    total_hours = 36,
    updated_at = CURRENT_TIMESTAMP
WHERE subject_id = 'PRG_DATA_BI' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm môn học
UPDATE subject
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE subject_id = 'PRG_DATA_BI';

-- [SEARCH] Tìm kiếm môn học theo tên và lọc theo chương trình
SELECT 
    sub.subject_id,
    sub.subject_name,
    p.program_name,
    sub.total_hours,
    sub.total_sessions,
    sub.subject_type
FROM subject sub
JOIN program p ON sub.program_id = p.program_id
WHERE sub.is_deleted = FALSE
  AND sub.program_id = 'PRG_DATA'
  AND sub.subject_name ILIKE '%SQL%'
ORDER BY sub.subject_id;


-- -------------------------------------------------------------------------
-- 1.3. NHÂN VIÊN (STAFF)
-- Ràng buộc: gender IN (0, 1, 2), date_of_birth < CURRENT_DATE, email/phone UNIQUE
-- -------------------------------------------------------------------------

-- [CREATE] Thêm nhân viên mới
INSERT INTO staff (staff_id, full_name, gender, date_of_birth, email, phone_number, position, manager_id, status)
VALUES ('STF_004', 'Hoàng Thu Trang', 0, '1995-12-05', 'trang.hoang@system.edu.vn', '0934567890', 'Education Officer', 'STF_002', 'Active');

-- [UPDATE] Cập nhật chức vụ, số điện thoại
UPDATE staff
SET position = 'Senior Education Officer',
    phone_number = '0934567899',
    updated_at = CURRENT_TIMESTAMP
WHERE staff_id = 'STF_004' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm / Cập nhật thôi việc
UPDATE staff
SET is_deleted = TRUE,
    status = 'RESIGNED',
    updated_at = CURRENT_TIMESTAMP
WHERE staff_id = 'STF_004';

-- [SEARCH] Tìm kiếm nhân viên kèm thông tin quản lý cấp trên
SELECT 
    s.staff_id,
    s.full_name,
    CASE s.gender WHEN 0 THEN 'Nữ' WHEN 1 THEN 'Nam' ELSE 'Khác' END AS gender_label,
    s.date_of_birth,
    s.email,
    s.phone_number,
    s.position,
    m.full_name AS direct_manager,
    s.status
FROM staff s
LEFT JOIN staff m ON s.manager_id = m.staff_id
WHERE s.is_deleted = FALSE
  AND (s.full_name ILIKE '%Lê Thị Bình%' OR s.position ILIKE '%Manager%')
ORDER BY s.staff_id;


-- -------------------------------------------------------------------------
-- 1.4. GIẢNG VIÊN (INSTRUCTOR)
-- Ràng buộc: contract_type IN ('FULLTIME', 'PARTTIME'), email UNIQUE
-- -------------------------------------------------------------------------

-- [CREATE] Thêm giảng viên mới
INSERT INTO instructor (instructor_id, full_name, email, phone_number, specialization, degree, contract_type)
VALUES ('INS_003', 'ThS. Nguyễn Quốc Anh', 'anh.nguyen@lecturer.edu.vn', '0945678901', 'Cloud & Data Engineering', 'Thạc sĩ', 'PARTTIME');

-- [UPDATE] Cập nhật học vị, hợp đồng
UPDATE instructor
SET degree = 'Tiến sĩ',
    contract_type = 'FULLTIME',
    updated_at = CURRENT_TIMESTAMP
WHERE instructor_id = 'INS_003' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm giảng viên
UPDATE instructor
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE instructor_id = 'INS_003';

-- [SEARCH] Tìm kiếm giảng viên theo chuyên môn hoặc học vị
SELECT 
    instructor_id,
    full_name,
    email,
    phone_number,
    specialization,
    degree,
    contract_type
FROM instructor
WHERE is_deleted = FALSE
  AND (specialization ILIKE '%Dữ liệu%' OR degree = 'Tiến sĩ')
ORDER BY instructor_id;


-- -------------------------------------------------------------------------
-- 1.5. HỌC VIÊN (STUDENT)
-- Ràng buộc: phone_number UNIQUE, status IN ('ACTIVE', 'RESERVED', 'DROPPED')
-- -------------------------------------------------------------------------

-- [CREATE] Thêm học viên mới
INSERT INTO student (student_id, full_name, date_of_birth, phone_number, email, source, status)
VALUES ('STU_003', 'Trịnh Bảo Ngọc', '2004-09-18', '0919998877', 'ngoc.tb@gmail.com', 'Facebook Ads', 'ACTIVE');

-- [UPDATE] Cập nhật thông tin liên hệ học viên
UPDATE student
SET phone_number = '0919998899',
    email = 'baongoc.trinh@gmail.com',
    updated_at = CURRENT_TIMESTAMP
WHERE student_id = 'STU_003' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm học viên (chuyển trạng thái sang DROPPED)
UPDATE student
SET is_deleted = TRUE,
    status = 'DROPPED',
    updated_at = CURRENT_TIMESTAMP
WHERE student_id = 'STU_003';

-- [SEARCH] Tìm kiếm học viên theo họ tên, sđt hoặc email
SELECT 
    student_id,
    full_name,
    date_of_birth,
    phone_number,
    email,
    source,
    status
FROM student
WHERE is_deleted = FALSE
  AND (full_name ILIKE '%Dũng%' OR phone_number LIKE '%0981%')
ORDER BY student_id;


-- -------------------------------------------------------------------------
-- 1.6. PHÒNG HỌC (ROOM)
-- Ràng buộc: capacity > 0, room_type IN ('LAB', 'STANDARD'), status IN ('READY', 'MAINTENANCE')
-- -------------------------------------------------------------------------

-- [CREATE] Thêm phòng học
INSERT INTO room (room_id, room_name, location, capacity, room_type, status)
VALUES ('ROOM_202', 'Phòng Hội thảo 202', 'Tòa B - Tầng 2', 45, 'STANDARD', 'READY');

-- [UPDATE] Đưa phòng vào diện bảo trì
UPDATE room
SET status = 'MAINTENANCE',
    updated_at = CURRENT_TIMESTAMP
WHERE room_id = 'ROOM_202' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm phòng học
UPDATE room
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE room_id = 'ROOM_202';

-- [SEARCH] Tìm kiếm phòng học thực hành (LAB) còn sử dụng được và có sức chứa >= 30
SELECT 
    room_id,
    room_name,
    location,
    capacity,
    room_type,
    status
FROM room
WHERE is_deleted = FALSE
  AND status = 'READY'
  AND room_type = 'LAB'
  AND capacity >= 30
ORDER BY capacity DESC;


-- =========================================================================
-- YÊU CẦU 2: HIỂN THỊ KẾT QUẢ HỌC TẬP CỦA MỖI HỌC VIÊN
-- TRONG CÁC KHÓA ĐÀO TẠO HỌ ĐÃ HOÀN THÀNH
-- =========================================================================

-- CÁCH 1: Truy vấn SQL thuần (Raw SQL) - Tính điểm mới nhất của từng môn, 
-- trạng thái môn và điểm trung bình tích lũy GPA của học viên trong các khóa ĐÃ HOÀN THÀNH
WITH latest_subject_scores AS (
    SELECT 
        er.student_id,
        er.class_id,
        er.subject_id,
        er.score,
        er.attempt_number,
        er.exam_date,
        er.evaluation,
        ROW_NUMBER() OVER (
            PARTITION BY er.student_id, er.class_id, er.subject_id 
            ORDER BY er.attempt_number DESC
        ) AS rn
    FROM exam_result er
    WHERE er.is_deleted = FALSE
)
SELECT 
    s.student_id,
    s.full_name AS student_name,
    c.class_id,
    c.class_name,
    p.program_name,
    sub.subject_id,
    sub.subject_name,
    lss.attempt_number AS final_attempt,
    lss.score AS final_score,
    lss.exam_date,
    COALESCE(lss.evaluation, 'NOT_TAKEN') AS subject_result,
    ROUND(
        AVG(lss.score) OVER (PARTITION BY s.student_id, c.class_id), 2
    ) AS class_gpa
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN class c ON e.class_id = c.class_id
JOIN program p ON c.program_id = p.program_id
JOIN subject sub ON p.program_id = sub.program_id
LEFT JOIN latest_subject_scores lss 
       ON e.student_id = lss.student_id 
      AND c.class_id = lss.class_id 
      AND sub.subject_id = lss.subject_id 
      AND lss.rn = 1
WHERE e.is_deleted = FALSE 
  -- Lọc các khóa học viên đã hoàn thành (hoặc lớp đã kết thúc)
  AND (e.status = 'COMPLETED' OR c.status = 'CLOSED' OR e.status = 'ENROLLED') 
ORDER BY s.student_id, c.class_id, sub.subject_id;

-- CÁCH 2: Gọi Function có sẵn trong database cho một học viên cụ thể
-- (Xem toàn bộ lịch sử các lần thi môn học của học viên, bao gồm cả các khoá CHƯA HOÀN THÀNH)
SELECT * FROM fn_get_student_academic_transcript('STU_001');


-- =========================================================================
-- YÊU CẦU 3: LIỆT KÊ TOÀN BỘ CÁC HỌC VIÊN CHƯA HOÀN THÀNH XONG CÁC MÔN HỌC
-- CỦA KHÓA ĐÀO TẠO KÈM ĐIỂM THI CỦA CÁC LẦN DỰ THI CHƯA ĐẠT (NẾU ĐÃ DỰ THI)
-- =========================================================================

-- Trả về: Học viên, Môn học chưa qua, Trạng thái (Chưa thi / Thi chưa đạt),
-- và chuỗi tổng hợp tất cả các lần thi bị rớt (điểm <= 5.0)
WITH class_target_subjects AS (
    -- Danh sách tất cả các môn bắt buộc thuộc chương trình của khóa học
    SELECT c.class_id, c.class_name, s.subject_id, s.subject_name
    FROM class c
    JOIN subject s ON c.program_id = s.program_id
    WHERE c.class_id = 'PRG_DATA_FALL_2026' AND s.is_deleted = FALSE
),
failed_attempts AS (
    -- Tập hợp tất cả các lần thi bị rớt (score <= 5.0) của học viên
    SELECT 
        er.student_id,
        er.class_id,
        er.subject_id,
        STRING_AGG(
            'Lần ' || er.attempt_number || ': ' || er.score || ' điểm (Ngày ' || TO_CHAR(er.exam_date, 'DD/MM/YYYY') || ')', 
            '; ' ORDER BY er.attempt_number
        ) AS failed_exam_history,
        MAX(er.score) AS highest_failed_score,
        COUNT(*) AS total_failed_attempts
    FROM exam_result er
    WHERE er.class_id = 'PRG_DATA_FALL_2026'
      AND er.score <= 5.0
      AND er.is_deleted = FALSE
    GROUP BY er.student_id, er.class_id, er.subject_id
),
passed_subjects AS (
    -- Những môn học viên đã thi ĐẠT (score > 5.0 ở bất kỳ lần nào)
    SELECT DISTINCT er.student_id, er.class_id, er.subject_id
    FROM exam_result er
    WHERE er.class_id = 'PRG_DATA_FALL_2026'
      AND er.score > 5.0
      AND er.is_deleted = FALSE
)
SELECT 
    e.student_id,
    st.full_name AS student_name,
    cts.class_id,
    cts.class_name,
    cts.subject_id,
    cts.subject_name,
    CASE 
        WHEN fa.total_failed_attempts IS NOT NULL THEN 'Chưa đạt (Thi rớt)'
        ELSE 'Chưa hoàn thành (Chưa dự thi)'
    END AS completion_status,
    COALESCE(fa.failed_exam_history, 'Chưa có lượt thi nào') AS failed_exam_details,
    COALESCE(fa.total_failed_attempts, 0) AS failed_attempts_count
FROM enrollment e
JOIN student st ON e.student_id = st.student_id
CROSS JOIN class_target_subjects cts
-- Loại bỏ các môn mà học viên ĐÃ THI ĐẠT
LEFT JOIN passed_subjects ps 
       ON e.student_id = ps.student_id 
      AND cts.subject_id = ps.subject_id
-- Lấy chi tiết điểm các lần thi chưa đạt
LEFT JOIN failed_attempts fa 
       ON e.student_id = fa.student_id 
      AND cts.subject_id = fa.subject_id
WHERE e.class_id = 'PRG_DATA_FALL_2026'
  AND e.is_deleted = FALSE
  AND ps.subject_id IS NULL -- Chỉ lấy các môn CHƯA HOÀN THÀNH
ORDER BY e.student_id, cts.subject_id;

-- =========================================================================
-- YÊU CẦU 4: TÍNH LƯƠNG CHO GIẢNG VIÊN TRONG MỘT THÁNG
-- Lương = Giờ dạy chính * Đơn giá + Giờ trợ giảng * (Đơn giá / 2)
-- (Đơn giá do Học viện xác định, ví dụ 200,000 VND / giờ)
-- =========================================================================

SELECT * FROM fn_calculate_instructor_salary(9, 2026, 200000);


-- =========================================================================
-- YÊU CẦU 5: TÍNH LƯƠNG CHO CÁC NHÂN VIÊN
-- Lương = Lương cứng (5tr) + Lương quản lý CTĐT (dựa trên số học viên)
--         + Thưởng quản lý cấp dưới (5% lương cứng x số cấp dưới)
-- =========================================================================

SELECT * FROM fn_calculate_staff_salary(50000);


-- =========================================================================
-- YÊU CẦU 6: CÁC CÂU TRUY VẤN KIỂM TRA RÀNG BUỘC SỐ LƯỢNG BẢN GHI
-- (ỨNG DỤNG SỬ DỤNG ĐỂ VALIDATION TRƯỚC KHI THỰC HIỆN GIAO DỊCH)
-- =========================================================================

-- 6.1. Kiểm tra giới hạn số môn học trong 1 CTĐT (Tối đa 10 môn)
-- Ứng dụng chạy câu này trước khi cho phép INSERT vào bảng subject
SELECT 
    program_id,
    COUNT(*) AS current_subjects,
    CASE 
        WHEN COUNT(*) >= 10 THEN 'BỊ CHẶN: Đã đạt tối đa 10 môn học'
        ELSE 'HỢP LỆ: Còn có thể thêm ' || (10 - COUNT(*)) || ' môn học'
    END AS validation_status
FROM subject
WHERE program_id = 'PRG_DATA' AND is_deleted = FALSE
GROUP BY program_id;

-- 6.2. Kiểm tra sĩ số lớp học trước khi cho học viên đăng ký (enrollment)
-- Không được vượt quá max_capacity của lớp
SELECT 
    c.class_id,
    c.class_name,
    c.max_capacity,
    COUNT(e.student_id) AS current_enrolled,
    (c.max_capacity - COUNT(e.student_id)) AS remaining_slots,
    CASE 
        WHEN COUNT(e.student_id) >= c.max_capacity THEN 'LỚP ĐÃ ĐẦY (FULL) - KHÔNG ĐƯỢC ĐĂNG KÝ'
        ELSE 'CÒN CHỖ TRỐNG - ĐĂNG KÝ ĐƯỢC'
    END AS registration_status
FROM class c
LEFT JOIN enrollment e ON c.class_id = e.class_id AND e.is_deleted = FALSE
WHERE c.class_id = 'PRG_DATA_FALL_2026' AND c.is_deleted = FALSE
GROUP BY c.class_id, c.class_name, c.max_capacity;

-- 6.3. Kiểm tra xung đột trùng phòng học trước khi xếp lịch (Tránh trùng phòng)
SELECT 
    session_id,
    class_id,
    room_id,
    start_time,
    end_time
FROM class_session
WHERE room_id = 'LAB_301'
  AND status <> 'CANCELED'
  AND is_deleted = FALSE
  -- Khung giờ dự kiến cần kiểm tra: '2026-09-02 18:30:00' đến '2026-09-02 20:30:00'
  AND start_time < '2026-09-02 20:30:00'
  AND end_time > '2026-09-02 18:30:00';

-- 6.4. Kiểm tra xung đột trùng lịch giảng viên trước khi xếp lịch
SELECT 
    session_id,
    class_id,
    start_time,
    end_time,
    main_instructor_id,
    teaching_assistant_id
FROM class_session
WHERE status <> 'CANCELED'
  AND is_deleted = FALSE
  -- Khung giờ dự kiến: '2026-09-02 19:00:00' đến '2026-09-02 21:00:00'
  AND start_time < '2026-09-02 21:00:00'
  AND end_time > '2026-09-02 19:00:00'
  -- Kiểm tra giảng viên INS_001 có đang dạy chính hoặc trợ giảng ở lớp nào khác không
  AND ('INS_001' IN (main_instructor_id, teaching_assistant_id));
