# LOG KẾT QUẢ THỰC THI SQL — ĐỀ TÀI 3
## Hệ CSDL Quản Lý Trung Tâm Đào Tạo · PostgreSQL 16

> **Ngày xuất:** 27/09/2026 | **Database:** `training_db` | **Lệnh:** `make reset && make demo-save`

---

## 📋 YÊU CẦU 1: CRUD — THÊM / XOÁ / SỬA / TÌM KIẾM

### 1.1. Chương Trình Đào Tạo (`chuong_trinh_dao_tao`)

**[CREATE]** `INSERT 0 1` — Thêm CT04:

| ma_ctdt | ten_ctdt | phu_cap_ql_moi_hv | trang_thai | ma_nv_quan_ly |
|---------|----------|-------------------|------------|---------------|
| CT04 | An Toàn Thông Tin & An Ninh Mạng | 65,000 | DANG_MO | NV02 |

**[UPDATE]** `UPDATE 1` — Sửa tên và phụ cấp CT04:

| ma_ctdt | ten_ctdt | phu_cap_ql_moi_hv |
|---------|----------|-------------------|
| CT04 | An Toàn Thông Tin & Phòng Thủ Không Gian Mạng | **70,000** |

**[DELETE]** `UPDATE 1` — Xóa mềm CT04:

| ma_ctdt | ten_ctdt | is_deleted | updated_at |
|---------|----------|------------|------------|
| CT04 | An Toàn Thông Tin & Phòng Thủ Không Gian Mạng | **true** | 2026-09-27 14:24:49 |

**[SEARCH]** Tìm CTĐT có từ khóa "Dữ liệu" hoặc mã "CT01" — `1 row`:

| ma_ctdt | ten_ctdt | phu_cap_ql_moi_hv | trang_thai | ho_ten_nv_quan_ly | email_nv_quan_ly |
|---------|----------|-------------------|------------|-------------------|------------------|
| CT01 | Khoa Học Dữ Liệu & Phân Tích Chuyên Sâu | 60,000 | DANG_MO | Hoàng Thu Trang | trang.ht@ptit.edu.vn |

---

### 1.2. Môn Học (`mon_hoc`)

**[CREATE]** `INSERT 0 1` — Thêm CT01-M04:

| ma_mon | ten_mon | tong_so_gio | loai_mon | ma_ctdt |
|--------|---------|-------------|----------|---------|
| CT01-M04 | Xử Lý Dữ Liệu Lớn với Apache Spark | 30 | TU_CHON | CT01 |

**[UPDATE]** `UPDATE 1` — Sửa tổng giờ 30 → 36:

| ma_mon | ten_mon | tong_so_gio |
|--------|---------|-------------|
| CT01-M04 | Xử Lý Dữ Liệu Lớn với Apache Spark | **36** |

**[DELETE]** `UPDATE 1` — Xóa mềm CT01-M04:

| ma_mon | ten_mon | is_deleted |
|--------|---------|------------|
| CT01-M04 | Xử Lý Dữ Liệu Lớn với Apache Spark | **true** |

**[SEARCH]** Tìm môn học thuộc CT01 đang hoạt động — `3 rows`:

| ma_mon | ten_mon | tong_so_gio | so_buoi_hoc | loai_mon |
|--------|---------|-------------|-------------|----------|
| CT01-M01 | Cơ sở dữ liệu Nâng cao & SQL For Analytics | 24 | 12 | BAT_BUOC |
| CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | 30 | 15 | BAT_BUOC |
| CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | 20 | 10 | BAT_BUOC |

---

### 1.3. Nhân Viên (`nhan_vien`)

**[CREATE]** `INSERT 0 1` — Thêm NV07:

| ma_nv | ho_ten | gioi_tinh | chuc_vu | so_dien_thoai | luong_co_dinh | trang_thai |
|-------|--------|-----------|---------|---------------|---------------|------------|
| NV07 | Nguyễn Thị Hồng | Nữ | Chuyên viên Hỗ trợ Đào tạo | 0967890123 | 5,000,000 | DANG_LAM |

**[UPDATE]** `UPDATE 1` — Thăng chức và đổi SĐT NV07:

