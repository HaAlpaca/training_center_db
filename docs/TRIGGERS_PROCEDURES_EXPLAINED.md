# 📘 Giải thích Triggers, Stored Procedures & Functions
### Hệ CSDL Quản lý Trung tâm Đào tạo — PostgreSQL

> Tài liệu này giải thích **cách hoạt động chi tiết** của từng Trigger, Stored Procedure (Transaction) và Function trong hệ thống. Mỗi thành phần được phân tích theo luồng thực thi thực tế.

---

## 📋 Mục lục

1. [Kiến trúc tổng quan](#1-kiến-trúc-tổng-quan)
2. [TRIGGERS — Bảo vệ ràng buộc toàn vẹn](#2-triggers--bảo-vệ-ràng-buộc-toàn-vẹn)
3. [STORED PROCEDURES — Giao dịch nghiệp vụ](#3-stored-procedures--giao-dịch-nghiệp-vụ)
4. [FUNCTIONS — Tính toán & Báo cáo](#4-functions--tính-toán--báo-cáo)
5. [Sơ đồ tương tác giữa các thành phần](#5-sơ-đồ-tương-tác-giữa-các-thành-phần)

---

## 1. Kiến trúc tổng quan

Hệ thống được thiết kế theo nguyên tắc **bảo vệ nhiều tầng**:

```
Ứng dụng / Người dùng
        │
        ▼
┌─────────────────────────┐
│  Stored Procedures      │  ← Tầng nghiệp vụ: đóng gói logic phức tạp
│  (Transaction đảm bảo   │     vào 1 lời gọi nguyên tử (all-or-nothing)
│   tính nguyên tử)       │
└──────────┬──────────────┘
           │  kích hoạt khi INSERT/UPDATE
           ▼
┌─────────────────────────┐
│  Triggers               │  ← Tầng bảo vệ: tự động kiểm tra ràng buộc
│  (Chạy tự động, không   │     ngay tại DB, không phụ thuộc ứng dụng
│   thể bỏ qua)           │
└──────────┬──────────────┘
           │  thao tác trên
           ▼
┌─────────────────────────┐
│  Các Bảng dữ liệu       │  ← 13 bảng: mon_hoc, buoi_hoc,
│                         │     phan_cong_giang_day, ket_qua_thi...
└─────────────────────────┘
```

> **Quy tắc cốt lõi:** Triggers không thể bị bypass — dù ai thao tác vào DB (qua app, pgAdmin, hay SQL thuần) thì ràng buộc vẫn được đảm bảo.

---

## 2. TRIGGERS — Bảo vệ ràng buộc toàn vẹn

> **File:** [`sql/02_triggers.sql`](../sql/02_triggers.sql)

Mỗi trigger gồm 2 phần: **Function** (logic kiểm tra) + **Trigger** (khai báo khi nào kích hoạt).

---

### 🔒 TRIGGER 1 — Giới hạn số môn học của Chương trình Đào tạo

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên trigger** | `trg_kiem_tra_so_mon_ctdt` |
| **Bảng** | `mon_hoc` |
| **Kích hoạt** | `AFTER INSERT OR UPDATE` |
| **Ràng buộc** | Mỗi CTĐT tối đa **10 môn học** |

**Bài toán thực tế:**
Một Chương trình Đào tạo (ví dụ: *Lập trình Python*) có thể bị thêm vô tội vạ hàng chục môn học. Trigger này giữ cho chương trình có cấu trúc gọn và có thể kiểm soát được.

**Cách hoạt động từng bước:**

```
Ai đó INSERT/UPDATE một bản ghi vào bảng mon_hoc
        │
        ▼ (AFTER — sau khi hàng đã được ghi tạm)
fn_kiem_tra_so_mon_ctdt() được gọi
        │
        ▼
SELECT COUNT(*) từ mon_hoc
WHERE ma_ctdt = NEW.ma_ctdt      ← đếm số môn hiện tại của cùng CTĐT
  AND is_deleted = FALSE
        │
        ├── Nếu COUNT > 10:
        │       RAISE EXCEPTION  ← hủy toàn bộ thao tác, rollback
        │
        └── Nếu COUNT ≤ 10:
                RETURN NEW       ← cho phép, ghi vào DB
```

> **Lưu ý kỹ thuật:** Trigger chạy `AFTER INSERT` nên đếm đã bao gồm bản ghi mới. Do đó ngưỡng kiểm tra là `> 10` (không phải `>= 10`).

---

### 🔒 TRIGGER 2 — Chống xung đột phòng học

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên trigger** | `trg_kiem_tra_trung_phong` |
| **Bảng** | `buoi_hoc` |
| **Kích hoạt** | `BEFORE INSERT OR UPDATE` |
| **Ràng buộc** | Cùng phòng, cùng ngày → khung giờ không được chồng lên nhau |

**Bài toán thực tế:**
Không thể để 2 lớp khác nhau cùng dùng *Phòng A101* vào lúc *8:00–10:00* ngày *01/10/2026*.

**Cách hoạt động từng bước:**

```
Ai đó INSERT/UPDATE một buổi học mới (NEW)
        │
        ▼ (BEFORE — kiểm tra trước khi ghi)
fn_kiem_tra_trung_phong() được gọi
        │
        ▼
Tìm trong buoi_hoc bất kỳ hàng nào thỏa:
  - ma_phong = NEW.ma_phong         ← cùng phòng
  - ngay_hoc = NEW.ngay_hoc         ← cùng ngày
  - ma_buoi <> NEW.ma_buoi          ← khác buổi (tránh self-check khi UPDATE)
  - trang_thai <> 'HUY_BUOI'        ← bỏ qua buổi đã hủy
  - NEW.gio_bat_dau < gio_ket_thuc  ← kiểm tra chồng giờ (overlap)
  - NEW.gio_ket_thuc > gio_bat_dau  ← (điều kiện 2 chiều của interval overlap)
        │
        ├── Tìm thấy → RAISE EXCEPTION (hủy, rollback)
        └── Không tìm thấy → RETURN NEW (cho phép)
```

**Công thức kiểm tra chồng giờ:**
```
[A_start, A_end) chồng [B_start, B_end)
⟺ A_start < B_end AND A_end > B_start
```

---

### 🔒 TRIGGER 3 — Chống xung đột lịch Giáo viên

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên trigger** | `trg_kiem_tra_trung_lich_gv` |
| **Bảng** | `buoi_hoc` |
| **Kích hoạt** | `BEFORE INSERT OR UPDATE` |
| **Ràng buộc** | Giáo viên (cả Giảng viên lẫn Trợ giảng) không được dạy 2 lớp trùng giờ |

**Bài toán thực tế:**
Giảng viên *Nguyễn Văn A* đã được phân công lớp *Python cơ bản* từ 8:00–10:00. Không thể xếp lịch thêm cho ông ấy ở lớp *Web Frontend* cùng khung giờ đó.

**Cách hoạt động từng bước:**

```
Ai đó INSERT/UPDATE một buổi học mới (NEW)
        │
        ▼ (BEFORE)
fn_kiem_tra_trung_lich_giao_vien() được gọi
        │
        ▼
FOR LOOP: duyệt qua TẤT CẢ giáo viên trong phan_cong_giang_day
          WHERE ma_lop_mon = NEW.ma_lop_mon  ← lấy GV của lớp này
        │
        │  Với mỗi giáo viên v_gv:
        ▼
  Tìm trong buoi_hoc × phan_cong_giang_day:
    - pc.ma_gv = v_gv.ma_gv                  ← cùng giáo viên
    - bh.ngay_hoc = NEW.ngay_hoc             ← cùng ngày
    - bh.ma_buoi <> NEW.ma_buoi              ← buổi khác
    - trang_thai <> 'HUY_BUOI'               ← chưa hủy
    - Interval overlap (như Trigger 2)        ← trùng giờ
        │
        ├── Tìm thấy → RAISE EXCEPTION (báo tên GV + giờ xung đột)
        └── Không tìm thấy → tiếp tục vòng lặp
        │
        ▼ (qua hết vòng lặp)
RETURN NEW  ← tất cả GV đều không xung đột
```

> **Điểm mạnh:** Kiểm tra đồng thời cả **Giảng viên** và **Trợ giảng** trong một trigger duy nhất. Đây là vòng lặp `FOR`, nên nếu lớp có 2 người (1 GV + 1 TA) thì cả 2 đều được kiểm tra.

---

### 🔒 TRIGGER 4 — Ràng buộc phân công Giáo viên

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên trigger** | `trg_kiem_tra_phan_cong` |
| **Bảng** | `phan_cong_giang_day` |
| **Kích hoạt** | `BEFORE INSERT OR UPDATE` |
| **Ràng buộc** | (a) 1 GV không thể vừa là Giảng viên vừa là Trợ giảng cùng lớp; (b) Mỗi lớp chỉ có đúng **1 Giảng viên chính** |

**Bài toán thực tế:**
Tránh tình huống admin nhầm lẫn gán cùng 1 giáo viên cho cả 2 vai trò, hoặc gán 2 giảng viên chính cho cùng một lớp.

**Cách hoạt động từng bước:**

```
Ai đó INSERT/UPDATE vào phan_cong_giang_day (NEW)
        │
        ▼ (BEFORE)
fn_kiem_tra_phan_cong_giao_vien() được gọi
        │
        ├── KIỂM TRA 1: Cùng GV, cùng lớp, khác vai trò?
        │   SELECT FROM phan_cong_giang_day
        │   WHERE ma_lop_mon = NEW.ma_lop_mon
        │     AND ma_gv = NEW.ma_gv
        │     AND vai_tro <> NEW.vai_tro   ← đã có vai trò khác rồi?
        │         │
        │         └── Có → RAISE EXCEPTION ("GV không thể giữ cả 2 vai trò")
        │
        ├── KIỂM TRA 2: Lớp đã có Giảng viên chính rồi?
        │   (Chỉ áp dụng khi NEW.vai_tro = 'GIANG_VIEN')
        │   SELECT FROM phan_cong_giang_day
        │   WHERE ma_lop_mon = NEW.ma_lop_mon
        │     AND vai_tro = 'GIANG_VIEN'
        │     AND ma_gv <> NEW.ma_gv       ← GV khác đã giữ vai này
        │         │
        │         └── Có → RAISE EXCEPTION ("Lớp đã có Giảng viên chính")
        │
        └── Không vi phạm gì → RETURN NEW
```

---

### 🔒 TRIGGER 5 — Kiểm soát điều kiện dự thi

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên trigger** | `trg_kiem_tra_hoc_vien_du_thi` |
| **Bảng** | `ket_qua_thi` |
| **Kích hoạt** | `BEFORE INSERT OR UPDATE` |
| **Ràng buộc** | Học viên chỉ được thi môn thuộc khóa mình **đã đăng ký hợp lệ** |

**Bài toán thực tế:**
Không thể để học viên chưa đăng ký khóa học (hoặc đã hủy) lại có điểm thi trong khóa đó — sẽ gây sai dữ liệu thống kê và xét tốt nghiệp.

**Cách hoạt động từng bước:**

```
Ai đó INSERT vào ket_qua_thi (NEW: ma_hv, ma_lop_mon, diem_thi...)
        │
        ▼ (BEFORE)
fn_kiem_tra_hoc_vien_du_thi() được gọi
        │
        ▼
BƯỚC 1: Tìm ma_khoa của lớp môn học
  SELECT ma_khoa INTO v_ma_khoa
  FROM lop_mon_hoc WHERE ma_lop_mon = NEW.ma_lop_mon
        │
        ├── NULL → RAISE EXCEPTION ("Lớp môn không tồn tại")
        │
        ▼
BƯỚC 2: Kiểm tra học viên đã đăng ký khóa đó chưa
  SELECT FROM dang_ky_khoa_hoc
  WHERE ma_hv = NEW.ma_hv
    AND ma_khoa = v_ma_khoa
    AND trang_thai <> 'HUY'    ← không tính đăng ký đã hủy
    AND is_deleted = FALSE
        │
        ├── Không tìm thấy → RAISE EXCEPTION ("Học viên chưa đăng ký khóa")
        └── Tìm thấy → RETURN NEW (cho phép ghi điểm)
```

---

## 3. STORED PROCEDURES — Giao dịch nghiệp vụ

> **File:** [`sql/08_procedures.sql`](../sql/08_procedures.sql)

Mỗi Stored Procedure là một **Transaction** — nghĩa là toàn bộ các câu lệnh bên trong thực thi **all-or-nothing**: nếu bất kỳ bước nào thất bại, mọi thay đổi trước đó tự động bị **ROLLBACK**.

---

### ⚙️ TRANSACTION 1 — Mở khóa đào tạo mới

**Procedure:** `sp_mo_khoa_dao_tao_moi`

**Bài toán:** Khi admin muốn mở một khóa học mới, họ không chỉ cần tạo bản ghi `khoa_dao_tao` mà còn phải tạo **tất cả các lớp môn học** tương ứng theo CTĐT. Làm thủ công từng bước rất dễ bỏ sót.

**Luồng thực thi:**

```
CALL sp_mo_khoa_dao_tao_moi('CT01-2026HK2-K01', 'Khóa Python HK2/2026', 'CT01', '2026HK2', ...)
        │
        ▼
[Bước 1] Kiểm tra CTĐT tồn tại?       → RAISE nếu không có
[Bước 2] Kiểm tra Kỳ học tồn tại?     → RAISE nếu không có
        │
        ▼
[Bước 3] INSERT vào khoa_dao_tao
         trang_thai = 'MO_DANG_KY'
        │
        ▼
[Bước 4] FOR LOOP: duyệt qua từng mon_hoc thuộc CTĐT
         (ví dụ CT01 có 5 môn → lặp 5 lần)
              │
              └── Mỗi vòng: INSERT vào lop_mon_hoc
                  ma_lop_mon = 'LM_CT01_2026HK2_K01_CT01_M01'
                  trang_thai = 'SAP_MO'
        │
        ▼
[Kết quả] 1 khóa + N lớp môn học được tạo nguyên tử
          (N = số môn trong CTĐT)
```

**Ví dụ kết quả:**
```
NOTICE: Giao dịch thành công: Đã mở khóa CT01-2026HK2-K01 và tự động tạo 5 lớp môn học.
```

---

### ⚙️ TRANSACTION 2 — Đăng ký khóa học & Ghi nhận học phí

**Procedure:** `sp_dang_ky_khoa_hoc_va_dong_phi`

**Bài toán:** Khi học viên đăng ký và nộp học phí, cần đồng thời (1) tạo đăng ký, (2) cập nhật học phí, (3) cập nhật trạng thái học viên — 3 thao tác này phải xảy ra cùng lúc.

**Luồng thực thi:**

```
CALL sp_dang_ky_khoa_hoc_va_dong_phi('HV001', 'CT01-2026HK2-K01', 5000000)
        │
        ▼
[Bước 1] Học viên HV001 có tồn tại?
         → RAISE nếu không
        │
        ▼
[Bước 2] Khóa đào tạo có đang mở không?
         (trang_thai IN ('MO_DANG_KY', 'DANG_HOC'))
         → RAISE nếu đã đóng/hủy
        │
        ▼
[Bước 3] INSERT vào dang_ky_khoa_hoc
         ON CONFLICT (ma_hv, ma_khoa) DO UPDATE  ← nếu đã đăng ký rồi thì
           hoc_phi_da_dong += EXCLUDED.hoc_phi_da_dong  ← cộng dồn học phí
           trang_thai = 'DANG_HOC'
           is_deleted = FALSE  ← kích hoạt lại nếu đã bị xóa mềm
        │
        ▼
[Bước 4] UPDATE hoc_vien SET trang_thai = 'DANG_HOC'
         (đảm bảo học viên được đánh dấu đang học)
        │
        ▼
[Kết quả] Đăng ký + học phí + trạng thái — nhất quán tuyệt đối
```

> **Điểm đặc biệt:** Dùng `ON CONFLICT ... DO UPDATE` (UPSERT) — hỗ trợ cả trường hợp học viên nộp thêm học phí lần 2.

---

### ⚙️ TRANSACTION 3 — Phân công GV & Tự động xếp lịch học

**Procedure:** `sp_phan_cong_va_len_lich_buoi_hoc`

**Bài toán:** Khi bắt đầu một lớp môn học, admin cần phân công giáo viên VÀ tạo toàn bộ lịch buổi học (ví dụ 10 buổi, mỗi buổi cách 3 ngày). Trigger 3, 4 sẽ được kích hoạt tự động để kiểm tra mỗi buổi.

**Luồng thực thi:**

```
CALL sp_phan_cong_va_len_lich_buoi_hoc(
    'LM_CT01_K01_M01',   -- lớp môn
    'GV001',              -- giảng viên chính
    'GV002',              -- trợ giảng
    'P101',               -- phòng học
    '2026-10-01',         -- ngày bắt đầu
    '08:00',              -- giờ bắt đầu
    3                     -- cách nhau 3 ngày
)
        │
        ▼
[Bước 1] Lấy so_buoi_hoc từ mon_hoc
         (ví dụ môn có 20 giờ → 10 buổi)
         → RAISE nếu lớp môn không hợp lệ
        │
        ▼
[Bước 2] INSERT GV001 vào phan_cong_giang_day vai_tro='GIANG_VIEN'
         ───► Trigger 4 (trg_kiem_tra_phan_cong) kiểm tra tự động
        │
        ▼
[Bước 3] INSERT GV002 vào phan_cong_giang_day vai_tro='TRO_GIANG'
         ───► Trigger 4 kiểm tra tự động
        │
        ▼
[Bước 4] FOR LOOP i = 1 đến so_buoi_hoc:
         │  v_ngay_hoc = 2026-10-01, 2026-10-04, 2026-10-07, ...
         │
         └── INSERT buoi_hoc (thu_tu_buoi=i, ngay=v_ngay_hoc, 08:00-10:00, P101)
              ───► Trigger 2 (trg_kiem_tra_trung_phong) kiểm tra phòng
              ───► Trigger 3 (trg_kiem_tra_trung_lich_gv) kiểm tra GV
              v_ngay_hoc += 3 ngày
        │
        ▼
[Bước 5] UPDATE lop_mon_hoc SET trang_thai = 'DANG_HOC'
        │
        ▼
[Kết quả] Toàn bộ lịch học được sinh ra nguyên tử, có kiểm tra đầy đủ
```

---

### ⚙️ TRANSACTION 4 — Nhập điểm thi & Xét tốt nghiệp tự động

**Procedure:** `sp_ghi_nhan_ket_qua_thi`

**Bài toán:** Khi nhập điểm thi, hệ thống cần (1) tự xác định đây là lần thi thứ mấy, (2) ghi điểm, (3) kiểm tra ngay xem học viên đã qua hết tất cả môn chưa để tự động cập nhật tốt nghiệp.

**Luồng thực thi:**

```
CALL sp_ghi_nhan_ket_qua_thi('HV001', 'LM_CT01_K01_M01', 7.5, '2026-11-15')
        │
        ▼
[Bước 1] Lấy ma_khoa từ lop_mon_hoc (để sau dùng xét tốt nghiệp)
        │
        ▼
[Bước 2] Tự động tính lan_thi_moi:
         SELECT MAX(lan_thi) + 1 FROM ket_qua_thi
         WHERE ma_hv='HV001' AND ma_lop_mon='LM_...'
         → Nếu chưa thi lần nào → lan_thi = 1
         → Đã thi 1 lần rồi → lan_thi = 2 (thi lại)
        │
        ▼
[Bước 3] INSERT vào ket_qua_thi (lan_thi=2, diem_thi=7.5)
         ───► Trigger 5 (trg_kiem_tra_hoc_vien_du_thi) kiểm tra tự động
         Cột ket_qua tự sinh: 7.5 > 5.0 → 'DAT'
        │
        ▼
[Bước 4] Dùng CTE kiểm tra: học viên còn môn nào chưa đạt không?
         ┌─ cac_lop_khoa: tất cả lớp môn của khóa
         ├─ mon_da_dat: các môn HV001 đã có điểm > 5.0
         └─ đếm số môn chưa dat = (tổng) - (đã đạt)
        │
        ├── Còn môn chưa đạt (v_so_mon_chua_dat > 0):
        │       NOTICE: "Còn X môn chưa đạt"
        │
        └── Đạt tất cả (v_so_mon_chua_dat = 0):
                UPDATE dang_ky_khoa_hoc
                SET trang_thai = 'HOAN_THANH'
                NOTICE: "CHÚC MỪNG: Học viên đã tốt nghiệp!"
```

---

### ⚙️ TRANSACTION 5 — Chuyển khóa & Bảo lưu học phí

**Procedure:** `sp_chuyen_khoa_hoc_vien`

**Bài toán:** Học viên muốn chuyển từ khóa cũ sang khóa mới (ví dụ: bảo lưu sang kỳ sau). Cần đảm bảo học phí đã nộp không bị mất và toàn bộ diễn ra nguyên tử.

**Luồng thực thi:**

```
CALL sp_chuyen_khoa_hoc_vien('HV001', 'CT01-2026HK1-K01', 'CT01-2026HK2-K01')
        │
        ▼
[Bước 1] Lấy hoc_phi_da_dong từ khóa cũ
         → RAISE nếu học viên chưa đăng ký khóa cũ
        │
        ▼
[Bước 2] Kiểm tra khóa mới có đang mở không?
         trang_thai IN ('MO_DANG_KY', 'DANG_HOC')
         → RAISE nếu không
        │
        ▼
[Bước 3] UPDATE khóa cũ: trang_thai = 'HUY'
        │
        ▼
[Bước 4] INSERT sang khóa mới với hoc_phi_da_dong = số tiền cũ
         ON CONFLICT DO UPDATE: kết chuyển thêm vào nếu đã có
        │
        ▼
[Kết quả] Khóa cũ: HUY | Khóa mới: DANG_HOC | Học phí: nguyên vẹn
```

---

## 4. FUNCTIONS — Tính toán & Báo cáo

> **File:** [`sql/03_functions.sql`](../sql/03_functions.sql)

Functions khác Procedures ở chỗ: **trả về dữ liệu**, dùng trong `SELECT`, không quản lý transaction.

---

### 📊 FUNCTION 1 — Bảng điểm học viên

**Function:** `fn_bang_diem_hoc_vien(p_ma_hv)`

Trả về bảng điểm đầy đủ: tất cả các môn của tất cả khóa học viên tham gia, kèm điểm thi theo từng lần (dùng `LEFT JOIN` để hiện cả môn chưa thi).

```sql
SELECT * FROM fn_bang_diem_hoc_vien('HV001');
-- Kết quả: ma_hv | ho_ten | ma_khoa | ten_khoa | ma_mon | ten_mon | lan_thi | diem_thi | ket_qua
```

---

### 📊 FUNCTION 2 — Danh sách học viên chưa hoàn thành khóa

**Function:** `fn_hoc_vien_chua_hoan_thanh_khoa(p_ma_khoa)`

Dùng nhiều CTE lồng nhau để xác định: với mỗi học viên trong khóa, môn nào chưa đạt? Đã thi rớt hay chưa thi? Chi tiết lịch sử các lần thi rớt là gì?

```sql
SELECT * FROM fn_hoc_vien_chua_hoan_thanh_khoa('CT01-2026HK1-K01');
-- Kết quả: ma_hv | ten_mon | trang_thai | diem_cao_nhat | so_lan_thi_rot | chi_tiet
```

---

### 📊 FUNCTION 3 — Bảng lương Giáo viên theo tháng

**Function:** `fn_tinh_luong_giao_vien(p_thang, p_nam)`

Tính lương dựa trên số buổi `HOAN_THANH` trong tháng:
- Giảng viên chính: `số giờ × (đơn_giá × 2)`
- Trợ giảng: `số giờ × đơn_giá`

```sql
SELECT * FROM fn_tinh_luong_giao_vien(10, 2026);
-- Kết quả: ma_gv | ho_ten | gio_day_chinh | gio_tro_giang | tong_luong
```

---

### 📊 FUNCTION 4 — Bảng lương Nhân viên

**Function:** `fn_tinh_luong_nhan_vien()`

Công thức lương:
```
Tổng thu nhập = Lương cố định
              + (Số NV cấp dưới × 5% × Lương cố định)
              + (Tổng học viên CTĐT quản lý × 50.000 VNĐ)
```

```sql
SELECT * FROM fn_tinh_luong_nhan_vien();
-- Kết quả: ma_nv | ho_ten | luong_co_dinh | phu_cap_quan_ly | tong_thu_nhap
```

---

## 5. Sơ đồ tương tác giữa các thành phần

```
Admin gọi Stored Procedure
         │
         ├─ sp_mo_khoa_dao_tao_moi
         │       └── INSERT khoa_dao_tao
         │       └── INSERT lop_mon_hoc (×N môn)
         │
         ├─ sp_phan_cong_va_len_lich_buoi_hoc
         │       └── INSERT phan_cong_giang_day
         │               └──► Trigger 4 (kiểm tra phân công GV)
         │       └── INSERT buoi_hoc (×M buổi)
         │               └──► Trigger 2 (kiểm tra phòng trống)
         │               └──► Trigger 3 (kiểm tra GV trống lịch)
         │
         ├─ sp_dang_ky_khoa_hoc_va_dong_phi
         │       └── UPSERT dang_ky_khoa_hoc
         │       └── UPDATE hoc_vien.trang_thai
         │
         └─ sp_ghi_nhan_ket_qua_thi
                 └── INSERT ket_qua_thi
                         └──► Trigger 5 (kiểm tra điều kiện thi)
                 └── Kiểm tra tốt nghiệp
                 └── UPDATE dang_ky_khoa_hoc → 'HOAN_THANH'

INSERT mon_hoc
        └──► Trigger 1 (kiểm tra giới hạn 10 môn/CTĐT)
```

---

## 🗂️ Bảng tham chiếu nhanh

| Loại | Tên | File | Bảng liên quan |
|------|-----|------|----------------|
| Trigger | `trg_kiem_tra_so_mon_ctdt` | `02_triggers.sql` | `mon_hoc` |
| Trigger | `trg_kiem_tra_trung_phong` | `02_triggers.sql` | `buoi_hoc` |
| Trigger | `trg_kiem_tra_trung_lich_gv` | `02_triggers.sql` | `buoi_hoc` |
| Trigger | `trg_kiem_tra_phan_cong` | `02_triggers.sql` | `phan_cong_giang_day` |
| Trigger | `trg_kiem_tra_hoc_vien_du_thi` | `02_triggers.sql` | `ket_qua_thi` |
| Procedure | `sp_mo_khoa_dao_tao_moi` | `08_procedures.sql` | `khoa_dao_tao`, `lop_mon_hoc` |
| Procedure | `sp_dang_ky_khoa_hoc_va_dong_phi` | `08_procedures.sql` | `dang_ky_khoa_hoc`, `hoc_vien` |
| Procedure | `sp_phan_cong_va_len_lich_buoi_hoc` | `08_procedures.sql` | `phan_cong_giang_day`, `buoi_hoc` |
| Procedure | `sp_ghi_nhan_ket_qua_thi` | `08_procedures.sql` | `ket_qua_thi`, `dang_ky_khoa_hoc` |
| Procedure | `sp_chuyen_khoa_hoc_vien` | `08_procedures.sql` | `dang_ky_khoa_hoc` |
| Function | `fn_bang_diem_hoc_vien` | `03_functions.sql` | `ket_qua_thi`, `lop_mon_hoc` |
| Function | `fn_hoc_vien_chua_hoan_thanh_khoa` | `03_functions.sql` | `ket_qua_thi`, `lop_mon_hoc` |
| Function | `fn_tinh_luong_giao_vien` | `03_functions.sql` | `buoi_hoc`, `phan_cong_giang_day` |
| Function | `fn_tinh_luong_nhan_vien` | `03_functions.sql` | `nhan_vien`, `chuong_trinh_dao_tao` |

---

*Tài liệu được tạo từ mã nguồn — [`sql/02_triggers.sql`](../sql/02_triggers.sql), [`sql/08_procedures.sql`](../sql/08_procedures.sql), [`sql/03_functions.sql`](../sql/03_functions.sql)*
