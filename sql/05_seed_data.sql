-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 5: DỮ LIỆU MẪU BAN ĐẦU & MỞ RỘNG (EXPANDED SEED DATA)
-- Đáp ứng đầy đủ dữ liệu của cả học kỳ: nhiều CTĐT, nhiều khóa, nhiều lớp,
-- học viên học nhiều chương trình, đa dạng kết quả thi và phân bổ giảng dạy.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 5.1. BẢNG STAFF (Nhân sự & Phân cấp quản lý)
-- Cây phân cấp:
-- STF_001 (Director)
--   ├── STF_002 (Program Manager - PRG_DATA, PRG_CLOUD)
--   │     ├── STF_004 (Academic Coordinator)
--   │     └── STF_005 (Academic Officer)
--   └── STF_003 (Program Manager - PRG_WEB)
--         └── STF_006 (Admission Specialist)
-- -------------------------------------------------------------------------
INSERT INTO staff (staff_id, full_name, gender, date_of_birth, email, phone_number, position, manager_id, status)
VALUES 
('STF_001', 'Trần Văn An', 1, '1980-05-15', 'an.tran@system.edu.vn', '0901234567', 'Director', NULL, 'Active'),
('STF_002', 'Lê Thị Bình', 0, '1988-08-20', 'binh.le@system.edu.vn', '0912345678', 'Program Manager', 'STF_001', 'Active'),
('STF_003', 'Phạm Minh Cường', 1, '1992-11-10', 'cuong.pham@system.edu.vn', '0923456789', 'Program Manager', 'STF_001', 'Active'),
('STF_004', 'Hoàng Thu Trang', 0, '1995-04-18', 'trang.hoang@system.edu.vn', '0934567890', 'Academic Coordinator', 'STF_002', 'Active'),
('STF_005', 'Nguyễn Hải Đăng', 1, '1996-09-22', 'dang.nh@system.edu.vn', '0941234567', 'Academic Officer', 'STF_002', 'Active'),
('STF_006', 'Vũ Mai Phương', 0, '1994-12-03', 'phuong.vm@system.edu.vn', '0952345678', 'Admission Specialist', 'STF_003', 'Active')
ON CONFLICT (staff_id) DO UPDATE 
SET full_name = EXCLUDED.full_name,
    position = EXCLUDED.position,
    manager_id = EXCLUDED.manager_id;


-- -------------------------------------------------------------------------
-- 5.2. BẢNG PROGRAM (Chương trình đào tạo)
-- -------------------------------------------------------------------------
INSERT INTO program (program_id, program_name, description, version, manager_id, status)
VALUES 
('PRG_DATA', 'Data Analytics Professional', 'Phân tích dữ liệu ứng dụng chuyên sâu cho doanh nghiệp', '1.0', 'STF_002', 'ACTIVE'),
('PRG_WEB', 'Fullstack Web Developer', 'Phát triển ứng dụng Web Fullstack hiện đại', '1.0', 'STF_003', 'ACTIVE'),
('PRG_CLOUD', 'Cloud & DevOps Engineering', 'Kỹ sư Điện toán đám mây và Tự động hóa hạ tầng', '1.0', 'STF_002', 'ACTIVE')
ON CONFLICT (program_id) DO UPDATE 
SET program_name = EXCLUDED.program_name,
    manager_id = EXCLUDED.manager_id,
    status = EXCLUDED.status;


-- -------------------------------------------------------------------------
-- 5.3. BẢNG SUBJECT (Môn học)
-- Đảm bảo:
-- 1. Mã môn phản ánh mã CTĐT (bắt đầu bằng program_id)
-- 2. total_hours chẵn (mỗi buổi 2 giờ)
-- 3. Mỗi CTĐT có từ 2 - 4 môn (thỏa mãn: ít nhất 1 và tối đa 10 môn)
-- -------------------------------------------------------------------------
INSERT INTO subject (subject_id, subject_name, program_id, total_hours, subject_type)
VALUES 
-- Môn học thuộc PRG_DATA
('PRG_DATA_SQL', 'SQL căn bản và nâng cao', 'PRG_DATA', 30, 'CORE'),
('PRG_DATA_PY', 'Python cho xử lý dữ liệu', 'PRG_DATA', 40, 'CORE'),
('PRG_DATA_BI', 'PowerBI & Dashboard nâng cao', 'PRG_DATA', 30, 'ELECTIVE'),
('PRG_DATA_ML', 'Machine Learning ứng dụng', 'PRG_DATA', 40, 'CORE'),

