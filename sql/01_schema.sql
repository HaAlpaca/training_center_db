-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 1: TẠO CẤU TRÚC 13 BẢNG (DDL) & RÀNG BUỘC TOÀN VẸN (CONSTRAINTS)
-- =========================================================================

SET client_encoding = 'UTF8';

-- Xóa các bảng cũ nếu đã tồn tại theo thứ tự ràng buộc khóa ngoại (CASCADE)
DROP TABLE IF EXISTS ket_qua_thi CASCADE;
DROP TABLE IF EXISTS buoi_hoc CASCADE;
DROP TABLE IF EXISTS phan_cong_giang_day CASCADE;
DROP TABLE IF EXISTS lop_mon_hoc CASCADE;
DROP TABLE IF EXISTS dang_ky_khoa_hoc CASCADE;
DROP TABLE IF EXISTS phong_hoc CASCADE;
DROP TABLE IF EXISTS giao_vien CASCADE;
DROP TABLE IF EXISTS hoc_vien CASCADE;
DROP TABLE IF EXISTS khoa_dao_tao CASCADE;
DROP TABLE IF EXISTS ky_hoc CASCADE;
DROP TABLE IF EXISTS mon_hoc CASCADE;
DROP TABLE IF EXISTS chuong_trinh_dao_tao CASCADE;
DROP TABLE IF EXISTS nhan_vien CASCADE;

-- Xóa các bảng tiếng Anh cũ nếu còn sót lại
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
-- 1. BẢNG NHAN_VIEN (Nhân sự & Cơ chế quản lý phân cấp đệ quy)
-- =========================================================================
CREATE TABLE nhan_vien (
    ma_nv VARCHAR(20) PRIMARY KEY,
    ho_ten VARCHAR(100) NOT NULL,
    gioi_tinh INT NOT NULL CHECK (gioi_tinh IN (0, 1, 2)), -- 0: Nữ, 1: Nam, 2: Khác
    ngay_sinh DATE NOT NULL CHECK (ngay_sinh < CURRENT_DATE),
    cccd VARCHAR(20) UNIQUE,
    so_dien_thoai VARCHAR(15) UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    chuc_vu VARCHAR(50),
    ngay_vao_lam DATE NOT NULL DEFAULT CURRENT_DATE,
    luong_co_dinh NUMERIC(15, 2) NOT NULL DEFAULT 5000000 CHECK (luong_co_dinh >= 0),
    ma_nv_quan_ly VARCHAR(20) REFERENCES nhan_vien(ma_nv), -- Nhân viên quản lý trực tiếp
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_LAM' CHECK (trang_thai IN ('DANG_LAM', 'NGHI_PHEP', 'DA_NGHI_VIEC')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Ràng buộc: Một nhân viên không được tự quản lý chính mình
    CONSTRAINT ck_nhan_vien_khong_tu_quan_ly CHECK (ma_nv_quan_ly IS NULL OR ma_nv_quan_ly <> ma_nv)
);

