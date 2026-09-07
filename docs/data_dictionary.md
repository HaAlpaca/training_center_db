# TỪ ĐIỂN DỮ LIỆU (DATA DICTIONARY)
## Hệ CSDL Quản Lý Đào Tạo

---

### Quy chuẩn chung (Audit Fields)
Mọi bảng nghiệp vụ trong hệ thống đều tích hợp 4 trường kiểm toán:
* `created_at` (TIMESTAMP): Thời điểm tạo bản ghi (Mặc định `CURRENT_TIMESTAMP`).
* `created_by` (VARCHAR(50)): Định danh tác nhân tạo (Mặc định `'SYSTEM'`).
* `updated_at` (TIMESTAMP): Thời điểm cập nhật dữ liệu gần nhất.
* `is_deleted` (BOOLEAN): Cơ chế Soft Delete (Mặc định `FALSE`).

---

### Danh sách các bảng thực thể

#### 1. Bảng `staff` (Nhân sự & Phân cấp quản lý)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `staff_id` | VARCHAR(20) | **PK** | Mã định danh nhân viên |
| `full_name` | VARCHAR(100) | NOT NULL | Họ và tên nhân viên |
| `gender` | INT | NOT NULL, CHECK (0, 1, 2) | Giới tính (0: Nữ, 1: Nam, 2: Khác) |
| `date_of_birth` | DATE | NOT NULL, < CURRENT_DATE | Ngày sinh |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Email công vụ |
| `phone_number` | VARCHAR(15) | UNIQUE | Số điện thoại liên hệ |
| `position` | VARCHAR(50) | NULL | Chức vụ (Giám đốc, Quản lý CTĐT, ...) |
| `manager_id` | VARCHAR(20) | FK -> `staff(staff_id)` | Mã quản lý trực tiếp (Đệ quy phân cấp) |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('Active', 'ON_LEAVE', 'RESIGNED') | Trạng thái làm việc |

#### 2. Bảng `program` (Chương trình đào tạo)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `program_id` | VARCHAR(20) | **PK** | Mã chương trình đào tạo |
| `program_name` | VARCHAR(150) | NOT NULL | Tên chương trình |
| `description` | TEXT | NULL | Mô tả chi tiết chương trình |
| `version` | VARCHAR(10) | NULL | Phiên bản chương trình |
| `manager_id` | VARCHAR(20) | NOT NULL, FK -> `staff(staff_id)` | Nhân sự phụ trách chương trình |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('DRAFT', 'ACTIVE', 'CLOSED') | Trạng thái chương trình |

#### 3. Bảng `subject` (Môn học)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `subject_id` | VARCHAR(30) | **PK** | Mã môn học |
| `subject_name` | VARCHAR(100) | NOT NULL | Tên môn học |
| `program_id` | VARCHAR(20) | NOT NULL, FK -> `program(program_id)` | Thuộc chương trình nào |
| `total_hours` | INT | NOT NULL, CHECK (>0 AND chẵn) | Tổng số giờ học |
| `total_sessions`| INT | GENERATED (total_hours / 2) | Tổng số buổi học (Mỗi buổi 2 giờ) |
| `subject_type` | VARCHAR(20) | NOT NULL, CHECK ('CORE', 'ELECTIVE') | Bắt buộc hoặc tự chọn |

#### 4. Bảng `semester` (Học kỳ)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `semester_id` | VARCHAR(20) | **PK** | Mã học kỳ |
| `semester_name` | VARCHAR(100) | NOT NULL | Tên học kỳ |
| `start_date` | DATE | NOT NULL | Ngày bắt đầu |
| `end_date` | DATE | NOT NULL, CHECK (end_date > start_date) | Ngày kết thúc |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('UPCOMING', 'ONGOING', 'FINISHED') | Trạng thái học kỳ |

#### 5. Bảng `class` (Lớp học phần / Khóa đào tạo)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `class_id` | VARCHAR(40) | **PK** | Mã lớp học |
| `class_name` | VARCHAR(150) | NOT NULL | Tên lớp |
| `program_id` | VARCHAR(20) | NOT NULL, FK -> `program(program_id)` | Thuộc chương trình đào tạo |
| `semester_id` | VARCHAR(20) | NOT NULL, FK -> `semester(semester_id)` | Thuộc kỳ học nào |
| `max_capacity` | INT | NOT NULL, CHECK (> 0) | Sĩ số tối đa |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('OPEN', 'FULL', 'RUNNING', 'CLOSED') | Trạng thái lớp |