-- Môn học thuộc PRG_WEB
('PRG_WEB_HTML', 'HTML5, CSS3 & Responsive Design', 'PRG_WEB', 20, 'CORE'),
('PRG_WEB_JS', 'JavaScript hiện đại & TypeScript', 'PRG_WEB', 30, 'CORE'),
('PRG_WEB_REACT', 'React.js & Next.js Framework', 'PRG_WEB', 40, 'CORE'),
('PRG_WEB_NODE', 'Node.js Backend & API Design', 'PRG_WEB', 40, 'CORE'),

-- Môn học thuộc PRG_CLOUD
('PRG_CLOUD_AWS', 'AWS Solutions Architect Associate', 'PRG_CLOUD', 40, 'CORE'),
('PRG_CLOUD_K8S', 'Docker & Kubernetes Administration', 'PRG_CLOUD', 30, 'CORE')
ON CONFLICT (subject_id) DO UPDATE 
SET subject_name = EXCLUDED.subject_name,
    total_hours = EXCLUDED.total_hours;


-- -------------------------------------------------------------------------
-- 5.4. BẢNG SEMESTER (Kỳ học)
-- -------------------------------------------------------------------------
INSERT INTO semester (semester_id, semester_name, start_date, end_date, status)
VALUES 
('SPRING_2026', 'Học kỳ Mùa Xuân 2026', '2026-01-05', '2026-05-30', 'FINISHED'),
('FALL_2026', 'Học kỳ Mùa Thu 2026', '2026-09-01', '2026-12-31', 'ONGOING'),
('SPRING_2027', 'Học kỳ Mùa Xuân 2027', '2027-01-05', '2027-05-30', 'UPCOMING')
ON CONFLICT (semester_id) DO UPDATE 
SET semester_name = EXCLUDED.semester_name,
    status = EXCLUDED.status;


-- -------------------------------------------------------------------------
-- 5.5. BẢNG CLASS (Khóa đào tạo / Lớp học)
-- Mã khóa học thể hiện CTĐT và Kỳ học: [program_id]_[semester_id]
-- -------------------------------------------------------------------------
INSERT INTO class (class_id, class_name, program_id, semester_id, max_capacity, status)
VALUES 
('PRG_DATA_SP_2026', 'Khóa Phân Tích Dữ Liệu K0 - Spring 2026', 'PRG_DATA', 'SPRING_2026', 20, 'CLOSED'),
('PRG_DATA_FALL_2026', 'Khóa Phân Tích Dữ Liệu K1 - Fall 2026', 'PRG_DATA', 'FALL_2026', 30, 'RUNNING'),
('PRG_WEB_FALL_2026', 'Khóa Lập Trình Web K1 - Fall 2026', 'PRG_WEB', 'FALL_2026', 25, 'RUNNING'),
('PRG_CLOUD_SP_2027', 'Khóa Cloud & DevOps K1 - Spring 2027', 'PRG_CLOUD', 'SPRING_2027', 30, 'OPEN')
ON CONFLICT (class_id) DO UPDATE 
SET class_name = EXCLUDED.class_name,
    status = EXCLUDED.status;


-- -------------------------------------------------------------------------
-- 5.6. BẢNG INSTRUCTOR (Giảng viên / Giáo viên)
-- -------------------------------------------------------------------------
INSERT INTO instructor (instructor_id, full_name, email, phone_number, specialization, degree, contract_type)
VALUES 
('INS_001', 'TS. Vũ Tuấn Đạt', 'dat.vu@lecturer.edu.vn', '0977889900', 'Cơ sở dữ liệu & Data Warehouse', 'Tiến sĩ', 'FULLTIME'),
('INS_002', 'ThS. Hoàng Mai Ly', 'ly.hoang@lecturer.edu.vn', '0966554433', 'Khoa học dữ liệu & Machine Learning', 'Thạc sĩ', 'PARTTIME'),
('INS_003', 'ThS. Nguyễn Quốc Anh', 'anh.nguyen@lecturer.edu.vn', '0945678901', 'Cloud Solutions & Big Data', 'Thạc sĩ', 'FULLTIME'),
('INS_004', 'TS. Đặng Minh Tuấn', 'tuan.dang@lecturer.edu.vn', '0933112233', 'Kỹ thuật phần mềm & Web Architecture', 'Tiến sĩ', 'FULLTIME'),
('INS_005', 'KS. Bùi Thị Ngọc', 'ngoc.bui@lecturer.edu.vn', '0912887766', 'Frontend Development & UI/UX', 'Kỹ sư', 'PARTTIME')
ON CONFLICT (instructor_id) DO UPDATE 
SET full_name = EXCLUDED.full_name,
    contract_type = EXCLUDED.contract_type;