-- =========================================================================
-- 2. BẢNG CHUONG_TRINH_DAO_TAO (Chương trình đào tạo)
-- =========================================================================
CREATE TABLE chuong_trinh_dao_tao (
    ma_ctdt VARCHAR(20) PRIMARY KEY, -- Ví dụ: CT01, CT02, CT_DATA
    ten_ctdt VARCHAR(150) NOT NULL,
    mo_ta TEXT,
    phu_cap_ql_moi_hv NUMERIC(15, 2) NOT NULL DEFAULT 50000 CHECK (phu_cap_ql_moi_hv >= 0), -- Phụ cấp quản lý trên mỗi học viên
    ma_nv_quan_ly VARCHAR(20) NOT NULL REFERENCES nhan_vien(ma_nv), -- Đúng 1 nhân viên quản lý
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_MO' CHECK (trang_thai IN ('DANG_MO', 'TAM_DUNG', 'DONG')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================================================================
-- 3. BẢNG MON_HOC (Môn học thuộc chương trình)
-- =========================================================================
CREATE TABLE mon_hoc (
    ma_mon VARCHAR(30) PRIMARY KEY, -- Thể hiện mã CTĐT, ví dụ: CT01-M01, CT01-M02
    ten_mon VARCHAR(100) NOT NULL,
    tong_so_gio INT NOT NULL CHECK (tong_so_gio > 0 AND tong_so_gio % 2 = 0), -- Mỗi buổi 2 giờ nên tổng giờ phải chẵn
    so_buoi_hoc INT GENERATED ALWAYS AS (tong_so_gio / 2) STORED, -- Số buổi học = Tổng số giờ / 2
    mo_ta TEXT,
    ma_ctdt VARCHAR(20) NOT NULL REFERENCES chuong_trinh_dao_tao(ma_ctdt),
    loai_mon VARCHAR(20) NOT NULL DEFAULT 'BAT_BUOC' CHECK (loai_mon IN ('BAT_BUOC', 'TU_CHON')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Ràng buộc: Tên môn học không được trùng nhau trong cùng một chương trình đào tạo
    CONSTRAINT uq_mon_hoc_ten_theo_ctdt UNIQUE (ma_ctdt, ten_mon)
);

-- =========================================================================
-- 4. BẢNG KY_HOC (Kỳ học đào tạo)
-- =========================================================================
CREATE TABLE ky_hoc (
    ma_ky_hoc VARCHAR(20) PRIMARY KEY, -- Ví dụ: 2026HK1, 2026HK2
    ten_ky_hoc VARCHAR(100) NOT NULL,
    nam_hoc VARCHAR(20) NOT NULL, -- Ví dụ: 2025-2026, 2026-2027
    tu_ngay DATE NOT NULL,
    den_ngay DATE NOT NULL,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'SAP_MO' CHECK (trang_thai IN ('SAP_MO', 'DANG_DIEN_RA', 'KET_THUC')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Ràng buộc: Ngày kết thúc phải sau ngày bắt đầu
    CONSTRAINT ck_ky_hoc_thoi_gian CHECK (den_ngay > tu_ngay)
);

-- =========================================================================
-- 5. BẢNG KHOA_DAO_TAO (Khóa đào tạo cụ thể theo kỳ học)
-- =========================================================================
CREATE TABLE khoa_dao_tao (
    ma_khoa VARCHAR(40) PRIMARY KEY, -- Ví dụ: CT01-2026HK1-K01
    ten_khoa VARCHAR(150) NOT NULL,
    ngay_bat_dau DATE NOT NULL,
    ngay_ket_thuc DATE NOT NULL,
    ma_ctdt VARCHAR(20) NOT NULL REFERENCES chuong_trinh_dao_tao(ma_ctdt),
    ma_ky_hoc VARCHAR(20) NOT NULL REFERENCES ky_hoc(ma_ky_hoc),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'MO_DANG_KY' CHECK (trang_thai IN ('MO_DANG_KY', 'DANG_HOC', 'KET_THUC', 'HUY')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_khoa_dao_tao_thoi_gian CHECK (ngay_ket_thuc >= ngay_bat_dau)
);

-- =========================================================================
-- 6. BẢNG HOC_VIEN (Học viên)
-- =========================================================================
CREATE TABLE hoc_vien (
    ma_hv VARCHAR(20) PRIMARY KEY,
    ho_ten VARCHAR(100) NOT NULL,
    ngay_sinh DATE,
    gioi_tinh INT CHECK (gioi_tinh IN (0, 1, 2)), -- 0: Nữ, 1: Nam, 2: Khác
    so_dien_thoai VARCHAR(15) UNIQUE,
    email VARCHAR(100) UNIQUE,
    dia_chi VARCHAR(255),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_HOC' CHECK (trang_thai IN ('DANG_HOC', 'BAO_LUU', 'DA_TOT_NGHIEP', 'THOI_HOC')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================================================================
-- 7. BẢNG DANG_KY_KHOA_HOC (Học viên đăng ký tham gia khóa đào tạo)
-- =========================================================================
CREATE TABLE dang_ky_khoa_hoc (
    ma_hv VARCHAR(20) NOT NULL REFERENCES hoc_vien(ma_hv),
    ma_khoa VARCHAR(40) NOT NULL REFERENCES khoa_dao_tao(ma_khoa),
    ngay_dang_ky TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hoc_phi_da_dong NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (hoc_phi_da_dong >= 0),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DA_DANG_KY' CHECK (trang_thai IN ('DA_DANG_KY', 'DANG_HOC', 'HOAN_THANH', 'HUY')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ma_hv, ma_khoa)
);

-- =========================================================================
-- 8. BẢNG GIAO_VIEN (Giáo viên / Giảng viên / Trợ giảng)
-- =========================================================================
CREATE TABLE giao_vien (
    ma_gv VARCHAR(20) PRIMARY KEY,
    ho_ten VARCHAR(100) NOT NULL,
    cccd VARCHAR(20) UNIQUE,
    so_dien_thoai VARCHAR(15) UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    chuyen_mon VARCHAR(200),
    hoc_vi VARCHAR(50),
    luong_tro_giang_gio NUMERIC(15, 2) NOT NULL DEFAULT 100000 CHECK (luong_tro_giang_gio >= 0), -- Đơn giá chuẩn mỗi giờ làm trợ giảng
    loai_hop_dong VARCHAR(20) NOT NULL DEFAULT 'PARTTIME' CHECK (loai_hop_dong IN ('FULLTIME', 'PARTTIME')),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_DAY' CHECK (trang_thai IN ('DANG_DAY', 'NGHI_PHEP', 'DA_NGHI_VIEC')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================================================================
-- 9. BẢNG LOP_MON_HOC (Một môn học được triển khai trong một khóa cụ thể)
-- =========================================================================
CREATE TABLE lop_mon_hoc (
    ma_lop_mon VARCHAR(40) PRIMARY KEY, -- Ví dụ: LM_CT01_K01_M01
    ma_khoa VARCHAR(40) NOT NULL REFERENCES khoa_dao_tao(ma_khoa),
    ma_mon VARCHAR(30) NOT NULL REFERENCES mon_hoc(ma_mon),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'SAP_MO' CHECK (trang_thai IN ('SAP_MO', 'DANG_HOC', 'HOAN_THANH', 'HUY')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Ràng buộc: Trong cùng 1 khóa đào tạo, 1 môn học chỉ được mở 1 lớp môn học
    CONSTRAINT uq_lop_mon_khoa UNIQUE (ma_khoa, ma_mon)
);

-- =========================================================================
-- 10. BẢNG PHAN_CONG_GIANG_DAY (Phân công giáo viên vào lớp môn học)
-- =========================================================================
CREATE TABLE phan_cong_giang_day (
    ma_lop_mon VARCHAR(40) NOT NULL REFERENCES lop_mon_hoc(ma_lop_mon),
    ma_gv VARCHAR(20) NOT NULL REFERENCES giao_vien(ma_gv),
    vai_tro VARCHAR(20) NOT NULL CHECK (vai_tro IN ('GIANG_VIEN', 'TRO_GIANG')),
    ngay_phan_cong DATE NOT NULL DEFAULT CURRENT_DATE,
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ma_lop_mon, ma_gv)
);

-- =========================================================================
-- 11. BẢNG PHONG_HOC (Phòng học)
-- =========================================================================
CREATE TABLE phong_hoc (
    ma_phong VARCHAR(20) PRIMARY KEY,
    ten_phong VARCHAR(50) NOT NULL,
    vi_tri VARCHAR(200),
    suc_chua INT NOT NULL CHECK (suc_chua > 0),
    loai_phong VARCHAR(20) NOT NULL DEFAULT 'LY_THUYET' CHECK (loai_phong IN ('LY_THUYET', 'THUC_HANH_LAB', 'HOI_TRUONG')),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'SAN_SANG' CHECK (trang_thai IN ('SAN_SANG', 'BAO_TRI', 'DONG_CUA')),
    mo_ta TEXT,
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================================================================
-- 12. BẢNG BUOI_HOC (Buổi học chi tiết - kéo dài đúng 2 giờ)
-- =========================================================================
CREATE TABLE buoi_hoc (
    ma_buoi BIGSERIAL PRIMARY KEY,
    ma_lop_mon VARCHAR(40) NOT NULL REFERENCES lop_mon_hoc(ma_lop_mon),
    thu_tu_buoi INT NOT NULL CHECK (thu_tu_buoi > 0),
    ngay_hoc DATE NOT NULL,
    gio_bat_dau TIME NOT NULL,
    gio_ket_thuc TIME NOT NULL,
    ma_phong VARCHAR(20) NOT NULL REFERENCES phong_hoc(ma_phong),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DA_LEN_LICH' CHECK (trang_thai IN ('DA_LEN_LICH', 'HOAN_THANH', 'HUY_BUOI')),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Ràng buộc: Mỗi buổi học kéo dài đúng 2 giờ
    CONSTRAINT ck_buoi_hoc_thoi_luong CHECK (gio_ket_thuc = gio_bat_dau + INTERVAL '2 hours')
);

-- =========================================================================
-- 13. BẢNG KET_QUA_THI (Lưu lịch sử các lần thi của học viên đối với lớp môn học)
-- =========================================================================
CREATE TABLE ket_qua_thi (
    ma_hv VARCHAR(20) NOT NULL REFERENCES hoc_vien(ma_hv),
    ma_lop_mon VARCHAR(40) NOT NULL REFERENCES lop_mon_hoc(ma_lop_mon),
    lan_thi INT NOT NULL CHECK (lan_thi > 0),
    ngay_thi DATE NOT NULL,
    diem_thi NUMERIC(4, 2) NOT NULL CHECK (diem_thi >= 0 AND diem_thi <= 10),
    ket_qua VARCHAR(20) GENERATED ALWAYS AS (CASE WHEN diem_thi > 5.0 THEN 'DAT' ELSE 'CHUA_DAT' END) STORED,
    ghi_chu VARCHAR(200),
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ma_hv, ma_lop_mon, lan_thi)
);
