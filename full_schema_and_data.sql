-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- =========================================================================

-- Xóa bảng cũ nếu tồn tại để chạy lại từ đầu (Cascade)
DROP TABLE IF EXISTS exam_result CASCADE;
DROP TABLE IF EXISTS class_session CASCADE;
DROP TABLE IF EXISTS enrollment CASCADE;
DROP TABLE IF EXISTS room CASCADE;
DROP TABLE IF EXISTS instructor CASCADE;
DROP TABLE IF EXISTS student CASCADE;
DROP TABLE IF EXISTS class CASCADE;
DROP TABLE IF EXISTS semester CASCADE;
DROP TABLE IF EXISTS subject CASCADE;
DROP TABLE IF EXISTS program CASCADE;
DROP TABLE IF EXISTS staff CASCADE;

-- =========================================================================
-- 1. TẠO CÁC BẢNG THỰC THỂ
-- =========================================================================

-- 1.1. Bảng STAFF (Nhân sự & Quản lý phân cấp)
CREATE TABLE staff (
    staff_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    gender INT NOT NULL CHECK (gender IN (0, 1, 2)), -- 0: Female, 1: Male, 2: Other
    date_of_birth DATE NOT NULL CHECK (date_of_birth < CURRENT_DATE),
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) UNIQUE,
    position VARCHAR(50),
    manager_id VARCHAR(20) REFERENCES staff(staff_id), -- Cấp trên trực tiếp (Null nếu là Giám đốc)
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'ON_LEAVE', 'RESIGNED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.2. Bảng PROGRAM (Chương trình đào tạo)
CREATE TABLE program (
    program_id VARCHAR(20) PRIMARY KEY,
    program_name VARCHAR(150) NOT NULL,
    description TEXT,
    version VARCHAR(10),
    manager_id VARCHAR(20) NOT NULL REFERENCES staff(staff_id),
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ACTIVE', 'CLOSED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.3. Bảng SUBJECT (Môn học thuộc chương trình)
CREATE TABLE subject (
    subject_id VARCHAR(30) PRIMARY KEY, -- Thể hiện mã CTĐT, vd: PRG_DATA_SQL
    subject_name VARCHAR(100) NOT NULL,
    program_id VARCHAR(20) NOT NULL REFERENCES program(program_id),
    total_hours INT NOT NULL CHECK (total_hours > 0 AND total_hours % 2 = 0),
    total_sessions INT GENERATED ALWAYS AS (total_hours / 2) STORED, -- Mỗi buổi 2 giờ
    subject_type VARCHAR(20) NOT NULL DEFAULT 'CORE' CHECK (subject_type IN ('CORE', 'ELECTIVE')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Tên môn học không trùng lặp trong cùng 1 CTĐT
    CONSTRAINT uq_subject_program_name UNIQUE (program_id, subject_name)
);

-- 1.4. Bảng SEMESTER (Kỳ học)
CREATE TABLE semester (
    semester_id VARCHAR(20) PRIMARY KEY,
    semester_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'UPCOMING' CHECK (status IN ('UPCOMING', 'ONGOING', 'FINISHED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_semester_date CHECK (end_date > start_date)
);

-- 1.5. Bảng CLASS (Khóa đào tạo / Lớp học phần)
CREATE TABLE class (
    class_id VARCHAR(40) PRIMARY KEY, -- Ví dụ: PRG_DATA_FALL2026
    class_name VARCHAR(150) NOT NULL,
    program_id VARCHAR(20) NOT NULL REFERENCES program(program_id),
    semester_id VARCHAR(20) NOT NULL REFERENCES semester(semester_id),
    max_capacity INT NOT NULL CHECK (max_capacity > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'FULL', 'RUNNING', 'CLOSED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.6. Bảng STUDENT (Học viên)
CREATE TABLE student (
    student_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    source VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESERVED', 'DROPPED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.7. Bảng INSTRUCTOR (Giáo viên / Giảng viên)
CREATE TABLE instructor (
    instructor_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15),
    specialization VARCHAR(200),
    degree VARCHAR(50),
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('FULLTIME', 'PARTTIME')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.8. Bảng ROOM (Phòng học)
CREATE TABLE room (
    room_id VARCHAR(20) PRIMARY KEY,
    room_name VARCHAR(50) NOT NULL,
    location VARCHAR(200),
    capacity INT NOT NULL CHECK (capacity > 0),
    room_type VARCHAR(20) NOT NULL CHECK (room_type IN ('LAB', 'STANDARD')),
    status VARCHAR(20) NOT NULL DEFAULT 'READY' CHECK (status IN ('READY', 'MAINTENANCE')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.9. Bảng ENROLLMENT (Học viên tham gia khóa đào tạo)
CREATE TABLE enrollment (
    student_id VARCHAR(20) NOT NULL REFERENCES student(student_id),
    class_id VARCHAR(40) NOT NULL REFERENCES class(class_id),
    enrollment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tuition_paid NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (tuition_paid >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ENROLLED' CHECK (status IN ('ENROLLED', 'CANCELED', 'COMPLETED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (student_id, class_id)
);

-- 1.10. Bảng CLASS_SESSION (Buổi học chi tiết)
CREATE TABLE class_session (
    session_id BIGSERIAL PRIMARY KEY,
    class_id VARCHAR(40) NOT NULL REFERENCES class(class_id),
    subject_id VARCHAR(30) NOT NULL REFERENCES subject(subject_id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    room_id VARCHAR(20) NOT NULL REFERENCES room(room_id),
    main_instructor_id VARCHAR(20) NOT NULL REFERENCES instructor(instructor_id),
    teaching_assistant_id VARCHAR(20) REFERENCES instructor(instructor_id),
    session_type VARCHAR(20) NOT NULL DEFAULT 'NORMAL' CHECK (session_type IN ('NORMAL', 'EXAM')),
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELED')),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Ràng buộc thời lượng đúng 2 tiếng
    CONSTRAINT ck_session_duration CHECK (end_time = start_time + INTERVAL '2 hours'),
    -- Trợ giảng và Giảng viên chính phải là 2 người khác nhau
    CONSTRAINT ck_distinct_instructors CHECK (teaching_assistant_id IS NULL OR main_instructor_id <> teaching_assistant_id)
);

-- 1.11. Bảng EXAM_RESULT (Kết quả thi các lần của học viên)
CREATE TABLE exam_result (
    student_id VARCHAR(20) NOT NULL REFERENCES student(student_id),
    class_id VARCHAR(40) NOT NULL REFERENCES class(class_id),
    subject_id VARCHAR(30) NOT NULL REFERENCES subject(subject_id),
    attempt_number INT NOT NULL CHECK (attempt_number > 0),
    score NUMERIC(4, 2) NOT NULL CHECK (score >= 0 AND score <= 10),
    exam_date DATE NOT NULL,
    evaluation VARCHAR(20) GENERATED ALWAYS AS (CASE WHEN score > 5.0 THEN 'PASS' ELSE 'FAILED' END) STORED,
    remarks VARCHAR(200),
    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (student_id, class_id, subject_id, attempt_number)
);

-- =========================================================================
-- 2. PL/PGSQL TRIGGERS KIỂM SOÁT RÀNG BUỘC TOÀN VẸN
-- =========================================================================

-- 2.1. Ràng buộc: Mỗi CTĐT chỉ có tối đa 10 môn học
CREATE OR REPLACE FUNCTION fn_check_max_subjects_per_program()
RETURNS TRIGGER AS $$
DECLARE
    v_subject_count INT;
BEGIN
    SELECT COUNT(*) INTO v_subject_count
    FROM subject
    WHERE program_id = NEW.program_id AND is_deleted = FALSE;

    IF v_subject_count > 10 THEN
        RAISE EXCEPTION 'Mỗi chương trình đào tạo chỉ được phép có tối đa 10 môn học.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_max_subjects
AFTER INSERT OR UPDATE ON subject
FOR EACH ROW
EXECUTE FUNCTION fn_check_max_subjects_per_program();

-- 2.2. Ràng buộc: Tránh xung đột trùng phòng học
CREATE OR REPLACE FUNCTION fn_check_room_schedule_conflict()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM class_session
        WHERE room_id = NEW.room_id
          AND session_id <> COALESCE(NEW.session_id, -1)
          AND status <> 'CANCELED'
          AND is_deleted = FALSE
          AND NEW.status <> 'CANCELED'
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time
    ) THEN
        RAISE EXCEPTION 'Phòng học % đã có lịch học trong khoảng thời gian này.', NEW.room_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_room_conflict
BEFORE INSERT OR UPDATE ON class_session
FOR EACH ROW
EXECUTE FUNCTION fn_check_room_schedule_conflict();

-- 2.3. Ràng buộc: Tránh xung đột trùng lịch giảng viên (Chính & Trợ giảng)
CREATE OR REPLACE FUNCTION fn_check_instructor_schedule_conflict()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM class_session
        WHERE session_id <> COALESCE(NEW.session_id, -1)
          AND status <> 'CANCELED'
          AND is_deleted = FALSE
          AND NEW.status <> 'CANCELED'
          AND (
              main_instructor_id = NEW.main_instructor_id
              OR (NEW.teaching_assistant_id IS NOT NULL AND main_instructor_id = NEW.teaching_assistant_id)
              OR (teaching_assistant_id IS NOT NULL AND teaching_assistant_id = NEW.main_instructor_id)
              OR (teaching_assistant_id IS NOT NULL AND NEW.teaching_assistant_id IS NOT NULL AND teaching_assistant_id = NEW.teaching_assistant_id)
          )
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time
    ) THEN
        RAISE EXCEPTION 'Giảng viên hoặc Trợ giảng đã có lịch giảng dạy khác trong khung giờ này.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_instructor_conflict
BEFORE INSERT OR UPDATE ON class_session
FOR EACH ROW
EXECUTE FUNCTION fn_check_instructor_schedule_conflict();

-- =========================================================================
-- 3. FUNCTIONS TRUY VẤN VÀ TÍNH TOÁN NGHIỆP VỤ
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

-- =========================================================================
-- 4. DỮ LIỆU MẪU BAN ĐẦU & MỞ RỘNG (EXPANDED SEED DATA)
-- =========================================================================

-- 4.1. Staff (Nhân sự & Phân cấp quản lý)
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

-- 4.2. Program (Chương trình đào tạo)
INSERT INTO program (program_id, program_name, description, version, manager_id, status)
VALUES 
('PRG_DATA', 'Data Analytics Professional', 'Phân tích dữ liệu ứng dụng chuyên sâu cho doanh nghiệp', '1.0', 'STF_002', 'ACTIVE'),
('PRG_WEB', 'Fullstack Web Developer', 'Phát triển ứng dụng Web Fullstack hiện đại', '1.0', 'STF_003', 'ACTIVE'),
('PRG_CLOUD', 'Cloud & DevOps Engineering', 'Kỹ sư Điện toán đám mây và Tự động hóa hạ tầng', '1.0', 'STF_002', 'ACTIVE')
ON CONFLICT (program_id) DO UPDATE 
SET program_name = EXCLUDED.program_name,
    manager_id = EXCLUDED.manager_id,
    status = EXCLUDED.status;

-- 4.3. Subject (Môn học)
INSERT INTO subject (subject_id, subject_name, program_id, total_hours, subject_type)
VALUES 
-- PRG_DATA
('PRG_DATA_SQL', 'SQL căn bản và nâng cao', 'PRG_DATA', 30, 'CORE'),
('PRG_DATA_PY', 'Python cho xử lý dữ liệu', 'PRG_DATA', 40, 'CORE'),
('PRG_DATA_BI', 'PowerBI & Dashboard nâng cao', 'PRG_DATA', 30, 'ELECTIVE'),
('PRG_DATA_ML', 'Machine Learning ứng dụng', 'PRG_DATA', 40, 'CORE'),
-- PRG_WEB
('PRG_WEB_HTML', 'HTML5, CSS3 & Responsive Design', 'PRG_WEB', 20, 'CORE'),
('PRG_WEB_JS', 'JavaScript hiện đại & TypeScript', 'PRG_WEB', 30, 'CORE'),
('PRG_WEB_REACT', 'React.js & Next.js Framework', 'PRG_WEB', 40, 'CORE'),
('PRG_WEB_NODE', 'Node.js Backend & API Design', 'PRG_WEB', 40, 'CORE'),
-- PRG_CLOUD
('PRG_CLOUD_AWS', 'AWS Solutions Architect Associate', 'PRG_CLOUD', 40, 'CORE'),
('PRG_CLOUD_K8S', 'Docker & Kubernetes Administration', 'PRG_CLOUD', 30, 'CORE')
ON CONFLICT (subject_id) DO UPDATE 
SET subject_name = EXCLUDED.subject_name,
    total_hours = EXCLUDED.total_hours;

-- 4.4. Semester (Kỳ học)
INSERT INTO semester (semester_id, semester_name, start_date, end_date, status)
VALUES 
('SPRING_2026', 'Học kỳ Mùa Xuân 2026', '2026-01-05', '2026-05-30', 'FINISHED'),
('FALL_2026', 'Học kỳ Mùa Thu 2026', '2026-09-01', '2026-12-31', 'ONGOING'),
('SPRING_2027', 'Học kỳ Mùa Xuân 2027', '2027-01-05', '2027-05-30', 'UPCOMING')
ON CONFLICT (semester_id) DO UPDATE 
SET semester_name = EXCLUDED.semester_name,
    status = EXCLUDED.status;

-- 4.5. Class (Khóa đào tạo / Lớp học)
INSERT INTO class (class_id, class_name, program_id, semester_id, max_capacity, status)
VALUES 
('PRG_DATA_SP_2026', 'Khóa Phân Tích Dữ Liệu K0 - Spring 2026', 'PRG_DATA', 'SPRING_2026', 20, 'CLOSED'),
('PRG_DATA_FALL_2026', 'Khóa Phân Tích Dữ Liệu K1 - Fall 2026', 'PRG_DATA', 'FALL_2026', 30, 'RUNNING'),
('PRG_WEB_FALL_2026', 'Khóa Lập Trình Web K1 - Fall 2026', 'PRG_WEB', 'FALL_2026', 25, 'RUNNING'),
('PRG_CLOUD_SP_2027', 'Khóa Cloud & DevOps K1 - Spring 2027', 'PRG_CLOUD', 'SPRING_2027', 30, 'OPEN')
ON CONFLICT (class_id) DO UPDATE 
SET class_name = EXCLUDED.class_name,
    status = EXCLUDED.status;

-- 4.6. Instructor (Giảng viên / Giáo viên)
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

-- 4.7. Room (Phòng học)
INSERT INTO room (room_id, room_name, location, capacity, room_type, status)
VALUES 
('LAB_301', 'Phòng Thực hành 301', 'Tòa A - Tầng 3', 40, 'LAB', 'READY'),
('LAB_302', 'Phòng Thực hành 302', 'Tòa A - Tầng 3', 35, 'LAB', 'READY'),
('ROOM_201', 'Phòng Lý thuyết 201', 'Tòa B - Tầng 2', 50, 'STANDARD', 'READY'),
('ROOM_202', 'Phòng Hội thảo 202', 'Tòa B - Tầng 2', 45, 'STANDARD', 'READY')
ON CONFLICT (room_id) DO UPDATE 
SET room_name = EXCLUDED.room_name,
    capacity = EXCLUDED.capacity;

-- 4.8. Student (Học viên)
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

-- 4.9. Enrollment (Học viên đăng ký khóa đào tạo)
INSERT INTO enrollment (student_id, class_id, tuition_paid, status)
VALUES 
('STU_001', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_002', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_003', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_004', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_005', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_006', 'PRG_DATA_FALL_2026', 15000000, 'ENROLLED'),
('STU_005', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_007', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_008', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_009', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_010', 'PRG_WEB_FALL_2026', 16500000, 'ENROLLED'),
('STU_011', 'PRG_DATA_SP_2026', 14000000, 'COMPLETED'),
('STU_012', 'PRG_DATA_SP_2026', 14000000, 'COMPLETED')
ON CONFLICT (student_id, class_id) DO UPDATE 
SET tuition_paid = EXCLUDED.tuition_paid,
    status = EXCLUDED.status;

-- 4.10. ClassSession (Buổi học chi tiết)
DELETE FROM class_session WHERE class_id IN ('PRG_DATA_FALL_2026', 'PRG_WEB_FALL_2026');

INSERT INTO class_session (class_id, subject_id, start_time, end_time, room_id, main_instructor_id, teaching_assistant_id, session_type, status)
VALUES 
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-02 18:00:00', '2026-09-02 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_HTML', '2026-09-02 18:00:00', '2026-09-02 20:00:00', 'ROOM_201', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-04 18:00:00', '2026-09-04 20:00:00', 'LAB_301', 'INS_001', NULL, 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_HTML', '2026-09-04 18:00:00', '2026-09-04 20:00:00', 'ROOM_201', 'INS_004', NULL, 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-07 18:00:00', '2026-09-07 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_JS',   '2026-09-07 18:00:00', '2026-09-07 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_SQL', '2026-09-09 18:00:00', '2026-09-09 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_JS',   '2026-09-09 18:00:00', '2026-09-09 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-11 18:00:00', '2026-09-11 20:00:00', 'LAB_301', 'INS_002', NULL, 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_JS',   '2026-09-11 18:00:00', '2026-09-11 20:00:00', 'LAB_302', 'INS_005', NULL, 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-14 18:00:00', '2026-09-14 20:00:00', 'LAB_301', 'INS_003', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_REACT','2026-09-14 18:00:00', '2026-09-14 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-16 18:00:00', '2026-09-16 20:00:00', 'LAB_301', 'INS_003', 'INS_002', 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_REACT','2026-09-16 18:00:00', '2026-09-16 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_PY',  '2026-09-18 18:00:00', '2026-09-18 20:00:00', 'LAB_301', 'INS_003', NULL, 'NORMAL', 'COMPLETED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_REACT','2026-09-18 18:00:00', '2026-09-18 20:00:00', 'LAB_302', 'INS_004', NULL, 'NORMAL', 'COMPLETED'),
('PRG_DATA_FALL_2026', 'PRG_DATA_BI',  '2026-10-05 18:00:00', '2026-10-05 20:00:00', 'LAB_301', 'INS_001', 'INS_002', 'NORMAL', 'SCHEDULED'),
('PRG_WEB_FALL_2026',  'PRG_WEB_NODE', '2026-10-05 18:00:00', '2026-10-05 20:00:00', 'LAB_302', 'INS_004', 'INS_005', 'NORMAL', 'SCHEDULED');

-- 4.11. ExamResult (Kết quả thi)
INSERT INTO exam_result (student_id, class_id, subject_id, attempt_number, score, exam_date, remarks)
VALUES 
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 4.5, '2026-09-20', 'Chưa đạt lý thuyết chỉ mục'),
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 2, 7.5, '2026-09-27', 'Thi lại đạt yêu cầu'),
('STU_001', 'PRG_DATA_FALL_2026', 'PRG_DATA_PY',  1, 8.0, '2026-09-28', 'Bài thực hành xuất sắc'),
('STU_002', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 3.5, '2026-09-20', 'Cần ôn tập lại câu lệnh JOIN'),
('STU_003', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 4.0, '2026-09-20', 'Thi lần 1 chưa đạt'),
('STU_003', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 2, 4.8, '2026-09-27', 'Thi lại lần 2 chưa đạt'),
('STU_003', 'PRG_DATA_FALL_2026', 'PRG_DATA_PY',  1, 6.5, '2026-09-28', 'Đạt'),
('STU_004', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 9.0, '2026-09-20', 'Đạt điểm xuất sắc'),
('STU_004', 'PRG_DATA_FALL_2026', 'PRG_DATA_PY',  1, 8.5, '2026-09-28', 'Đạt điểm giỏi'),
('STU_006', 'PRG_DATA_FALL_2026', 'PRG_DATA_SQL', 1, 5.0, '2026-09-20', 'Đúng 5.0 - Chưa đạt theo quy định > 5'),
('STU_007', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 1, 9.5, '2026-09-22', 'Giao diện chuẩn responsive'),
('STU_007', 'PRG_WEB_FALL_2026', 'PRG_WEB_JS',   1, 8.0, '2026-09-29', 'Tốt'),
('STU_008', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 1, 3.0, '2026-09-22', 'Chưa hoàn thành flexbox'),
('STU_008', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 2, 6.5, '2026-09-29', 'Thi lại đạt'),
('STU_008', 'PRG_WEB_FALL_2026', 'PRG_WEB_JS',   1, 4.0, '2026-09-29', 'Chưa đạt async/await'),
('STU_009', 'PRG_WEB_FALL_2026', 'PRG_WEB_HTML', 1, 7.0, '2026-09-22', 'Đạt'),
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