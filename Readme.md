# HỆ CƠ SỞ DỮ LIỆU QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3)

Dự án Cơ sở dữ liệu quan hệ xây dựng trên hệ quản trị **PostgreSQL 16**, bao gồm kiến trúc phân rã module DDL, ràng buộc toàn vẹn nâng cao bằng Triggers PL/pgSQL, Functions nghiệp vụ, Views báo cáo, kịch bản kiểm thử tự động và môi trường container hóa với Docker Compose.

---

## 1. Cấu trúc thư mục dự án

```text
CSDL/
├── .env.example                  # File cấu hình biến môi trường mẫu
├── docker-compose.yml            # Khởi chạy PostgreSQL + pgAdmin bằng 1 lệnh
├── readme.md                     # Tài liệu hướng dẫn sử dụng và kiến trúc
│
├── sql/                          # Các script SQL tự động thực thi theo thứ tự khi khởi tạo
│   ├── 01_schema.sql             # DDL: Định nghĩa 11 bảng, khóa chính, khóa ngoại, CHECK constraints
│   ├── 02_triggers.sql           # Triggers PL/pgSQL: Chống trùng phòng, trùng lịch GV, giới hạn môn
│   ├── 03_functions.sql          # Stored Functions: Bảng điểm, tính lương GV & NV, SV chưa đạt
│   ├── 04_views.sql              # Views: Thống kê sĩ số, doanh thu học phí, tỷ lệ đỗ môn
│   ├── 05_seed_data.sql          # Dữ liệu mẫu (Insert kiểm thử)
│   └── 06_queries_reports.sql    # Kịch bản truy vấn mẫu, demo nghiệp vụ và phân tích
│
├── docs/                         # Tài liệu thiết kế hệ thống
│   ├── erd.md                    # Sơ đồ quan hệ thực thể (ERD) dạng Mermaid
│   └── data_dictionary.md        # Từ điển dữ liệu chi tiết (11 bảng, kiểu dữ liệu, ràng buộc)
│
└── tests/                        # Kịch bản kiểm thử
    └── test_triggers.sql         # Test cases cố tình vi phạm để kiểm tra phản ứng của Triggers
```

---

## 2. Thông tin kết nối & Dịch vụ

### PostgreSQL Database
* **Host:** `localhost` (hoặc `csdl_postgres` nếu kết nối nội bộ giữa các container)
* **Port:** `5432`
* **Database Name:** `training_db`
* **Username:** `admin`
* **Password:** `admin_password`

### pgAdmin 4 (Giao diện đồ họa web)
* **URL:** [http://localhost:5050](http://localhost:5050)
* **Email:** `admin@admin.com`
* **Password:** `admin_password`

---

## 3. Hướng dẫn khởi chạy nhanh (Quick Start)

### Bước 1: Khởi động hệ thống bằng Docker Compose
Mở PowerShell hoặc Terminal tại thư mục `d:\MASTER\CSDL`, chạy lệnh:

```bash
docker compose up -d
```

> **Cơ chế tự động:** Thư mục `./sql` được mount trực tiếp vào `/docker-entrypoint-initdb.d` của PostgreSQL. Khi container khởi tạo lần đầu, Postgres sẽ tự động thực thi các file theo thứ tự alphabet:
> `01_schema.sql` $\rightarrow$ `02_triggers.sql` $\rightarrow$ `03_functions.sql` $\rightarrow$ `04_views.sql` $\rightarrow$ `05_seed_data.sql` $\rightarrow$ `06_queries_reports.sql`.

---

### Bước 2: Truy cập và quản lý trên pgAdmin

1. Mở trình duyệt vào [http://localhost:5050](http://localhost:5050).
2. Đăng nhập bằng tài khoản:
   * **Email:** `admin@admin.com`
   * **Password:** `admin_password`
3. Đăng ký kết nối tới CSDL:
   * Nhấp chuột phải vào mục **Servers** $\rightarrow$ chọn **Register** $\rightarrow$ **Server...**
   * Tab **General**: Đặt tên gợi nhớ (ví dụ: `Training_DB`).
   * Tab **Connection**:
     * **Host name/address:** `csdl_postgres` (tên container) hoặc `host.docker.internal`
     * **Port:** `5432`
     * **Maintenance database:** `training_db`
     * **Username:** `admin`
     * **Password:** `admin_password`
   * Nhấn **Save**.

---

### Bước 3: Chạy thử kịch bản kiểm tra Triggers

Mở Query Tool trong pgAdmin (hoặc dùng `psql`) và thực thi nội dung trong file [tests/test_triggers.sql](file:///d:/MASTER/CSDL/tests/test_triggers.sql):

* **Test Case 1 (Trùng phòng học):** Thử xếp buổi học vào phòng `LAB_301` trùng khung giờ 18:30 - 20:30 $\rightarrow$ Trigger `trg_check_room_conflict` sẽ chặn và thông báo lỗi.
* **Test Case 2 (Trùng lịch giảng viên):** Thử xếp giảng viên `INS_001` dạy lớp khác trong cùng khung giờ $\rightarrow$ Trigger `trg_check_instructor_conflict` sẽ chặn.
* **Test Case 3 (Giới hạn môn học):** Thử thêm môn học thứ 11 vào một chương trình đào tạo $\rightarrow$ Trigger `trg_check_max_subjects` sẽ chặn.

---

### Bước 4: Chạy các câu truy vấn nghiệp vụ mẫu

Mở file [sql/06_queries_reports.sql](file:///d:/MASTER/CSDL/sql/06_queries_reports.sql) để kiểm tra các hàm nghiệp vụ:

```sql
-- Xem bảng điểm của học viên STU_001
SELECT * FROM fn_get_student_academic_transcript('STU_001');

-- Tính thù lao giảng viên tháng 09/2026 với đơn giá 200,000 VND/giờ
SELECT * FROM fn_calculate_instructor_salary(9, 2026, 200000);

-- Tính lương nhân viên kèm thưởng phụ trách số lượng học viên
SELECT * FROM fn_calculate_staff_salary(50000);

-- Thống kê sĩ số và doanh thu các lớp học
SELECT * FROM v_class_enrollment_summary;
```

---

## 4. Các lệnh quản trị hữu ích

* **Kiểm tra trạng thái container:**
  ```bash
  docker compose ps
  ```
* **Xem nhật ký log của PostgreSQL:**
  ```bash
  docker compose logs -f postgres
  ```
* **Tạm dừng các container (không mất dữ liệu):**
  ```bash
  docker compose stop
  ```
* **Khởi động lại các container:**
  ```bash
  docker compose start
  ```
* **Xóa toàn bộ container và reset dữ liệu về trạng thái ban đầu:**
  ```bash
  docker compose down -v
  ```
  *(Sau lệnh này, khi chạy `docker compose up -d` trở lại, toàn bộ CSDL sẽ được tạo mới và chạy lại từ `01_schema.sql` đến `05_seed_data.sql`).*