#### 6. Bảng `student` (Học viên)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `student_id` | VARCHAR(20) | **PK** | Mã định danh học viên |
| `full_name` | VARCHAR(100) | NOT NULL | Họ và tên |
| `date_of_birth` | DATE | NOT NULL | Ngày sinh |
| `phone_number` | VARCHAR(15) | NOT NULL, UNIQUE | Số điện thoại |
| `email` | VARCHAR(100) | UNIQUE | Địa chỉ email |
| `source` | VARCHAR(50) | NULL | Nguồn tuyển sinh (Facebook, Giới thiệu...) |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('ACTIVE', 'RESERVED', 'DROPPED') | Trạng thái học tập |

#### 7. Bảng `instructor` (Giảng viên / Trợ giảng)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `instructor_id`| VARCHAR(20) | **PK** | Mã định danh giảng viên |
| `full_name` | VARCHAR(100) | NOT NULL | Họ và tên |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Email công vụ |
| `phone_number` | VARCHAR(15) | NULL | Số điện thoại |
| `specialization`| VARCHAR(200) | NULL | Chuyên môn / Lĩnh vực giảng dạy |
| `degree` | VARCHAR(50) | NULL | Trình độ / Học vị (Cử nhân, Thạc sĩ, Tiến sĩ) |
| `contract_type`| VARCHAR(20) | NOT NULL, CHECK ('FULLTIME', 'PARTTIME') | Loại hình hợp đồng |

#### 8. Bảng `room` (Phòng học)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `room_id` | VARCHAR(20) | **PK** | Mã phòng học |
| `room_name` | VARCHAR(50) | NOT NULL | Tên phòng học |
| `location` | VARCHAR(200) | NULL | Vị trí (Tòa nhà, số tầng) |
| `capacity` | INT | NOT NULL, CHECK (> 0) | Sức chứa tối đa (chỗ ngồi) |
| `room_type` | VARCHAR(20) | NOT NULL, CHECK ('LAB', 'STANDARD') | Phòng máy tính thực hành hoặc lý thuyết |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('READY', 'MAINTENANCE') | Trạng thái phòng |

#### 9. Bảng `enrollment` (Đăng ký học & Học phí)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `student_id` | VARCHAR(20) | **PK**, FK -> `student(student_id)` | Mã học viên |
| `class_id` | VARCHAR(40) | **PK**, FK -> `class(class_id)` | Mã lớp đăng ký |
| `enrollment_date`| TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Ngày đăng ký tham gia |
| `tuition_paid` | NUMERIC(15, 2)| NOT NULL, DEFAULT 0, CHECK (>= 0) | Số tiền học phí đã đóng |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('ENROLLED', 'CANCELED', 'COMPLETED') | Tình trạng theo học |

#### 10. Bảng `class_session` (Buổi học chi tiết & Thời khóa biểu)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `session_id` | BIGSERIAL | **PK** | Mã tự tăng buổi học |
| `class_id` | VARCHAR(40) | NOT NULL, FK -> `class(class_id)` | Thuộc lớp học nào |
| `subject_id` | VARCHAR(30) | NOT NULL, FK -> `subject(subject_id)` | Thuộc môn học nào |
| `start_time` | TIMESTAMP | NOT NULL | Thời gian bắt đầu |
| `end_time` | TIMESTAMP | NOT NULL, CHECK (end_time = start_time + 2h) | Thời gian kết thúc (đúng 2 giờ) |
| `room_id` | VARCHAR(20) | NOT NULL, FK -> `room(room_id)` | Phòng học tổ chức |
| `main_instructor_id` | VARCHAR(20) | NOT NULL, FK -> `instructor` | Giảng viên đứng lớp chính |
| `teaching_assistant_id` | VARCHAR(20) | NULL, FK -> `instructor` | Trợ giảng (khác giảng viên chính) |
| `session_type` | VARCHAR(20) | NOT NULL, CHECK ('NORMAL', 'EXAM') | Buổi học thường hoặc buổi thi |
| `status` | VARCHAR(20) | NOT NULL, CHECK ('SCHEDULED', 'COMPLETED', 'CANCELED') | Trạng thái buổi học |

#### 11. Bảng `exam_result` (Kết quả thi của học viên)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `student_id` | VARCHAR(20) | **PK**, FK -> `student(student_id)` | Mã học viên |
| `class_id` | VARCHAR(40) | **PK**, FK -> `class(class_id)` | Mã lớp |
| `subject_id` | VARCHAR(30) | **PK**, FK -> `subject(subject_id)` | Mã môn thi |
| `attempt_number`| INT | **PK**, NOT NULL, CHECK (> 0) | Lần thi (1, 2, ...) |
| `score` | NUMERIC(4, 2)| NOT NULL, CHECK (0 <= score <= 10) | Điểm số đạt được |
| `exam_date` | DATE | NOT NULL | Ngày thi |
| `evaluation` | VARCHAR(20) | GENERATED (CASE WHEN score > 5 THEN 'PASS' ELSE 'FAILED') | Đánh giá Đạt / Chưa đạt |
| `remarks` | VARCHAR(200)| NULL | Ghi chú thêm |