-- -------------------------------------------------------------------------
-- 5.7. BẢNG ROOM (Phòng học)
-- -------------------------------------------------------------------------
INSERT INTO room (room_id, room_name, location, capacity, room_type, status)
VALUES 
('LAB_301', 'Phòng Thực hành 301', 'Tòa A - Tầng 3', 40, 'LAB', 'READY'),
('LAB_302', 'Phòng Thực hành 302', 'Tòa A - Tầng 3', 35, 'LAB', 'READY'),
('ROOM_201', 'Phòng Lý thuyết 201', 'Tòa B - Tầng 2', 50, 'STANDARD', 'READY'),
('ROOM_202', 'Phòng Hội thảo 202', 'Tòa B - Tầng 2', 45, 'STANDARD', 'READY')
ON CONFLICT (room_id) DO UPDATE 
SET room_name = EXCLUDED.room_name,
    capacity = EXCLUDED.capacity;


-- -------------------------------------------------------------------------
-- 5.8. BẢNG STUDENT (Học viên - 12 học viên với nguồn tuyển sinh đa dạng)
-- -------------------------------------------------------------------------
INSERT INTO student (student_id, full_name, date_of_birth, phone_number, email, source, status)
VALUES 
('STU_001', 'Nguyễn Hoàng Dũng', '2002-03-12', '0981112223', 'dung.nh@gmail.com', 'Facebook Ads', 'ACTIVE'),
('STU_002', 'Đỗ Phương Thảo', '2003-07-25', '0984445556', 'thao.dp@gmail.com', 'Website', 'ACTIVE'),
('STU_003', 'Trịnh Bảo Ngọc', '2004-09-18', '0919998877', 'ngoc.tb@gmail.com', 'Người quen giới thiệu', 'ACTIVE'),
('STU_004', 'Phạm Quốc Bảo', '2001-11-05', '0971239876', 'bao.pq@gmail.com', 'Hội thảo', 'ACTIVE'),
('STU_005', 'Lê Thanh Hương', '2002-05-30', '0963321456', 'huong.lt@gmail.com', 'TikTok Ads', 'ACTIVE'),
('STU_006', 'Vũ Đình Trọng', '2000-08-14', '0988765432', 'trong.vd@gmail.com', 'Google Search', 'ACTIVE'),
('STU_007', 'Bùi Minh Khôi', '2003-01-20', '0977654321', 'khoi.bm@gmail.com', 'Facebook Ads', 'ACTIVE'),
('STU_008', 'Nguyễn Thu Uyên', '2004-04-10', '0966543210', 'uyen.nt@gmail.com', 'Website', 'ACTIVE'),
('STU_009', 'Trần Văn Hùng', '1999-10-28', '0918765432', 'hung.tv@gmail.com', 'Người quen giới thiệu', 'ACTIVE'),
('STU_010', 'Đinh Hoàng Yến', '2002-12-15', '0943219876', 'yen.dh@gmail.com', 'Hội thảo', 'ACTIVE'),
('STU_011', 'Mai Anh Quân', '2001-06-08', '0932198765', 'quan.ma@gmail.com', 'Website', 'ACTIVE'),
('STU_012', 'Phan Thảo Nguyên', '2003-03-22', '0921987654', 'nguyen.pt@gmail.com', 'Facebook Ads', 'ACTIVE')
ON CONFLICT (student_id) DO UPDATE 
SET full_name = EXCLUDED.full_name,
    phone_number = EXCLUDED.phone_number;