| ma_nv | ho_ten | chuc_vu | so_dien_thoai |
|-------|--------|---------|---------------|
| NV07 | Nguyễn Thị Hồng | **Chuyên viên Chính Quản lý Đào tạo** | **0967890999** |

**[DELETE]** `UPDATE 1` — Ghi nhận thôi việc, xóa mềm NV07:

| ma_nv | ho_ten | trang_thai | is_deleted |
|-------|--------|------------|------------|
| NV07 | Nguyễn Thị Hồng | **DA_NGHI_VIEC** | **true** |

**[SEARCH]** Tìm NV có tên "Bình" hoặc chức vụ "Trưởng phòng" — `2 rows`:

| ma_nv | ho_ten | gioi_tinh | email | chuc_vu | nguoi_quan_ly | luong_co_dinh |
|-------|--------|-----------|-------|---------|---------------|---------------|
| NV02 | ThS. Lê Thị Bình | Nữ | binh.lt@ptit.edu.vn | Trưởng phòng Đào tạo | TS. Nguyễn Văn Hùng | 5,000,000 |
| NV03 | ThS. Trần Quốc Bảo | Nam | bao.tq@ptit.edu.vn | Trưởng phòng Khảo thí & ĐBCL | TS. Nguyễn Văn Hùng | 5,000,000 |

---

### 1.4. Giáo Viên (`giao_vien`)

**[CREATE]** `INSERT 0 1` — Thêm GV07:

| ma_gv | ho_ten | hoc_vi | chuyen_mon | luong_tro_giang_gio | loai_hop_dong |
|-------|--------|--------|------------|---------------------|---------------|
| GV07 | ThS. Chu Đức Trọng | Thạc sĩ | An ninh mạng & Hệ thống thông tin | 115,000 | PARTTIME |

**[UPDATE]** `UPDATE 1` — Thăng Thạc sĩ → Tiến sĩ, tăng lương:

| ma_gv | ho_ten | hoc_vi | luong_tro_giang_gio |
|-------|--------|--------|---------------------|
| GV07 | ThS. Chu Đức Trọng | **Tiến sĩ** | **135,000** |

**[DELETE]** `UPDATE 1` — Xóa mềm GV07:

| ma_gv | ho_ten | is_deleted |
|-------|--------|------------|
| GV07 | ThS. Chu Đức Trọng | **true** |

**[SEARCH]** Tìm GV chuyên môn "Dữ liệu" hoặc học vị "Tiến sĩ" — `3 rows`:

| ma_gv | ho_ten | hoc_vi | chuyen_mon | luong_tro_giang_gio | don_gia_giang_vien_gio | loai_hop_dong |
|-------|--------|--------|------------|---------------------|------------------------|---------------|
| GV01 | TS. Nguyễn Văn An | Tiến sĩ | Cơ sở dữ liệu & Data Engineering | 120,000 | 240,000 | FULLTIME |
| GV02 | ThS. Trần Thị Mai | Thạc sĩ | Khoa học Dữ liệu & Python | 100,000 | 200,000 | PARTTIME |
| GV06 | TS. Đỗ Gia Huy | Tiến sĩ | Trí tuệ nhân tạo & Deep Learning | 150,000 | 300,000 | FULLTIME |

---

### 1.5. Học Viên (`hoc_vien`)

**[CREATE]** `INSERT 0 1` — Thêm HV009:

| ma_hv | ho_ten | ngay_sinh | gioi_tinh | so_dien_thoai | email | dia_chi | trang_thai |
|-------|--------|-----------|-----------|---------------|-------|---------|------------|
| HV009 | Lê Quốc Tuấn | 2003-10-10 | Nam | 0989990011 | tuan.lq@gmail.com | Số 99 Thanh Xuân, Hà Nội | DANG_HOC |

**[UPDATE]** `UPDATE 1` — Cập nhật SĐT và địa chỉ HV009:

| ma_hv | ho_ten | so_dien_thoai | dia_chi |
|-------|--------|---------------|---------|
| HV009 | Lê Quốc Tuấn | **0989990022** | **Số 100 Cầu Giấy, Hà Nội** |

**[DELETE]** `UPDATE 1` — Xóa mềm HV009:

| ma_hv | ho_ten | is_deleted |
|-------|--------|------------|
| HV009 | Lê Quốc Tuấn | **true** |

