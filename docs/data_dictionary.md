# TỪ ĐIỂN DỮ LIỆU (DATA DICTIONARY)
## HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - 13 BẢNG

---

### Quy chuẩn chung về Audit Fields
Mọi bảng trong hệ thống đều tích hợp 4 trường audit hỗ trợ truy vết:
* `created_at` (TIMESTAMP): Thời điểm tạo bản ghi (Mặc định `CURRENT_TIMESTAMP`).
* `created_by` (VARCHAR(50)): Tác nhân tạo (Mặc định `'SYSTEM'`).
* `updated_at` (TIMESTAMP): Thời điểm cập nhật dữ liệu gần nhất.
* `is_deleted` (BOOLEAN): Trạng thái xóa mềm (Mặc định `FALSE`).

---

### Danh sách chi tiết 13 Bảng Dữ liệu

#### 1. Bảng `nhan_vien` (Nhân viên & Phân cấp quản lý)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_nv` | VARCHAR(20) | **PK** | Mã định danh nhân viên |
| `ho_ten` | VARCHAR(100) | NOT NULL | Họ và tên nhân viên |
| `gioi_tinh` | INT | NOT NULL, CHECK (0, 1, 2) | Giới tính (0: Nữ, 1: Nam, 2: Khác) |
| `ngay_sinh` | DATE | NOT NULL, < CURRENT_DATE | Ngày sinh |
| `cccd` | VARCHAR(20) | UNIQUE | Số căn cước công dân |
| `so_dien_thoai` | VARCHAR(15) | UNIQUE | Số điện thoại liên hệ |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Email công vụ |
| `chuc_vu` | VARCHAR(50) | NULL | Chức danh / Vị trí công tác |
| `ngay_vao_lam` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Ngày bắt đầu làm việc |
| `luong_co_dinh` | NUMERIC(15,2) | NOT NULL, DEFAULT 5.000.000 | Lương cứng cố định hàng tháng |
| `ma_nv_quan_ly` | VARCHAR(20) | FK -> `nhan_vien(ma_nv)` | Quản lý trực tiếp (Khác `ma_nv`) |
| `trang_thai` | VARCHAR(20) | CHECK ('DANG_LAM', 'NGHI_PHEP', 'DA_NGHI_VIEC') | Trạng thái làm việc |

#### 2. Bảng `chuong_trinh_dao_tao` (Chương trình đào tạo)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_ctdt` | VARCHAR(20) | **PK** | Mã chương trình (VD: CT01, CT02) |
| `ten_ctdt` | VARCHAR(150) | NOT NULL | Tên chương trình đào tạo |
| `mo_ta` | TEXT | NULL | Mục tiêu, nội dung chương trình |
| `phu_cap_ql_moi_hv` | NUMERIC(15,2) | NOT NULL, DEFAULT 50.000, >= 0 | Mức phụ cấp quản lý trên mỗi học viên |
| `ma_nv_quan_ly` | VARCHAR(20) | NOT NULL, FK -> `nhan_vien(ma_nv)` | Nhân sự phụ trách chương trình |
| `trang_thai` | VARCHAR(20) | CHECK ('DANG_MO', 'TAM_DUNG', 'DONG') | Trạng thái chương trình |

#### 3. Bảng `mon_hoc` (Môn học thuộc chương trình)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_mon` | VARCHAR(30) | **PK** | Mã môn (chứa mã CTĐT, VD: CT01-M01) |
| `ten_mon` | VARCHAR(100) | NOT NULL | Tên môn học (Unique trong 1 CTĐT) |
| `tong_so_gio` | INT | NOT NULL, CHECK (>0 AND chẵn) | Tổng số giờ học của môn |
| `so_buoi_hoc` | INT | GENERATED (tong_so_gio / 2) | Số buổi học (Mỗi buổi 2 giờ) |
| `mo_ta` | TEXT | NULL | Đề cương tóm tắt môn học |
| `ma_ctdt` | VARCHAR(20) | NOT NULL, FK -> `chuong_trinh_dao_tao(ma_ctdt)` | Thuộc chương trình đào tạo |
| `loai_mon` | VARCHAR(20) | CHECK ('BAT_BUOC', 'TU_CHON') | Tính chất môn học |

