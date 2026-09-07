-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 5: DỮ LIỆU MẪU BAN ĐẦU (SEED DATA)
-- =========================================================================

-- 5.1. Staff (Nhân sự & Phân cấp quản lý)
INSERT INTO staff (staff_id, full_name, gender, date_of_birth, email, phone_number, position, manager_id)
VALUES 
('STF_001', 'Trần Văn An', 1, '1980-05-15', 'an.tran@system.edu.vn', '0901234567', 'Director', NULL),
('STF_002', 'Lê Thị Bình', 0, '1988-08-20', 'binh.le@system.edu.vn', '0912345678', 'Program Manager', 'STF_001'),
('STF_003', 'Phạm Minh Cường', 1, '1992-11-10', 'cuong.pham@system.edu.vn', '0923456789', 'Coordinator', 'STF_002');

-- 5.2. Program (Chương trình đào tạo)
INSERT INTO program (program_id, program_name, description, version, manager_id, status)
VALUES 
('PRG_DATA', 'Data Analytics Professional', 'Phân tích dữ liệu ứng dụng', '1.0', 'STF_002', 'ACTIVE'),
('PRG_WEB', 'Fullstack Web Developer', 'Phát triển ứng dụng Web', '1.0', 'STF_002', 'ACTIVE');

-- 5.3. Subject (Môn học)
INSERT INTO subject (subject_id, subject_name, program_id, total_hours, subject_type)
VALUES 
('PRG_DATA_SQL', 'SQL căn bản và nâng cao', 'PRG_DATA', 30, 'CORE'),
('PRG_DATA_PY', 'Python cho xử lý dữ liệu', 'PRG_DATA', 40, 'CORE'),
('PRG_WEB_JS', 'JavaScript hiện đại', 'PRG_WEB', 30, 'CORE');

-- 5.4. Semester (Kỳ học)
INSERT INTO semester (semester_id, semester_name, start_date, end_date, status)
VALUES 
('FALL_2026', 'Học kỳ Mùa Thu 2026', '2026-09-01', '2026-12-31', 'ONGOING');

-- 5.5. Class (Khóa đào tạo / Lớp học)
INSERT INTO class (class_id, class_name, program_id, semester_id, max_capacity, status)
VALUES 
('PRG_DATA_FALL_2026', 'Khóa Phân Tích Dữ Liệu K1 - Fall 2026', 'PRG_DATA', 'FALL_2026', 30, 'RUNNING');

-- 5.6. Student (Học viên)
INSERT INTO student (student_id, full_name, date_of_birth, phone_number, email)
VALUES 
('STU_001', 'Nguyễn Hoàng Dũng', '2002-03-12', '0981112223', 'dung.nh@gmail.com'),
('STU_002', 'Đỗ Phương Thảo', '2003-07-25', '0984445556', 'thao.dp@gmail.com');

-- 5.7. Instructor (Giảng viên)
INSERT INTO instructor (instructor_id, full_name, email, phone_number, specialization, degree, contract_type)
VALUES 
('INS_001', 'TS. Vũ Tuấn Đạt', 'dat.vu@lecturer.edu.vn', '0977889900', 'Cơ sở dữ liệu', 'Tiến sĩ', 'FULLTIME'),
('INS_002', 'ThS. Hoàng Mai Ly', 'ly.hoang@lecturer.edu.vn', '0966554433', 'Khoa học máy tính', 'Thạc sĩ', 'PARTTIME');

-- 5.8. Room (Phòng học)
INSERT INTO room (room_id, room_name, location, capacity, room_type, status)
VALUES 
('LAB_301', 'Phòng Thực hành 301', 'Tòa A - Tầng 3', 40, 'LAB', 'READY');

-- 5.9. Enrollment (Học viên đăng ký lớp)
INSERT INTO enrollment (student_id, class_id, tuition_paid)
VALUES 
('STU_001', 'PRG_DATA_FALL_2026', 15000000),
('STU_002', 'PRG_DATA_FALL_2026', 15000000);

-- 5.10. ClassSession (Buổi học chi tiết)
INSERT INTO class_session (class_id, subject_id, start_time, end_time, room_id, main_instructor_id, teaching_assistant_id, status)
VALUES 
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-02 18:00:00', '2026-09-02 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-04 18:00:00', '2026-09-04 20:00:00', 'LAB_301', 'INS_001', NULL, 'COMPLETED');

-- 5.11. ExamResult (Kết quả thi)
INSERT INTO exam_result (student_id, class_id, subject_id, attempt_number, score, exam_date)
VALUES 
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 4.5, '2026-09-20'),
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 2, 7.5, '2026-09-27'),
('STU_002', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 3.5, '2026-09-20');