**[SEARCH]** Tìm HV tên "Dũng" hoặc SĐT chứa "0981" — `1 row`:

| ma_hv | ho_ten | ngay_sinh | gioi_tinh | so_dien_thoai | email | dia_chi |
|-------|--------|-----------|-----------|---------------|-------|---------|
| HV001 | Trần Tuấn Dũng | 2002-04-12 | Nam | 0981112233 | dung.tt@gmail.com | Số 10 Hà Đông, Hà Nội |

---

### 1.6. Phòng Học (`phong_hoc`)

**[CREATE]** `INSERT 0 1` — Thêm LAB_401:

| ma_phong | ten_phong | vi_tri | suc_chua | loai_phong | trang_thai | mo_ta |
|----------|-----------|--------|----------|------------|------------|-------|
| LAB_401 | Phòng Lab Chuyên Dụng 401 | Tòa A2 - Tầng 4 | 40 | THUC_HANH_LAB | SAN_SANG | Máy tính chuyên dụng xử lý AI GPU |

**[UPDATE]** `UPDATE 1` — Chuyển LAB_401 vào bảo trì:

| ma_phong | ten_phong | trang_thai |
|----------|-----------|------------|
| LAB_401 | Phòng Lab Chuyên Dụng 401 | **BAO_TRI** |

**[DELETE]** `UPDATE 1` — Xóa mềm LAB_401:

| ma_phong | ten_phong | trang_thai | is_deleted |
|----------|-----------|------------|------------|
| LAB_401 | Phòng Lab Chuyên Dụng 401 | BAO_TRI | **true** |

**[SEARCH]** Tìm phòng SAN_SANG, sức chứa >= 35 — `5 rows`:

| ma_phong | ten_phong | vi_tri | suc_chua | loai_phong | trang_thai |
|----------|-----------|--------|----------|------------|------------|
| HT_A | Hội Trường Lớn Khu A | Tòa A1 - Tầng 1 | 150 | HOI_TRUONG | SAN_SANG |
| P_201 | Phòng Lý Thuyết Đa Năng 201 | Tòa A1 - Tầng 2 | 50 | LY_THUYET | SAN_SANG |
| P_202 | Phòng Lý Thuyết 202 | Tòa A1 - Tầng 2 | 45 | LY_THUYET | SAN_SANG |
| LAB_301 | Phòng Thực Hành Lab 301 | Tòa A2 - Tầng 3 | 40 | THUC_HANH_LAB | SAN_SANG |
| LAB_302 | Phòng Thực Hành Lab 302 | Tòa A2 - Tầng 3 | 35 | THUC_HANH_LAB | SAN_SANG |

---

## 📊 YÊU CẦU 2: KẾT QUẢ HỌC TẬP TỪNG HỌC VIÊN

> **Hàm:** `fn_bang_diem_hoc_vien(p_ma_hv)` | Điểm > 5.0 → **ĐẠT** | <= 5.0 → **CHƯA ĐẠT**

**Cách 1 — Raw SQL (điểm cao nhất mỗi môn) — `25 rows` (trích):**

| ma_hv | ho_ten_hoc_vien | ma_khoa | ma_mon | ten_mon | so_lan_thi | diem_cao_nhat | trang_thai_mon |
|-------|-----------------|---------|--------|---------|------------|---------------|----------------|
| HV001 | Trần Tuấn Dũng | CT01-2026HK1-K01 | CT01-M01 | Cơ sở dữ liệu Nâng cao & SQL For Analytics | 1 | 8.50 | ĐẠT |
| HV001 | Trần Tuấn Dũng | CT01-2026HK1-K01 | CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | 2 | 7.50 | ĐẠT |
| HV001 | Trần Tuấn Dũng | CT01-2026HK1-K01 | CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | — | — | Chưa dự thi |
| HV002 | Nguyễn Phương Thảo | CT01-2026HK1-K01 | CT01-M01 | Cơ sở dữ liệu Nâng cao & SQL For Analytics | 2 | 4.50 | CHƯA ĐẠT |
| HV003 | Trịnh Bảo Ngọc | CT01-2026HK1-K01 | CT01-M01 | Cơ sở dữ liệu Nâng cao & SQL For Analytics | 1 | 9.00 | ĐẠT |
| HV004 | Đặng Quốc Huy | CT02-2026HK1-K01 | CT02-M01 | Lập trình Web Frontend Hiện Đại (Next.js/React) | 1 | 8.00 | ĐẠT |
| HV005 | Vũ Hoàng Nam | CT02-2026HK1-K01 | CT02-M01 | Lập trình Web Frontend Hiện Đại (Next.js/React) | 2 | 7.00 | ĐẠT |
| HV007 | Ngô Quang Khải | CT03-2026HK1-K01 | CT03-M01 | Toán ứng dụng cho Machine Learning | 1 | 8.50 | ĐẠT |