-- -------------------------------------------------------------------------
-- 5.9. BẢNG ENROLLMENT (Học viên đăng ký khóa đào tạo)
-- - STU_005 đăng ký cả 2 khóa ở 2 CTĐT khác nhau
-- - STU_011 & STU_012 ở khóa PRG_DATA_SP_2026 đã COMPLETED
-- -------------------------------------------------------------------------
INSERT INTO enrollment (student_id, class_id, tuition_paid, status)
VALUES 
-- Lớp Data Fall 2026
('STU_001', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_002', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_003', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_004', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_005', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_006', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),

-- Lớp Web Fall 2026 (STU_005 học cả 2 khóa)
('STU_005', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_007', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_008', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_009', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_010', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),

-- Lớp Spring 2026 (Khóa đã kết thúc)
('STU_011', 'PRG_DATA_SP_2026', 14000000, 'COMPLETED'),
('STU_012', 'PRG_DATA_SP_2026', 14000000, 'COMPLETED')
ON CONFLICT (student_id, class_id) DO UPDATE 
SET tuition_paid = EXCLUDED.tuition_paid,
    status = EXCLUDED.status;


-- -------------------------------------------------------------------------
-- 5.10. BẢNG CLASS_SESSION (Buổi học chi tiết & Thời khóa biểu)
-- Phân bổ hợp lý trong Tháng 9/2026:
-- - Không trùng phòng tại cùng thời điểm
-- - Không trùng giảng viên/trợ giảng tại cùng thời điểm
-- - Thời lượng đúng 2 giờ
-- -------------------------------------------------------------------------
-- Làm sạch các buổi học cũ để nạp lịch biểu chuẩn không bị vi phạm unique/conflict
DELETE FROM class_session WHERE class_id IN ('PRG_DATA_FALL_2026', 'PRG_WEB_FALL_2026');

INSERT INTO class_session (class_id, subject_id, start_time, end_time, room_id, main_instructor_id, teaching_assistant_id, session_type, status)
VALUES 
-- Tuần 1: 02/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-02 18:00:00', '2026-09-02 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_HTML', '2026-09-02 18:00:00', '2026-09-02 20:00:00', 'ROOM_201', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),

-- Tuần 1: 04/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-04 18:00:00', '2026-09-04 20:00:00', 'LAB_301', 'INS_001', NULL, 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_HTML', '2026-09-04 18:00:00', '2026-09-04 20:00:00', 'ROOM_201', 'INS_004', NULL, 'NORMAL', 'COMPLETED'),

-- Tuần 2: 07/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-07 18:00:00', '2026-09-07 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_JS',   '2026-09-07 18:00:00', '2026-09-07 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),

-- Tuần 2: 09/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-09 18:00:00', '2026-09-09 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_JS',   '2026-09-09 18:00:00', '2026-09-09 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),

-- Tuần 2: 11/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-11 18:00:00', '2026-09-11 20:00:00', 'LAB_301', 'INS_002', NULL, 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_JS',   '2026-09-11 18:00:00', '2026-09-11 20:00:00', 'LAB_302', 'INS_005', NULL, 'NORMAL', 'COMPLETED'),

-- Tuần 3: 14/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-14 18:00:00', '2026-09-14 20:00:00', 'LAB_301', 'INS_003', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_REACT','2026-09-14 18:00:00', '2026-09-14 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),

-- Tuần 3: 16/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-16 18:00:00', '2026-09-16 20:00:00', 'LAB_301', 'INS_003', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_REACT','2026-09-16 18:00:00', '2026-09-16 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),

-- Tuần 3: 18/09/2026 (18:00 - 20:00)
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-18 18:00:00', '2026-09-18 20:00:00', 'LAB_301', 'INS_003', NULL, 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_REACT','2026-09-18 18:00:00', '2026-09-18 20:00:00', 'LAB_302', 'INS_004', NULL, 'NORMAL', 'COMPLETED'),

-- Các buổi học sắp tới trong Tháng 10/2026 (SCHEDULED)
('PRG_DATA_FALL_2026', 'PRG_DATA_BI',  '2026-10-05 18:00:00', '2026-10-05 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'SCHEDULED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_NODE', '2026-10-05 18:00:00', '2026-10-05 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'SCHEDULED');