#### 4. Bảng `ky_hoc` (Kỳ học đào tạo)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_ky_hoc` | VARCHAR(20) | **PK** | Mã kỳ học (VD: 2026HK1, 2026HK2) |
| `ten_ky_hoc` | VARCHAR(100) | NOT NULL | Tên học kỳ |
| `nam_hoc` | VARCHAR(20) | NOT NULL | Năm học (VD: 2025-2026) |
| `tu_ngay` | DATE | NOT NULL | Ngày bắt đầu học kỳ |
| `den_ngay` | DATE | NOT NULL, CHECK (den_ngay > tu_ngay) | Ngày kết thúc học kỳ |
| `trang_thai` | VARCHAR(20) | CHECK ('SAP_MO', 'DANG_DIEN_RA', 'KET_THUC') | Trạng thái kỳ học |

#### 5. Bảng `khoa_dao_tao` (Khóa đào tạo cụ thể)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_khoa` | VARCHAR(40) | **PK** | Mã khóa (VD: CT01-2026HK1-K01) |
| `ten_khoa` | VARCHAR(150) | NOT NULL | Tên khóa đào tạo |
| `ngay_bat_dau` | DATE | NOT NULL | Ngày khai giảng |
| `ngay_ket_thuc` | DATE | NOT NULL, CHECK (>= ngay_bat_dau) | Ngày bế giảng |
| `ma_ctdt` | VARCHAR(20) | NOT NULL, FK -> `chuong_trinh_dao_tao` | Chương trình của khóa |
| `ma_ky_hoc` | VARCHAR(20) | NOT NULL, FK -> `ky_hoc` | Vận hành trong kỳ học |
| `trang_thai` | VARCHAR(20) | CHECK ('MO_DANG_KY', 'DANG_HOC', 'KET_THUC', 'HUY') | Trạng thái khóa |

#### 6. Bảng `hoc_vien` (Học viên)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_hv` | VARCHAR(20) | **PK** | Mã định danh học viên |
| `ho_ten` | VARCHAR(100) | NOT NULL | Họ và tên học viên |
| `ngay_sinh` | DATE | NULL | Ngày tháng năm sinh |
| `gioi_tinh` | INT | CHECK (0, 1, 2) | Giới tính (0: Nữ, 1: Nam, 2: Khác) |
| `so_dien_thoai` | VARCHAR(15) | UNIQUE | Số điện thoại liên hệ |
| `email` | VARCHAR(100) | UNIQUE | Email học viên |
| `dia_chi` | VARCHAR(255) | NULL | Địa chỉ cư trú |
| `trang_thai` | VARCHAR(20) | CHECK ('DANG_HOC', 'BAO_LUU', 'DA_TOT_NGHIEP', 'THOI_HOC') | Trạng thái học tập |

#### 7. Bảng `dang_ky_khoa_hoc` (Đăng ký tham gia khóa đào tạo)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_hv` | VARCHAR(20) | **PK**, FK -> `hoc_vien(ma_hv)` | Học viên đăng ký |
| `ma_khoa` | VARCHAR(40) | **PK**, FK -> `khoa_dao_tao(ma_khoa)` | Khóa học tham gia |
| `ngay_dang_ky` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Thời điểm ghi nhận đăng ký |
| `hoc_phi_da_dong`| NUMERIC(15,2)| NOT NULL, DEFAULT 0, >= 0 | Số tiền học phí đã hoàn thành |
| `trang_thai` | VARCHAR(20) | CHECK ('DA_DANG_KY', 'DANG_HOC', 'HOAN_THANH', 'HUY') | Trạng thái đăng ký |

#### 8. Bảng `giao_vien` (Giáo viên / Giảng viên / Trợ giảng)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_gv` | VARCHAR(20) | **PK** | Mã định danh giáo viên |
| `ho_ten` | VARCHAR(100) | NOT NULL | Họ và tên |
| `cccd` | VARCHAR(20) | UNIQUE | Căn cước công dân |
| `so_dien_thoai` | VARCHAR(15) | UNIQUE | Số điện thoại liên hệ |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Email liên lạc |
| `chuyen_mon` | VARCHAR(200) | NULL | Chuyên môn giảng dạy |
| `hoc_vi` | VARCHAR(50) | NULL | Thạc sĩ, Tiến sĩ, Kỹ sư... |
| `luong_tro_giang_gio`| NUMERIC(15,2)| NOT NULL, DEFAULT 100.000, >= 0 | Đơn giá trợ giảng/giờ (GV chính = $2 \times$ TA) |
| `loai_hop_dong`| VARCHAR(20) | CHECK ('FULLTIME', 'PARTTIME') | Loại hợp đồng lao động |
| `trang_thai` | VARCHAR(20) | CHECK ('DANG_DAY', 'NGHI_PHEP', 'DA_NGHI_VIEC') | Trạng thái giảng dạy |

