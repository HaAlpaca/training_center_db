# HỆ CƠ SỞ DỮ LIỆU QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3)

Dự án Cơ sở dữ liệu quan hệ xây dựng trên hệ quản trị **PostgreSQL 16**, bao gồm kiến trúc phân rã module DDL, ràng buộc toàn vẹn nâng cao bằng Triggers PL/pgSQL, Functions nghiệp vụ, Views báo cáo, kịch bản kiểm thử tự động và môi trường container hóa với Docker Compose.

---

## 1. Cấu trúc thư mục dự án

```text
CSDL/
├── .env.example                  # File cấu hình biến môi trường mẫu
├── .gitignore                    # Bỏ qua các file sinh tự động, node_modules, build
├── Makefile                      # Tự động hóa toàn bộ thao tác dự án (make up, make reset...)
├── docker-compose.yml            # Khởi chạy PostgreSQL + pgAdmin bằng 1 lệnh
├── full_schema_and_data.sql      # Script tổng hợp toàn bộ CSDL (Schema + Triggers + Functions + Views + Seed Data)
├── readme.md                     # Tài liệu hướng dẫn sử dụng và kiến trúc
│
├── sql/                          # Các script SQL tự động thực thi theo thứ tự khi khởi tạo
│   ├── 01_schema.sql             # DDL: Định nghĩa 11 bảng, khóa chính, khóa ngoại, CHECK constraints
│   ├── 02_triggers.sql           # Triggers PL/pgSQL: Chống trùng phòng, trùng lịch GV, giới hạn môn
│   ├── 03_functions.sql          # Stored Functions: Bảng điểm, tính lương GV & NV, SV chưa đạt
│   ├── 04_views.sql              # Views: Thống kê sĩ số, doanh thu học phí, tỷ lệ đỗ môn
│   ├── 05_seed_data.sql          # Dữ liệu mẫu mở rộng (Học viên, Giảng viên, Lịch học, Điểm thi đa dạng kịch bản)
│   ├── 06_queries_reports.sql    # Kịch bản truy vấn mẫu, demo nghiệp vụ và phân tích
│   └── 07_assignment_queries.sql # Tập hợp đầy đủ các câu truy vấn đáp ứng 6 Yêu cầu lớn của đề tài
│
├── web/                          # Giao diện Web Quản trị (Next.js 16 + Tailwind CSS)
│   ├── src/lib/db.ts             # Connection pool kết nối trực tiếp PostgreSQL
│   └── ...
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
* **Port:** `5433` (cổng máy chủ host) / `5432` (nội bộ container)
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
> `01_schema.sql` $\rightarrow$ `02_triggers.sql` $\rightarrow$ `03_functions.sql` $\rightarrow$ `04_views.sql` $\rightarrow$ `05_seed_data.sql` $\rightarrow$ `06_queries_reports.sql` $\rightarrow$ `07_assignment_queries.sql`.

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

## 4. Chi tiết cập nhật phần SQL & Truy vấn theo yêu cầu đề bài

Các cập nhật mới nhất trong phần SQL bao gồm việc mở rộng bộ dữ liệu mẫu thực tế và bổ sung toàn bộ các câu truy vấn đáp ứng trọn vẹn 6 Yêu cầu lớn của môn học trong file [sql/07_assignment_queries.sql](file:///d:/MASTER/CSDL/sql/07_assignment_queries.sql):

### 4.1. Mở rộng dữ liệu mẫu (`sql/05_seed_data.sql`)
* **Cơ cấu nhân sự đa cấp:** 6 nhân viên (`staff`) phân bổ theo sơ đồ hình cây (Giám đốc $\rightarrow$ Trưởng chương trình $\rightarrow$ Điều phối viên, Chuyên viên).
* **Chương trình & Môn học phong phú:** 3 CTĐT (`PRG_DATA`, `PRG_WEB`, `PRG_CLOUD`) với đầy đủ môn học bắt buộc/tự chọn, số giờ chẵn chuẩn hóa (mỗi buổi 2h).
* **Lớp học & Học viên:** 3 lớp học với các trạng thái khác nhau (`PLANNING`, `OPEN`, `CLOSED` - lớp đã hoàn thành để test tốt nghiệp); 12 học viên đăng ký nhiều chương trình.
* **Lịch học thực tế Tháng 9/2026:** Các buổi học được phân bổ chuẩn xác, không bị xung đột phòng hay trùng lịch giảng viên/trợ giảng, phục vụ tính thù lao thực tế.
* **Kịch bản điểm thi đa dạng:** Bao gồm học viên thi 1 lần đỗ ngay, thi rớt lần 1 và đỗ lần 2, thi rớt cả 2 lần (nợ môn), học viên chưa tham gia thi, điểm chạm ngưỡng 5.0 (không đạt), và lớp đã thi đỗ 100% tất cả các môn.
* **An toàn khi nạp dữ liệu:** Áp dụng `ON CONFLICT (...) DO UPDATE` giúp nạp lại dữ liệu nhiều lần mà không bị lỗi trùng khóa.

---

### 4.2. Tập hợp các câu truy vấn đáp ứng 6 yêu cầu đề tài (`sql/07_assignment_queries.sql`)

| Yêu cầu | Nội dung nghiệp vụ | Kỹ thuật & Cú pháp SQL áp dụng |
| :--- | :--- | :--- |
| **Yêu cầu 1** | **Thực hiện CRUD & Tìm kiếm trên các đối tượng** | Viết đầy đủ `INSERT`, `UPDATE`, `DELETE` (Soft Delete qua `is_deleted = TRUE`) và `SELECT / SEARCH` (tìm kiếm bằng `ILIKE`) kèm kiểm soát ràng buộc toàn vẹn cho 10 đối tượng: Program, Subject, Staff, Instructor, Room, Class, Class Session, Student, Enrollment, Exam Result. |
| **Yêu cầu 2** | **Hiển thị kết quả học tập của mỗi học viên** | - Truy vấn điểm thi các môn trong khóa học, xác định lần thi mới nhất bằng Window Function `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY attempt_number DESC)`.<br>- Phân loại kết quả môn học (`PASSED`, `FAILED`, `NOT_TAKEN`) và tính GPA trung bình bằng `AVG() OVER()`.<br>- Gọi Stored Function: `SELECT * FROM fn_get_student_academic_transcript('STU_001');`. |
| **Yêu cầu 3** | **Liệt kê học viên chưa hoàn thành môn học & điểm thi rớt** | - Dùng CTE xác định các môn bắt buộc của khóa, loại trừ các môn đã thi đạt (`score > 5.0`).<br>- Tổng hợp lịch sử tất cả các lần thi bị rớt (`score <= 5.0`) thành chuỗi chi tiết bằng hàm `STRING_AGG()`.<br>- Phân loại rõ trạng thái: "Chưa hoàn thành (Chưa dự thi)" hoặc "Chưa đạt (Thi rớt)". |
| **Yêu cầu 4** | **Tính lương cho giảng viên trong tháng** | - Gọi Stored Function: `SELECT * FROM fn_calculate_instructor_salary(9, 2026, 200000);`.<br>- Công thức: $Lương = (Giờ\_dạy\_chính \times Đơn\_giá) + (Giờ\_trợ\_giảng \times \frac{Đơn\_giá}{2})$. Tự động tính dựa trên các buổi học đã hoàn thành (`COMPLETED`). |
| **Yêu cầu 5** | **Tính lương cho các nhân viên** | - Gọi Stored Function: `SELECT * FROM fn_calculate_staff_salary(50000);`.<br>- Công thức: $Lương = Lương\_cứng (5.000.000) + Phụ\_cấp\_quản\_lý\_CTĐT (dựa\_trên\_số\_học\_viên \times đơn\_giá) + Thưởng\_cấp\_dưới (5\% \times Lương\_cứng \times Số\_cấp\_dưới)$. |
| **Yêu cầu 6** | **Kiểm tra ràng buộc số lượng trước giao dịch (Validation)** | Các câu truy vấn kiểm tra dữ liệu trước khi thực hiện giao dịch (Insert/Update):<br>1. Giới hạn số môn học trong 1 CTĐT (tối đa 10 môn).<br>2. Kiểm tra sĩ số lớp học trước khi cho đăng ký (không vượt `max_capacity`).<br>3. Kiểm tra xung đột trùng phòng học trong cùng khung giờ.<br>4. Kiểm tra xung đột trùng lịch giảng viên / trợ giảng trong cùng khung giờ. |

---

### 4.3. File script trọn gói (`full_schema_and_data.sql`)
* Tổng hợp toàn bộ DDL tạo bảng, Constraints, Triggers, Functions, Views và dữ liệu mẫu mở rộng thành một file duy nhất.
* Thích hợp để import nhanh trên môi trường độc lập không sử dụng Docker hoặc chạy kiểm thử trực tiếp trên pgAdmin / DBeaver bằng 1 lần Run Script.

---

## 5. Quản trị dự án nhanh bằng Makefile (Khuyên dùng)

Dự án cung cấp sẵn file `Makefile` giúp bạn thực hiện toàn bộ các tác vụ từ Docker, Database đến Frontend chỉ bằng 1 lệnh ngắn:

| Lệnh `make` | Ý nghĩa chức năng | Lệnh gốc tương đương |
| :--- | :--- | :--- |
| **`make help`** | Hiển thị bảng danh sách hướng dẫn các lệnh | — |
| **`make up`** | Khởi chạy PostgreSQL & pgAdmin ngầm | `docker compose up -d` |
| **`make down`** | Dừng toàn bộ các container | `docker compose down` |
| **`make restart`** | Khởi động lại các container | `docker compose restart` |
| **`make reset`** | Xóa sạch và nạp mới toàn bộ CSDL từ đầu | `docker compose down -v && docker compose up -d` |
| **`make logs`** | Xem nhật ký log của PostgreSQL theo thời gian thực | `docker compose logs -f postgres` |
| **`make psql`** | Mở trực tiếp terminal `psql` vào database `training_db` | `docker exec -it csdl_postgres psql -U admin -d training_db` |
| **`make test-triggers`** | Chạy kịch bản kiểm thử Triggers tự động | `docker exec -i csdl_postgres psql -U admin -d training_db < tests/test_triggers.sql` |
| **`make install`** | Cài đặt dependencies cho web frontend | `npm --prefix web install` |
| **`make dev`** | Khởi chạy giao diện Next.js (http://localhost:3000) | `npm --prefix web run dev` |
| **`make build`** | Đóng gói ứng dụng Next.js cho production | `npm --prefix web run build` |

*(Nếu môi trường không hỗ trợ `make`, bạn vẫn có thể sử dụng trực tiếp các lệnh gốc ở cột thứ 3).*