-- -------------------------------------------------------------------------
-- 5.11. BẢNG EXAM_RESULT (Kết quả thi của học viên)
-- Đa dạng kịch bản phục vụ kiểm thử:
-- - Thi 1 lần đỗ ngay (score > 5.0)
-- - Thi rớt lần 1, thi lại lần 2 đỗ
-- - Thi rớt cả 2 lần (vẫn chưa hoàn thành)
-- - Học viên chưa tham gia thi (không có bản ghi)
-- - Khóa PRG_DATA_SP_2026 đã hoàn thành tất cả các môn
-- -------------------------------------------------------------------------
INSERT INTO exam_result (student_id, class_id, subject_id, attempt_number, score, exam_date, remarks)
VALUES 
-- 1. STU_001 (Thi rớt lần 1, thi lại lần 2 đạt môn SQL; môn Python đỗ lần 1)
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 4.5, '2026-09-20', 'Chưa đạt lý thuyết chỉ mục'),
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 2, 7.5, '2026-09-27', 'Thi lại đạt yêu cầu'),
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_PY',  1, 8.0, '2026-09-28', 'Bài thực hành xuất sắc'),

-- 2. STU_002 (Mới thi lần 1 bị rớt môn SQL, chưa thi lại)
('STU_002', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 3.5, '2026-09-20', 'Cần ôn tập lại câu lệnh JOIN'),

-- 3. STU_003 (Thi rớt cả 2 lần môn SQL -> Nợ môn kèm điểm các lần)
('STU_003', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 4.0, '2026-09-20', 'Thi lần 1 chưa đạt'),
('STU_003', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 2, 4.8, '2026-09-27', 'Thi lại lần 2 chưa đạt'),
('STU_003', 'PRG_DATA_FALL_2026', 'PRG_DATA_PY',  1, 6.5, '2026-09-28', 'Đạt'),

-- 4. STU_004 (Học lực giỏi, đỗ ngay lần đầu các môn đã thi)
('STU_004', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 9.0, '2026-09-20', 'Đạt điểm xuất sắc'),
('STU_004', 'PRG_DATA_FALL_2026', 'PRG_DATA_PY',  1, 8.5, '2026-09-28', 'Đạt điểm giỏi'),

-- 5. STU_006 (Điểm vừa chạm mức không đạt 5.0)
('STU_006', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 5.0, '2026-09-20', 'Đúng 5.0 - Chưa đạt theo quy định > 5'),

-- 6. Học viên lớp Web PRG_WEB_FALL_2026
('STU_007', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 1, 9.5, '2026-09-22', 'Giao diện chuẩn responsive'),
('STU_007', 'PRG_WEB_FALL_2026', 'PRG_WEB_JS',   1, 8.0, '2026-09-29', 'Tốt'),
('STU_008', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 1, 3.0, '2026-09-22', 'Chưa hoàn thành flexbox'),
('STU_008', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 2, 6.5, '2026-09-29', 'Thi lại đạt'),
('STU_008', 'PRG_WEB_FALL_2026', 'PRG_WEB_JS',   1, 4.0, '2026-09-29', 'Chưa đạt async/await'),
('STU_009', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 1, 7.0, '2026-09-22', 'Đạt'),

-- 7. Học viên khóa PRG_DATA_SP_2026 (Khóa đã kết thúc - hoàn thành toàn bộ môn học)
('STU_011', 'PRG_DATA_SP_2026', 'PRG_DATA_SQL', 1, 8.5, '2026-05-10', 'Tốt nghiệp'),
('STU_011', 'PRG_DATA_SP_2026', 'PRG_DATA_PY',  1, 9.0, '2026-05-15', 'Tốt nghiệp'),
('STU_011', 'PRG_DATA_SP_2026', 'PRG_DATA_BI',  1, 8.0, '2026-05-20', 'Tốt nghiệp'),
('STU_011', 'PRG_DATA_SP_2026', 'PRG_DATA_ML',  1, 8.5, '2026-05-25', 'Tốt nghiệp'),

('STU_012', 'PRG_DATA_SP_2026', 'PRG_DATA_SQL', 1, 6.5, '2026-05-10', 'Tốt nghiệp'),
('STU_012', 'PRG_DATA_SP_2026', 'PRG_DATA_PY',  1, 7.0, '2026-05-15', 'Tốt nghiệp'),
('STU_012', 'PRG_DATA_SP_2026', 'PRG_DATA_BI',  1, 6.0, '2026-05-20', 'Tốt nghiệp'),
('STU_012', 'PRG_DATA_SP_2026', 'PRG_DATA_ML',  1, 7.5, '2026-05-25', 'Tốt nghiệp')
ON CONFLICT (student_id, class_id, subject_id, attempt_number) DO UPDATE 
SET score = EXCLUDED.score,
    exam_date = EXCLUDED.exam_date,
    remarks = EXCLUDED.remarks;