#### 9. Bảng `lop_mon_hoc` (Môn học triển khai trong Khóa)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_lop_mon` | VARCHAR(40) | **PK** | Mã lớp môn (VD: LM_CT01_K01_M01) |
| `ma_khoa` | VARCHAR(40) | NOT NULL, FK -> `khoa_dao_tao` | Khóa đào tạo |
| `ma_mon` | VARCHAR(30) | NOT NULL, FK -> `mon_hoc` | Môn học triển khai |
| `trang_thai` | VARCHAR(20) | CHECK ('SAP_MO', 'DANG_HOC', 'HOAN_THANH', 'HUY') | Trạng thái lớp môn |

#### 10. Bảng `phan_cong_giang_day` (Phân công giảng dạy theo lớp môn)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_lop_mon` | VARCHAR(40) | **PK**, FK -> `lop_mon_hoc` | Lớp môn học |
| `ma_gv` | VARCHAR(20) | **PK**, FK -> `giao_vien` | Giáo viên được phân công |
| `vai_tro` | VARCHAR(20) | NOT NULL, CHECK ('GIANG_VIEN', 'TRO_GIANG') | Vai trò trong lớp |
| `ngay_phan_cong`| DATE | NOT NULL, DEFAULT CURRENT_DATE | Ngày phân công nhiệm vụ |

#### 11. Bảng `phong_hoc` (Phòng học)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_phong` | VARCHAR(20) | **PK** | Mã phòng học (VD: LAB_301, P_201) |
| `ten_phong` | VARCHAR(50) | NOT NULL | Tên hiển thị của phòng |
| `vi_tri` | VARCHAR(200) | NULL | Tòa nhà, tầng |
| `suc_chua` | INT | NOT NULL, CHECK (>0) | Số lượng chỗ ngồi tối đa |
| `loai_phong` | VARCHAR(20) | CHECK ('LY_THUYET', 'THUC_HANH_LAB', 'HOI_TRUONG') | Chức năng phòng |
| `trang_thai` | VARCHAR(20) | CHECK ('SAN_SANG', 'BAO_TRI', 'DONG_CUA') | Trạng thái sử dụng |
| `mo_ta` | TEXT | NULL | Trang thiết bị |

#### 12. Bảng `buoi_hoc` (Buổi học chi tiết)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_buoi` | BIGSERIAL | **PK** | Mã định danh buổi học |
| `ma_lop_mon` | VARCHAR(40) | NOT NULL, FK -> `lop_mon_hoc` | Thuộc lớp môn học nào |
| `thu_tu_buoi` | INT | NOT NULL, CHECK (>0) | Buổi thứ mấy của môn học |
| `ngay_hoc` | DATE | NOT NULL | Ngày diễn ra |
| `gio_bat_dau` | TIME | NOT NULL | Giờ bắt đầu |
| `gio_ket_thuc` | TIME | NOT NULL, CHECK (= gio_bat_dau + 2h) | Giờ kết thúc (Đúng 2 tiếng) |
| `ma_phong` | VARCHAR(20) | NOT NULL, FK -> `phong_hoc` | Phòng tổ chức |
| `trang_thai` | VARCHAR(20) | CHECK ('DA_LEN_LICH', 'HOAN_THANH', 'HUY_BUOI') | Trạng thái buổi học |

#### 13. Bảng `ket_qua_thi` (Lịch sử các lần thi của học viên)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `ma_hv` | VARCHAR(20) | **PK**, FK -> `hoc_vien` | Học viên dự thi |
| `ma_lop_mon` | VARCHAR(40) | **PK**, FK -> `lop_mon_hoc` | Thi môn học của lớp nào |
| `lan_thi` | INT | **PK**, CHECK (>0) | Lần thi thứ mấy (1, 2, 3...) |
| `ngay_thi` | DATE | NOT NULL | Ngày tham gia thi |
| `diem_thi` | NUMERIC(4,2) | NOT NULL, CHECK (0 <= diem_thi <= 10) | Điểm số đạt được |
| `ket_qua` | VARCHAR(20) | GENERATED (diem_thi > 5.0 -> DAT) | Trạng thái ĐẠT / CHƯA ĐẠT |
| `ghi_chu` | VARCHAR(200)| NULL | Nhận xét của giảng viên/khảo thí |