**Cách 2 — `fn_bang_diem_hoc_vien('HV001')` (chi tiết từng lần thi) — `4 rows`:**

| ma_hv | ho_ten_hv | ma_mon | ten_mon | lan_thi | diem_thi | ngay_thi | ket_qua |
|-------|-----------|--------|---------|---------|----------|----------|---------|
| HV001 | Trần Tuấn Dũng | CT01-M01 | Cơ sở dữ liệu Nâng cao & SQL For Analytics | 1 | 8.50 | 2026-09-25 | DAT |
| HV001 | Trần Tuấn Dũng | CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | 1 | 4.00 | 2026-09-26 | CHUA_DAT |
| HV001 | Trần Tuấn Dũng | CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | 2 | 7.50 | 2026-10-05 | DAT |
| HV001 | Trần Tuấn Dũng | CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | — | — | — | — |

---

## ❌ YÊU CẦU 3: HỌC VIÊN CHƯA HOÀN THÀNH KHÓA

> **Hàm:** `fn_hoc_vien_chua_hoan_thanh_khoa('CT01-2026HK1-K01')` — `8 rows`

| ma_hv | ho_ten_hv | ma_mon | ten_mon | trang_thai_hoan_thanh | diem_cao_nhat | so_lan_thi_rot | chi_tiet_lan_rot |
|-------|-----------|--------|---------|----------------------|---------------|----------------|------------------|
| HV001 | Trần Tuấn Dũng | CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |
| HV002 | Nguyễn Phương Thảo | CT01-M01 | Cơ sở dữ liệu Nâng cao & SQL For Analytics | Chưa đạt (Đã thi nhưng rớt) | 4.50 | 2 | Lần 1: 3.50đ (25/09/2026); Lần 2: 4.50đ (05/10/2026) |
| HV002 | Nguyễn Phương Thảo | CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |
| HV002 | Nguyễn Phương Thảo | CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |
| HV003 | Trịnh Bảo Ngọc | CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |
| HV003 | Trịnh Bảo Ngọc | CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |
| HV004 | Đặng Quốc Huy | CT01-M02 | Lập trình Python cho Khoa học Dữ liệu | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |
| HV004 | Đặng Quốc Huy | CT01-M03 | Trực quan hóa Dữ liệu với PowerBI | Chưa hoàn thành (Chưa dự thi) | -1 | 0 | Chưa có lượt thi nào |

---

## 💰 YÊU CẦU 4: BẢNG LƯƠNG GIÁO VIÊN — THÁNG 9/2026

> **Hàm:** `fn_tinh_luong_giao_vien(9, 2026)` | Giảng viên chính = Giờ × (2 × Đơn giá) | Trợ giảng = Giờ × Đơn giá

| ma_gv | ho_ten_gv | hoc_vi | loai_hop_dong | don_gia_ta | gio_day_chinh | gio_tro_giang | tong_gio | tien_day_chinh | tien_tro_giang | tong_luong |
|-------|-----------|--------|---------------|------------|---------------|---------------|----------|----------------|----------------|------------|
| GV01 | TS. Nguyễn Văn An | Tiến sĩ | FULLTIME | 120,000 | 12 | 0 | 12 | 2,880,000 | 0 | **2,880,000** |
| GV04 | KS. Phạm Hải Đăng | Kỹ sư | PARTTIME | 90,000 | 0 | 20 | 20 | 0 | 1,800,000 | **1,800,000** |
| GV03 | ThS. Lê Hoàng Long | Thạc sĩ | FULLTIME | 110,000 | 8 | 0 | 8 | 1,760,000 | 0 | **1,760,000** |
| GV02 | ThS. Trần Thị Mai | Thạc sĩ | PARTTIME | 100,000 | 8 | 0 | 8 | 1,600,000 | 0 | **1,600,000** |
| GV06 | TS. Đỗ Gia Huy | Tiến sĩ | FULLTIME | 150,000 | 4 | 0 | 4 | 1,200,000 | 0 | **1,200,000** |
| GV05 | KS. Vũ Thu Hà | Kỹ sư | PARTTIME | 85,000 | 0 | 8 | 8 | 0 | 680,000 | **680,000** |

