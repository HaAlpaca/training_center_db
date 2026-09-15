# HỆ CƠ SỞ DỮ LIỆU QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3)

Dự án Cơ sở dữ liệu quan hệ xây dựng trên hệ quản trị **PostgreSQL 16**, bao gồm kiến trúc phân rã module DDL cho **13 bảng tiếng Việt**, hệ thống **5 Triggers PL/pgSQL** kiểm soát ràng buộc toàn vẹn, **5 Stored Procedures Transactions** quản lý giao dịch nguyên tử, Functions nghiệp vụ, Views báo cáo, kịch bản kiểm thử tự động và môi trường container hóa với Docker Compose.

---

## 1. Cấu trúc thư mục dự án

```text
CSDL/
├── .env.example                  # File cấu hình biến môi trường mẫu
├── .gitignore                    # Bỏ qua các file sinh tự động, node_modules, build
├── Makefile                      # Tự động hóa toàn bộ thao tác dự án (make up, make reset...)
├── docker-compose.yml            # Khởi chạy PostgreSQL + pgAdmin bằng 1 lệnh
├── full_schema_and_data.sql      # Script tổng hợp toàn bộ CSDL (13 bảng + 5 Triggers + Functions + Views + Seed Data + 5 Procedures)
├── Readme.md                     # Tài liệu hướng dẫn sử dụng và kiến trúc
│
├── sql/                          # Các script SQL tự động thực thi theo thứ tự khi khởi tạo
│   ├── 01_schema.sql             # DDL: Định nghĩa 13 bảng tiếng Việt, khóa chính, khóa ngoại, CHECK constraints
│   ├── 02_triggers.sql           # Triggers PL/pgSQL: 5 Triggers kiểm soát ràng buộc toàn vẹn nâng cao
│   ├── 03_functions.sql          # Stored Functions: Bảng điểm, tính lương GV & NV, SV chưa đạt
│   ├── 04_views.sql              # Views: Thống kê sĩ số khóa, doanh thu học phí, tỷ lệ đỗ môn, phân cấp nhân sự
│   ├── 05_seed_data.sql          # Dữ liệu mẫu mở rộng (Học viên, Giảng viên, Lịch học, Điểm thi đa dạng kịch bản)
│   ├── 06_queries_reports.sql    # Kịch bản truy vấn mẫu, demo nghiệp vụ và phân tích
│   ├── 07_assignment_queries.sql # Tập hợp đầy đủ các câu truy vấn đáp ứng 6 Yêu cầu lớn của đề tài
│   └── 08_procedures.sql         # Stored Procedures: 5 Quy trình giao dịch (Transactions) chuẩn ACID
│
├── web/                          # Giao diện Web Quản trị (Next.js 16 + Tailwind CSS)
│   ├── src/lib/db.ts             # Connection pool kết nối trực tiếp PostgreSQL
│   └── ...
│
├── docs/                         # Tài liệu thiết kế hệ thống
│   ├── erd.md                    # Sơ đồ quan hệ thực thể (ERD 13 bảng) dạng Mermaid
│   └── data_dictionary.md        # Từ điển dữ liệu chi tiết (13 bảng, kiểu dữ liệu, ràng buộc)
│
└── tests/                        # Kịch bản kiểm thử
    └── test_triggers.sql         # Test cases kiểm thử tự động cho cả 5 Triggers và 5 Transactions
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

## 3. Danh mục 5 Triggers PL/pgSQL Kiểm soát Toàn vẹn

1. **`trg_kiem_tra_so_mon_ctdt`** (bảng `mon_hoc`): Chặn khi 1 CTĐT vượt quá 10 môn học.
2. **`trg_kiem_tra_trung_phong`** (bảng `buoi_hoc`): Chặn xếp trùng phòng học trong cùng ngày & khung giờ 2 tiếng.
3. **`trg_kiem_tra_trung_lich_gv`** (bảng `buoi_hoc`): Chặn xếp trùng lịch của giảng viên (cả dạy chính & trợ giảng).
4. **`trg_kiem_tra_phan_cong`** (bảng `phan_cong_giang_day`): Mỗi lớp có tối đa 1 GV chính; 1 người không vừa dạy chính vừa trợ giảng.
5. **`trg_kiem_tra_hoc_vien_du_thi`** (bảng `ket_qua_thi`): Chặn nhập điểm cho học viên chưa đăng ký khóa đào tạo tương ứng.

---

## 4. Danh mục 5 Stored Procedures Giao dịch (Transactions - ACID)

1. **`sp_mo_khoa_dao_tao_moi`**: Tạo khóa đào tạo và tự động sinh toàn bộ các lớp môn học theo chương trình trong 1 transaction.
2. **`sp_dang_ky_khoa_hoc_va_dong_phi`**: Ghi nhận học viên đăng ký khóa, đóng học phí và cập nhật trạng thái học tập.
3. **`sp_phan_cong_va_len_lich_buoi_hoc`**: Phân công giảng viên chính + trợ giảng và tự động sinh lịch $N$ buổi học định kỳ.
4. **`sp_ghi_nhan_ket_qua_thi`**: Nhập điểm thi, tự động tính số lần thi và tự động xét tốt nghiệp khóa nếu đạt tất cả các môn.
5. **`sp_chuyen_khoa_hoc_vien`**: Chuyển học viên sang khóa mới, hủy đăng ký khóa cũ và kết chuyển bảo lưu 100% học phí.

---

## 5. Quản trị dự án nhanh bằng Makefile

| Lệnh `make` | Ý nghĩa chức năng | Lệnh gốc tương đương |
| :--- | :--- | :--- |
| **`make help`** | Hiển thị bảng danh sách hướng dẫn các lệnh | — |
| **`make up`** | Khởi chạy PostgreSQL & pgAdmin ngầm | `docker compose up -d` |
| **`make down`** | Dừng toàn bộ các container | `docker compose down` |
| **`make restart`** | Khởi động lại các container | `docker compose restart` |
| **`make reset`** | Xóa sạch và nạp mới toàn bộ CSDL từ đầu | `docker compose down -v && docker compose up -d` |
| **`make logs`** | Xem nhật ký log của PostgreSQL theo thời gian thực | `docker compose logs -f postgres` |
| **`make psql`** | Mở trực tiếp terminal `psql` vào database `training_db` | `docker exec -it csdl_postgres psql -U admin -d training_db` |
| **`make test-triggers`** | Chạy kịch bản kiểm thử Triggers & Transactions tự động | `docker exec -i csdl_postgres psql -U admin -d training_db < tests/test_triggers.sql` |
| **`make install`** | Cài đặt dependencies cho web frontend | `npm --prefix web install` |
| **`make dev`** | Khởi chạy giao diện Next.js (http://localhost:3000) | `npm --prefix web run dev` |
| **`make build`** | Đóng gói ứng dụng Next.js cho production | `npm --prefix web run build` |
