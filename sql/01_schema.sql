-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 1: TẠO CẤU TRÚC BẢNG (DDL) & RÀNG BUỘC TOÀN VẸN (CONSTRAINTS)
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
-- 1. BẢNG STAFF (Nhân sự & Quản lý phân cấp)
-- =========================================================================
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

-- =========================================================================
-- 2. BẢNG PROGRAM (Chương trình đào tạo)
-- =========================================================================
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

-- =========================================================================
-- 3. BẢNG SUBJECT (Môn học thuộc chương trình)
-- =========================================================================
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

-- =========================================================================
-- 4. BẢNG SEMESTER (Kỳ học)
-- =========================================================================
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

-- =========================================================================
-- 5. BẢNG CLASS (Khóa đào tạo / Lớp học phần)
-- =========================================================================
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

-- =========================================================================
-- 6. BẢNG STUDENT (Học viên)
-- =========================================================================
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

-- =========================================================================
-- 7. BẢNG INSTRUCTOR (Giáo viên / Giảng viên)
-- =========================================================================
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

-- =========================================================================
-- 8. BẢNG ROOM (Phòng học)
-- =========================================================================
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

-- =========================================================================
-- 9. BẢNG ENROLLMENT (Học viên tham gia khóa đào tạo)
-- =========================================================================
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

-- =========================================================================
-- 10. BẢNG CLASS_SESSION (Buổi học chi tiết)
-- =========================================================================
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

-- =========================================================================
-- 11. BẢNG EXAM_RESULT (Kết quả thi các lần của học viên)
-- =========================================================================
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