---

## 💼 YÊU CẦU 5: BẢNG LƯƠNG NHÂN VIÊN

> **Hàm:** `fn_tinh_luong_nhan_vien()` | Lương = Lương cứng + (5% × cấp dưới × lương) + (50,000 × tổng HV)

| ma_nv | ho_ten_nv | chuc_vu | luong_co_dinh | so_cap_duoi | phu_cap_ql_nv | so_ctdt | tong_hv | luong_ql_ctdt | tong_thu_nhap |
|-------|-----------|---------|---------------|-------------|---------------|---------|---------|---------------|---------------|
| NV01 | TS. Nguyễn Văn Hùng | Giám đốc Trung tâm | 5,000,000 | 2 | 500,000 | 0 | 0 | 0 | **5,500,000** |
| NV02 | ThS. Lê Thị Bình | Trưởng phòng Đào tạo | 5,000,000 | 2 | 500,000 | 0 | 0 | 0 | **5,500,000** |
| NV03 | ThS. Trần Quốc Bảo | Trưởng phòng Khảo thí & ĐBCL | 5,000,000 | 1 | 250,000 | 0 | 0 | 0 | **5,250,000** |
| NV04 | Hoàng Thu Trang | Chuyên viên Quản lý CTĐT Data | 5,000,000 | 0 | 0 | 1 | 4 | 200,000 | **5,200,000** |
| NV05 | Phạm Minh Đức | Chuyên viên Quản lý CTĐT Web | 5,000,000 | 0 | 0 | 1 | 3 | 150,000 | **5,150,000** |
| NV06 | Vũ Thị Mai | Chuyên viên Quản lý CTĐT AI | 5,000,000 | 0 | 0 | 1 | 2 | 100,000 | **5,100,000** |

---

## 🔒 YÊU CẦU 6: KIỂM TRA RÀNG BUỘC SỐ LƯỢNG

### 6.1. Số môn trong CTĐT `CT01` (tối đa 10 môn)

| ma_ctdt | so_mon_hien_tai | ket_qua_kiem_tra |
|---------|-----------------|------------------|
| CT01 | 3 | ✅ HỢP LỆ: Còn có thể thêm 7 môn học |

### 6.2. Xung đột phòng — LAB_301, ngày 02/09/2026, khung 18:30–20:30

> ⚠️ **PHÁT HIỆN XUNG ĐỘT:** Phòng LAB_301 đã có lịch trong khung giờ này!

| ma_buoi | ma_lop_mon | ma_phong | ngay_hoc | gio_bat_dau | gio_ket_thuc |
|---------|------------|----------|----------|-------------|--------------|
| 1 | LM_CT01_K01_M01 | LAB_301 | 2026-09-02 | 18:30:00 | 20:30:00 |

### 6.3. Xung đột lịch giáo viên — GV01, ngày 02/09/2026, khung 18:30–20:30

> ⚠️ **PHÁT HIỆN XUNG ĐỘT:** GV01 đã có lịch giảng trong khung giờ này!

| ma_buoi | ma_lop_mon | ngay_hoc | gio_bat_dau | gio_ket_thuc | ma_gv | vai_tro |
|---------|------------|----------|-------------|--------------|-------|---------|
| 1 | LM_CT01_K01_M01 | 2026-09-02 | 18:30:00 | 20:30:00 | GV01 | GIANG_VIEN |

---

## 🔄 Cách tái tạo log

```bash
make reset && make demo-save   # Reset DB sạch + xuất log đầy đủ
make demo-save                  # Chỉ xuất log (không reset DB)
make demo                       # Xem trực tiếp trên terminal
```

> **File log thô:** [`query_output.txt`](query_output.txt) | **File SQL:** [`sql/queries/07_assignment_queries.sql`](sql/queries/07_assignment_queries.sql)
