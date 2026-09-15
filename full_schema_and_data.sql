-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- TẬP TIN TỔNG HỢP TOÀN BỘ CƠ SỞ DỮ LIỆU (FULL MASTER SCRIPT)
-- BAO GỒM: 13 BẢNG TIẾNG VIỆT + 5 TRIGGERS + FUNCTIONS + VIEWS + SEED DATA + 5 PROCEDURES (TRANSACTIONS)
-- =========================================================================

SET client_encoding = 'UTF8';

-- =========================================================================
-- PHẦN 1: TẠO CẤU TRÚC 13 BẢNG (DDL) & RÀNG BUỘC TOÀN VẸN (CONSTRAINTS)
-- =========================================================================

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

-- 1. BẢNG NHAN_VIEN
CREATE TABLE nhan_vien (
    ma_nv VARCHAR(20) PRIMARY KEY,
    ho_ten VARCHAR(100) NOT NULL,
    gioi_tinh INT NOT NULL CHECK (gioi_tinh IN (0, 1, 2)),
    ngay_sinh DATE NOT NULL CHECK (ngay_sinh < CURRENT_DATE),
    cccd VARCHAR(20) UNIQUE,
    so_dien_thoai VARCHAR(15) UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    chuc_vu VARCHAR(50),
    ngay_vao_lam DATE NOT NULL DEFAULT CURRENT_DATE,
    luong_co_dinh NUMERIC(15, 2) NOT NULL DEFAULT 5000000 CHECK (luong_co_dinh >= 0),
    ma_nv_quan_ly VARCHAR(20) REFERENCES nhan_vien(ma_nv),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_LAM' CHECK (trang_thai IN ('DANG_LAM', 'NGHI_PHEP', 'DA_NGHI_VIEC')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_nhan_vien_khong_tu_quan_ly CHECK (ma_nv_quan_ly IS NULL OR ma_nv_quan_ly <> ma_nv)
);

-- 2. BẢNG CHUONG_TRINH_DAO_TAO
CREATE TABLE chuong_trinh_dao_tao (
    ma_ctdt VARCHAR(20) PRIMARY KEY,
    ten_ctdt VARCHAR(150) NOT NULL,
    mo_ta TEXT,
    phu_cap_ql_moi_hv NUMERIC(15, 2) NOT NULL DEFAULT 50000 CHECK (phu_cap_ql_moi_hv >= 0),
    ma_nv_quan_ly VARCHAR(20) NOT NULL REFERENCES nhan_vien(ma_nv),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_MO' CHECK (trang_thai IN ('DANG_MO', 'TAM_DUNG', 'DONG')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 3. BẢNG MON_HOC
CREATE TABLE mon_hoc (
    ma_mon VARCHAR(30) PRIMARY KEY,
    ten_mon VARCHAR(100) NOT NULL,
    tong_so_gio INT NOT NULL CHECK (tong_so_gio > 0 AND tong_so_gio % 2 = 0),
    so_buoi_hoc INT GENERATED ALWAYS AS (tong_so_gio / 2) STORED,
    mo_ta TEXT,
    ma_ctdt VARCHAR(20) NOT NULL REFERENCES chuong_trinh_dao_tao(ma_ctdt),
    loai_mon VARCHAR(20) NOT NULL DEFAULT 'BAT_BUOC' CHECK (loai_mon IN ('BAT_BUOC', 'TU_CHON')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_mon_hoc_ten_theo_ctdt UNIQUE (ma_ctdt, ten_mon)
);

-- 4. BẢNG KY_HOC
CREATE TABLE ky_hoc (
    ma_ky_hoc VARCHAR(20) PRIMARY KEY,
    ten_ky_hoc VARCHAR(100) NOT NULL,
    nam_hoc VARCHAR(20) NOT NULL,
    tu_ngay DATE NOT NULL,
    den_ngay DATE NOT NULL,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'SAP_MO' CHECK (trang_thai IN ('SAP_MO', 'DANG_DIEN_RA', 'KET_THUC')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_ky_hoc_thoi_gian CHECK (den_ngay > tu_ngay)
);

-- 5. BẢNG KHOA_DAO_TAO
CREATE TABLE khoa_dao_tao (
    ma_khoa VARCHAR(40) PRIMARY KEY,
    ten_khoa VARCHAR(150) NOT NULL,
    ngay_bat_dau DATE NOT NULL,
    ngay_ket_thuc DATE NOT NULL,
    ma_ctdt VARCHAR(20) NOT NULL REFERENCES chuong_trinh_dao_tao(ma_ctdt),
    ma_ky_hoc VARCHAR(20) NOT NULL REFERENCES ky_hoc(ma_ky_hoc),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'MO_DANG_KY' CHECK (trang_thai IN ('MO_DANG_KY', 'DANG_HOC', 'KET_THUC', 'HUY')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_khoa_dao_tao_thoi_gian CHECK (ngay_ket_thuc >= ngay_bat_dau)
);

-- 6. BẢNG HOC_VIEN
CREATE TABLE hoc_vien (
    ma_hv VARCHAR(20) PRIMARY KEY,
    ho_ten VARCHAR(100) NOT NULL,
    ngay_sinh DATE,
    gioi_tinh INT CHECK (gioi_tinh IN (0, 1, 2)),
    so_dien_thoai VARCHAR(15) UNIQUE,
    email VARCHAR(100) UNIQUE,
    dia_chi VARCHAR(255),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_HOC' CHECK (trang_thai IN ('DANG_HOC', 'BAO_LUU', 'DA_TOT_NGHIEP', 'THOI_HOC')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 7. BẢNG DANG_KY_KHOA_HOC
CREATE TABLE dang_ky_khoa_hoc (
    ma_hv VARCHAR(20) NOT NULL REFERENCES hoc_vien(ma_hv),
    ma_khoa VARCHAR(40) NOT NULL REFERENCES khoa_dao_tao(ma_khoa),
    ngay_dang_ky TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hoc_phi_da_dong NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (hoc_phi_da_dong >= 0),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DA_DANG_KY' CHECK (trang_thai IN ('DA_DANG_KY', 'DANG_HOC', 'HOAN_THANH', 'HUY')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ma_hv, ma_khoa)
);

-- 8. BẢNG GIAO_VIEN
CREATE TABLE giao_vien (
    ma_gv VARCHAR(20) PRIMARY KEY,
    ho_ten VARCHAR(100) NOT NULL,
    cccd VARCHAR(20) UNIQUE,
    so_dien_thoai VARCHAR(15) UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    chuyen_mon VARCHAR(200),
    hoc_vi VARCHAR(50),
    luong_tro_giang_gio NUMERIC(15, 2) NOT NULL DEFAULT 100000 CHECK (luong_tro_giang_gio >= 0),
    loai_hop_dong VARCHAR(20) NOT NULL DEFAULT 'PARTTIME' CHECK (loai_hop_dong IN ('FULLTIME', 'PARTTIME')),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DANG_DAY' CHECK (trang_thai IN ('DANG_DAY', 'NGHI_PHEP', 'DA_NGHI_VIEC')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 9. BẢNG LOP_MON_HOC
CREATE TABLE lop_mon_hoc (
    ma_lop_mon VARCHAR(40) PRIMARY KEY,
    ma_khoa VARCHAR(40) NOT NULL REFERENCES khoa_dao_tao(ma_khoa),
    ma_mon VARCHAR(30) NOT NULL REFERENCES mon_hoc(ma_mon),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'SAP_MO' CHECK (trang_thai IN ('SAP_MO', 'DANG_HOC', 'HOAN_THANH', 'HUY')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_lop_mon_khoa UNIQUE (ma_khoa, ma_mon)
);

-- 10. BẢNG PHAN_CONG_GIANG_DAY
CREATE TABLE phan_cong_giang_day (
    ma_lop_mon VARCHAR(40) NOT NULL REFERENCES lop_mon_hoc(ma_lop_mon),
    ma_gv VARCHAR(20) NOT NULL REFERENCES giao_vien(ma_gv),
    vai_tro VARCHAR(20) NOT NULL CHECK (vai_tro IN ('GIANG_VIEN', 'TRO_GIANG')),
    ngay_phan_cong DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ma_lop_mon, ma_gv)
);

-- 11. BẢNG PHONG_HOC
CREATE TABLE phong_hoc (
    ma_phong VARCHAR(20) PRIMARY KEY,
    ten_phong VARCHAR(50) NOT NULL,
    vi_tri VARCHAR(200),
    suc_chua INT NOT NULL CHECK (suc_chua > 0),
    loai_phong VARCHAR(20) NOT NULL DEFAULT 'LY_THUYET' CHECK (loai_phong IN ('LY_THUYET', 'THUC_HANH_LAB', 'HOI_TRUONG')),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'SAN_SANG' CHECK (trang_thai IN ('SAN_SANG', 'BAO_TRI', 'DONG_CUA')),
    mo_ta TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 12. BẢNG BUOI_HOC
CREATE TABLE buoi_hoc (
    ma_buoi BIGSERIAL PRIMARY KEY,
    ma_lop_mon VARCHAR(40) NOT NULL REFERENCES lop_mon_hoc(ma_lop_mon),
    thu_tu_buoi INT NOT NULL CHECK (thu_tu_buoi > 0),
    ngay_hoc DATE NOT NULL,
    gio_bat_dau TIME NOT NULL,
    gio_ket_thuc TIME NOT NULL,
    ma_phong VARCHAR(20) NOT NULL REFERENCES phong_hoc(ma_phong),
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'DA_LEN_LICH' CHECK (trang_thai IN ('DA_LEN_LICH', 'HOAN_THANH', 'HUY_BUOI')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_buoi_hoc_thoi_luong CHECK (gio_ket_thuc = gio_bat_dau + INTERVAL '2 hours')
);

-- 13. BẢNG KET_QUA_THI
CREATE TABLE ket_qua_thi (
    ma_hv VARCHAR(20) NOT NULL REFERENCES hoc_vien(ma_hv),
    ma_lop_mon VARCHAR(40) NOT NULL REFERENCES lop_mon_hoc(ma_lop_mon),
    lan_thi INT NOT NULL CHECK (lan_thi > 0),
    ngay_thi DATE NOT NULL,
    diem_thi NUMERIC(4, 2) NOT NULL CHECK (diem_thi >= 0 AND diem_thi <= 10),
    ket_qua VARCHAR(20) GENERATED ALWAYS AS (CASE WHEN diem_thi > 5.0 THEN 'DAT' ELSE 'CHUA_DAT' END) STORED,
    ghi_chu VARCHAR(200),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    updated_at TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ma_hv, ma_lop_mon, lan_thi)
);


-- =========================================================================
-- PHẦN 2: 5 TRIGGERS PL/PGSQL KIỂM SOÁT RÀNG BUỘC TOÀN VẸN
-- =========================================================================

-- TRIGGER 1
CREATE OR REPLACE FUNCTION fn_kiem_tra_so_mon_ctdt()
RETURNS TRIGGER AS $$
DECLARE
    v_so_mon INT;
BEGIN
    SELECT COUNT(*) INTO v_so_mon
    FROM mon_hoc
    WHERE ma_ctdt = NEW.ma_ctdt AND is_deleted = FALSE;

    IF v_so_mon > 10 THEN
        RAISE EXCEPTION 'Chương trình đào tạo % đã có 10 môn học. Mỗi chương trình chỉ được phép có tối đa 10 môn học.', NEW.ma_ctdt;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kiem_tra_so_mon_ctdt ON mon_hoc;
CREATE TRIGGER trg_kiem_tra_so_mon_ctdt
AFTER INSERT OR UPDATE ON mon_hoc
FOR EACH ROW
EXECUTE FUNCTION fn_kiem_tra_so_mon_ctdt();

-- TRIGGER 2
CREATE OR REPLACE FUNCTION fn_kiem_tra_trung_phong()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM buoi_hoc
        WHERE ma_phong = NEW.ma_phong
          AND ngay_hoc = NEW.ngay_hoc
          AND ma_buoi <> COALESCE(NEW.ma_buoi, -1)
          AND trang_thai <> 'HUY_BUOI'
          AND is_deleted = FALSE
          AND NEW.trang_thai <> 'HUY_BUOI'
          AND NEW.gio_bat_dau < gio_ket_thuc
          AND NEW.gio_ket_thuc > gio_bat_dau
    ) THEN
        RAISE EXCEPTION 'Phòng học % đã có lịch học vào ngày % trong khung giờ % - %.', 
            NEW.ma_phong, NEW.ngay_hoc, NEW.gio_bat_dau, NEW.gio_ket_thuc;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kiem_tra_trung_phong ON buoi_hoc;
CREATE TRIGGER trg_kiem_tra_trung_phong
BEFORE INSERT OR UPDATE ON buoi_hoc
FOR EACH ROW
EXECUTE FUNCTION fn_kiem_tra_trung_phong();

-- TRIGGER 3
CREATE OR REPLACE FUNCTION fn_kiem_tra_trung_lich_giao_vien()
RETURNS TRIGGER AS $$
DECLARE
    v_gv RECORD;
BEGIN
    FOR v_gv IN 
        SELECT ma_gv, vai_tro 
        FROM phan_cong_giang_day 
        WHERE ma_lop_mon = NEW.ma_lop_mon AND is_deleted = FALSE
    LOOP
        IF EXISTS (
            SELECT 1
            FROM buoi_hoc bh
            JOIN phan_cong_giang_day pc ON bh.ma_lop_mon = pc.ma_lop_mon
            WHERE pc.ma_gv = v_gv.ma_gv
              AND bh.ngay_hoc = NEW.ngay_hoc
              AND bh.ma_buoi <> COALESCE(NEW.ma_buoi, -1)
              AND bh.trang_thai <> 'HUY_BUOI'
              AND bh.is_deleted = FALSE
              AND pc.is_deleted = FALSE
              AND NEW.trang_thai <> 'HUY_BUOI'
              AND NEW.gio_bat_dau < bh.gio_ket_thuc
              AND NEW.gio_ket_thuc > bh.gio_bat_dau
        ) THEN
            RAISE EXCEPTION 'Giáo viên % đã có lịch giảng dạy vào ngày % trong khung giờ % - %.', 
                v_gv.ma_gv, NEW.ngay_hoc, NEW.gio_bat_dau, NEW.gio_ket_thuc;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kiem_tra_trung_lich_gv ON buoi_hoc;
CREATE TRIGGER trg_kiem_tra_trung_lich_gv
BEFORE INSERT OR UPDATE ON buoi_hoc
FOR EACH ROW
EXECUTE FUNCTION fn_kiem_tra_trung_lich_giao_vien();

-- TRIGGER 4
CREATE OR REPLACE FUNCTION fn_kiem_tra_phan_cong_giao_vien()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM phan_cong_giang_day
        WHERE ma_lop_mon = NEW.ma_lop_mon
          AND ma_gv = NEW.ma_gv
          AND vai_tro <> NEW.vai_tro
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Một giáo viên (%) không thể đồng thời giữ cả 2 vai trò Giảng viên và Trợ giảng trong cùng một lớp môn học.', NEW.ma_gv;
    END IF;

    IF NEW.vai_tro = 'GIANG_VIEN' AND EXISTS (
        SELECT 1
        FROM phan_cong_giang_day
        WHERE ma_lop_mon = NEW.ma_lop_mon
          AND vai_tro = 'GIANG_VIEN'
          AND ma_gv <> NEW.ma_gv
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Lớp môn học % đã có Giảng viên chính đảm nhiệm. Mỗi lớp chỉ có đúng 1 Giảng viên chính.', NEW.ma_lop_mon;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kiem_tra_phan_cong ON phan_cong_giang_day;
CREATE TRIGGER trg_kiem_tra_phan_cong
BEFORE INSERT OR UPDATE ON phan_cong_giang_day
FOR EACH ROW
EXECUTE FUNCTION fn_kiem_tra_phan_cong_giao_vien();

-- TRIGGER 5
CREATE OR REPLACE FUNCTION fn_kiem_tra_hoc_vien_du_thi()
RETURNS TRIGGER AS $$
DECLARE
    v_ma_khoa VARCHAR(40);
BEGIN
    SELECT ma_khoa INTO v_ma_khoa
    FROM lop_mon_hoc
    WHERE ma_lop_mon = NEW.ma_lop_mon AND is_deleted = FALSE;

    IF v_ma_khoa IS NULL THEN
        RAISE EXCEPTION 'Lớp môn học % không tồn tại hoặc đã bị xóa.', NEW.ma_lop_mon;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM dang_ky_khoa_hoc
        WHERE ma_hv = NEW.ma_hv
          AND ma_khoa = v_ma_khoa
          AND is_deleted = FALSE
          AND trang_thai <> 'HUY'
    ) THEN
        RAISE EXCEPTION 'Học viên % chưa đăng ký khóa đào tạo % (sở hữu lớp môn %). Không thể ghi nhận kết quả thi!',
            NEW.ma_hv, v_ma_khoa, NEW.ma_lop_mon;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kiem_tra_hoc_vien_du_thi ON ket_qua_thi;
CREATE TRIGGER trg_kiem_tra_hoc_vien_du_thi
BEFORE INSERT OR UPDATE ON ket_qua_thi
FOR EACH ROW
EXECUTE FUNCTION fn_kiem_tra_hoc_vien_du_thi();


-- =========================================================================
-- PHẦN 3: STORED FUNCTIONS NGHIỆP VỤ & TÍNH TOÁN LƯƠNG
-- =========================================================================

CREATE OR REPLACE FUNCTION fn_bang_diem_hoc_vien(p_ma_hv VARCHAR)
RETURNS TABLE (
    ma_hv VARCHAR,
    ho_ten_hv VARCHAR,
    ma_khoa VARCHAR,
    ten_khoa VARCHAR,
    ma_mon VARCHAR,
    ten_mon VARCHAR,
    lan_thi INT,
    diem_thi NUMERIC,
    ngay_thi DATE,
    ket_qua VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        hv.ma_hv,
        hv.ho_ten AS ho_ten_hv,
        kdt.ma_khoa,
        kdt.ten_khoa,
        mh.ma_mon,
        mh.ten_mon,
        kqt.lan_thi,
        kqt.diem_thi,
        kqt.ngay_thi,
        kqt.ket_qua
    FROM hoc_vien hv
    JOIN dang_ky_khoa_hoc dk ON hv.ma_hv = dk.ma_hv
    JOIN khoa_dao_tao kdt ON dk.ma_khoa = kdt.ma_khoa
    JOIN lop_mon_hoc lmh ON kdt.ma_khoa = lmh.ma_khoa
    JOIN mon_hoc mh ON lmh.ma_mon = mh.ma_mon
    LEFT JOIN ket_qua_thi kqt ON hv.ma_hv = kqt.ma_hv 
                              AND lmh.ma_lop_mon = kqt.ma_lop_mon
                              AND kqt.is_deleted = FALSE
    WHERE hv.ma_hv = p_ma_hv
      AND hv.is_deleted = FALSE
      AND dk.is_deleted = FALSE
    ORDER BY kdt.ma_khoa, mh.ma_mon, kqt.lan_thi;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_hoc_vien_chua_hoan_thanh_khoa(p_ma_khoa VARCHAR)
RETURNS TABLE (
    ma_hv VARCHAR,
    ho_ten_hv VARCHAR,
    ma_mon VARCHAR,
    ten_mon VARCHAR,
    ma_lop_mon VARCHAR,
    trang_thai_hoan_thanh TEXT,
    diem_cao_nhat NUMERIC,
    so_lan_thi_rot BIGINT,
    chi_tiet_lan_rot TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH cac_lop_mon_khoa AS (
        SELECT lm.ma_lop_mon, lm.ma_khoa, lm.ma_mon, mh.ten_mon
        FROM lop_mon_hoc lm
        JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
        WHERE lm.ma_khoa = p_ma_khoa AND lm.is_deleted = FALSE
    ),
    hoc_vien_khoa AS (
        SELECT dk.ma_hv, hv.ho_ten
        FROM dang_ky_khoa_hoc dk
        JOIN hoc_vien hv ON dk.ma_hv = hv.ma_hv
        WHERE dk.ma_khoa = p_ma_khoa AND dk.is_deleted = FALSE
    ),
    mon_da_dat AS (
        SELECT DISTINCT kq.ma_hv, kq.ma_lop_mon
        FROM ket_qua_thi kq
        JOIN cac_lop_mon_khoa clm ON kq.ma_lop_mon = clm.ma_lop_mon
        WHERE kq.diem_thi > 5.0 AND kq.is_deleted = FALSE
    ),
    lich_su_thi_rot AS (
        SELECT 
            kq.ma_hv,
            kq.ma_lop_mon,
            COUNT(*)::BIGINT AS so_lan_rot,
            MAX(kq.diem_thi) AS diem_rot_cao_nhat,
            STRING_AGG(
                'Lần ' || kq.lan_thi || ': ' || kq.diem_thi || ' điểm (' || TO_CHAR(kq.ngay_thi, 'DD/MM/YYYY') || ')',
                '; ' ORDER BY kq.lan_thi
            ) AS chuoi_lich_su_rot
        FROM ket_qua_thi kq
        JOIN cac_lop_mon_khoa clm ON kq.ma_lop_mon = clm.ma_lop_mon
        WHERE kq.diem_thi <= 5.0 AND kq.is_deleted = FALSE
        GROUP BY kq.ma_hv, kq.ma_lop_mon
    )
    SELECT 
        hvk.ma_hv,
        hvk.ho_ten AS ho_ten_hv,
        clm.ma_mon,
        clm.ten_mon,
        clm.ma_lop_mon,
        CASE 
            WHEN lsr.so_lan_rot IS NOT NULL THEN 'Chưa đạt (Đã thi nhưng rớt)'
            ELSE 'Chưa hoàn thành (Chưa dự thi)'
        END AS trang_thai_hoan_thanh,
        COALESCE(lsr.diem_rot_cao_nhat, -1) AS diem_cao_nhat,
        COALESCE(lsr.so_lan_rot, 0)::BIGINT AS so_lan_thi_rot,
        COALESCE(lsr.chuoi_lich_su_rot, 'Chưa có lượt thi nào') AS chi_tiet_lan_rot
    FROM hoc_vien_khoa hvk
    CROSS JOIN cac_lop_mon_khoa clm
    LEFT JOIN mon_da_dat mdd ON hvk.ma_hv = mdd.ma_hv AND clm.ma_lop_mon = mdd.ma_lop_mon
    LEFT JOIN lich_su_thi_rot lsr ON hvk.ma_hv = lsr.ma_hv AND clm.ma_lop_mon = lsr.ma_lop_mon
    WHERE mdd.ma_lop_mon IS NULL
    ORDER BY hvk.ma_hv, clm.ma_mon;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_tinh_luong_giao_vien(
    p_thang INT,
    p_nam INT
)
RETURNS TABLE (
    ma_gv VARCHAR,
    ho_ten_gv VARCHAR,
    hoc_vi VARCHAR,
    loai_hop_dong VARCHAR,
    don_gia_tro_giang NUMERIC,
    gio_day_chinh BIGINT,
    gio_tro_giang BIGINT,
    tong_gio_day BIGINT,
    tien_day_chinh NUMERIC,
    tien_tro_giang NUMERIC,
    tong_luong NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH thoi_luong_day AS (
        SELECT 
            pc.ma_gv,
            SUM(CASE WHEN pc.vai_tro = 'GIANG_VIEN' THEN 2 ELSE 0 END)::BIGINT AS gio_chinh,
            SUM(CASE WHEN pc.vai_tro = 'TRO_GIANG' THEN 2 ELSE 0 END)::BIGINT AS gio_ta
        FROM buoi_hoc bh
        JOIN phan_cong_giang_day pc ON bh.ma_lop_mon = pc.ma_lop_mon
        WHERE EXTRACT(MONTH FROM bh.ngay_hoc) = p_thang
          AND EXTRACT(YEAR FROM bh.ngay_hoc) = p_nam
          AND bh.trang_thai = 'HOAN_THANH'
          AND bh.is_deleted = FALSE
          AND pc.is_deleted = FALSE
        GROUP BY pc.ma_gv
    )
    SELECT 
        gv.ma_gv,
        gv.ho_ten AS ho_ten_gv,
        gv.hoc_vi,
        gv.loai_hop_dong,
        gv.luong_tro_giang_gio AS don_gia_tro_giang,
        COALESCE(tld.gio_chinh, 0)::BIGINT AS gio_day_chinh,
        COALESCE(tld.gio_ta, 0)::BIGINT AS gio_tro_giang,
        (COALESCE(tld.gio_chinh, 0) + COALESCE(tld.gio_ta, 0))::BIGINT AS tong_gio_day,
        ROUND(COALESCE(tld.gio_chinh, 0) * (gv.luong_tro_giang_gio * 2.0), 2) AS tien_day_chinh,
        ROUND(COALESCE(tld.gio_ta, 0) * gv.luong_tro_giang_gio, 2) AS tien_tro_giang,
        ROUND(
            (COALESCE(tld.gio_chinh, 0) * (gv.luong_tro_giang_gio * 2.0)) + 
            (COALESCE(tld.gio_ta, 0) * gv.luong_tro_giang_gio), 
            2
        ) AS tong_luong
    FROM giao_vien gv
    JOIN thoi_luong_day tld ON gv.ma_gv = tld.ma_gv
    WHERE gv.is_deleted = FALSE
    ORDER BY tong_luong DESC;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_tinh_luong_nhan_vien()
RETURNS TABLE (
    ma_nv VARCHAR,
    ho_ten_nv VARCHAR,
    chuc_vu VARCHAR,
    luong_co_dinh NUMERIC,
    so_nv_cap_duoi BIGINT,
    phu_cap_quan_ly_nv NUMERIC,
    so_ctdt_quan_ly BIGINT,
    tong_so_hoc_vien_ctdt BIGINT,
    luong_quan_ly_ctdt NUMERIC,
    tong_thu_nhap NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH cap_duoi AS (
        SELECT nv.ma_nv_quan_ly, COUNT(*)::BIGINT AS so_luong
        FROM nhan_vien nv
        WHERE nv.is_deleted = FALSE 
          AND nv.trang_thai = 'DANG_LAM' 
          AND nv.ma_nv_quan_ly IS NOT NULL
        GROUP BY nv.ma_nv_quan_ly
    ),
    hoc_vien_chuong_trinh AS (
        SELECT 
            ct.ma_nv_quan_ly,
            COUNT(DISTINCT ct.ma_ctdt)::BIGINT AS so_chuong_trinh,
            COUNT(DISTINCT dk.ma_hv)::BIGINT AS tong_hv,
            SUM(COALESCE(ct.phu_cap_ql_moi_hv, 50000)) AS tong_phu_cap
        FROM chuong_trinh_dao_tao ct
        LEFT JOIN khoa_dao_tao kdt ON ct.ma_ctdt = kdt.ma_ctdt AND kdt.is_deleted = FALSE
        LEFT JOIN dang_ky_khoa_hoc dk ON kdt.ma_khoa = dk.ma_khoa AND dk.is_deleted = FALSE
        WHERE ct.is_deleted = FALSE
        GROUP BY ct.ma_nv_quan_ly
    )
    SELECT 
        nv.ma_nv,
        nv.ho_ten AS ho_ten_nv,
        nv.chuc_vu,
        nv.luong_co_dinh,
        COALESCE(cd.so_luong, 0)::BIGINT AS so_nv_cap_duoi,
        ROUND(COALESCE(cd.so_luong, 0) * (0.05 * nv.luong_co_dinh), 2) AS phu_cap_quan_ly_nv,
        COALESCE(hvct.so_chuong_trinh, 0)::BIGINT AS so_ctdt_quan_ly,
        COALESCE(hvct.tong_hv, 0)::BIGINT AS tong_so_hoc_vien_ctdt,
        ROUND(COALESCE(hvct.tong_hv, 0) * 50000.0, 2) AS luong_quan_ly_ctdt,
        ROUND(
            nv.luong_co_dinh + 
            (COALESCE(cd.so_luong, 0) * 0.05 * nv.luong_co_dinh) + 
            (COALESCE(hvct.tong_hv, 0) * 50000.0), 
            2
        ) AS tong_thu_nhap
    FROM nhan_vien nv
    LEFT JOIN cap_duoi cd ON nv.ma_nv = cd.ma_nv_quan_ly
    LEFT JOIN hoc_vien_chuong_trinh hvct ON nv.ma_nv = hvct.ma_nv_quan_ly
    WHERE nv.is_deleted = FALSE AND nv.trang_thai = 'DANG_LAM'
    ORDER BY tong_thu_nhap DESC;
END;
$$ LANGUAGE plpgsql;


-- =========================================================================
-- PHẦN 4: CÁC VIEWS BÁO CÁO THỐNG KÊ NGHIỆP VỤ
-- =========================================================================

CREATE OR REPLACE VIEW v_thong_ke_khoa_dao_tao AS
SELECT 
    kdt.ma_khoa,
    kdt.ten_khoa,
    ctdt.ma_ctdt,
    ctdt.ten_ctdt,
    kh.ma_ky_hoc,
    kh.ten_ky_hoc,
    kdt.ngay_bat_dau,
    kdt.ngay_ket_thuc,
    COUNT(DISTINCT lm.ma_lop_mon) AS so_lop_mon,
    COUNT(DISTINCT dk.ma_hv) AS so_hoc_vien_dang_ky,
    COALESCE(SUM(dk.hoc_phi_da_dong), 0) AS tong_hoc_phi_thu_duoc,
    kdt.trang_thai
FROM khoa_dao_tao kdt
JOIN chuong_trinh_dao_tao ctdt ON kdt.ma_ctdt = ctdt.ma_ctdt
JOIN ky_hoc kh ON kdt.ma_ky_hoc = kh.ma_ky_hoc
LEFT JOIN lop_mon_hoc lm ON kdt.ma_khoa = lm.ma_khoa AND lm.is_deleted = FALSE
LEFT JOIN dang_ky_khoa_hoc dk ON kdt.ma_khoa = dk.ma_khoa AND dk.is_deleted = FALSE
WHERE kdt.is_deleted = FALSE
GROUP BY kdt.ma_khoa, kdt.ten_khoa, ctdt.ma_ctdt, ctdt.ten_ctdt, kh.ma_ky_hoc, kh.ten_ky_hoc, kdt.ngay_bat_dau, kdt.ngay_ket_thuc, kdt.trang_thai;


CREATE OR REPLACE VIEW v_tong_quan_lich_giang_day AS
WITH giang_vien_lop AS (
    SELECT 
        pc.ma_lop_mon,
        MAX(CASE WHEN pc.vai_tro = 'GIANG_VIEN' THEN gv.ho_ten END) AS giang_vien_chinh,
        MAX(CASE WHEN pc.vai_tro = 'GIANG_VIEN' THEN gv.ma_gv END) AS ma_gv_chinh,
        MAX(CASE WHEN pc.vai_tro = 'TRO_GIANG' THEN gv.ho_ten END) AS tro_giang,
        MAX(CASE WHEN pc.vai_tro = 'TRO_GIANG' THEN gv.ma_gv END) AS ma_tro_giang
    FROM phan_cong_giang_day pc
    JOIN giao_vien gv ON pc.ma_gv = gv.ma_gv
    WHERE pc.is_deleted = FALSE
    GROUP BY pc.ma_lop_mon
)
SELECT 
    bh.ma_buoi,
    bh.thu_tu_buoi,
    bh.ngay_hoc,
    bh.gio_bat_dau,
    bh.gio_ket_thuc,
    lm.ma_lop_mon,
    mh.ma_mon,
    mh.ten_mon,
    kdt.ten_khoa,
    ph.ma_phong,
    ph.ten_phong,
    ph.vi_tri AS vi_tri_phong,
    gvl.giang_vien_chinh,
    gvl.ma_gv_chinh,
    gvl.tro_giang,
    gvl.ma_tro_giang,
    bh.trang_thai AS trang_thai_buoi
FROM buoi_hoc bh
JOIN lop_mon_hoc lm ON bh.ma_lop_mon = lm.ma_lop_mon
JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
JOIN khoa_dao_tao kdt ON lm.ma_khoa = kdt.ma_khoa
JOIN phong_hoc ph ON bh.ma_phong = ph.ma_phong
LEFT JOIN giang_vien_lop gvl ON lm.ma_lop_mon = gvl.ma_lop_mon
WHERE bh.is_deleted = FALSE;


CREATE OR REPLACE VIEW v_ty_le_dat_mon_hoc AS
WITH diem_moi_nhat AS (
    SELECT 
        kq.ma_lop_mon,
        kq.ma_hv,
        kq.diem_thi,
        kq.ket_qua,
        ROW_NUMBER() OVER (PARTITION BY kq.ma_lop_mon, kq.ma_hv ORDER BY kq.lan_thi DESC) as rn
    FROM ket_qua_thi kq
    WHERE kq.is_deleted = FALSE
)
SELECT 
    lm.ma_lop_mon,
    mh.ma_mon,
    mh.ten_mon,
    kdt.ten_khoa,
    COUNT(dmn.ma_hv) AS tong_so_hv_du_thi,
    COUNT(CASE WHEN dmn.diem_thi > 5.0 THEN 1 END) AS so_hv_dat,
    COUNT(CASE WHEN dmn.diem_thi <= 5.0 THEN 1 END) AS so_hv_chua_dat,
    ROUND(
        (COUNT(CASE WHEN dmn.diem_thi > 5.0 THEN 1 END)::NUMERIC / NULLIF(COUNT(dmn.ma_hv), 0)) * 100, 
        2
    ) AS ty_le_dat_phan_tram
FROM lop_mon_hoc lm
JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
JOIN khoa_dao_tao kdt ON lm.ma_khoa = kdt.ma_khoa
LEFT JOIN diem_moi_nhat dmn ON lm.ma_lop_mon = dmn.ma_lop_mon AND dmn.rn = 1
WHERE lm.is_deleted = FALSE
GROUP BY lm.ma_lop_mon, mh.ma_mon, mh.ten_mon, kdt.ten_khoa;


CREATE OR REPLACE VIEW v_phan_cap_nhan_su AS
SELECT 
    nv.ma_nv,
    nv.ho_ten,
    CASE nv.gioi_tinh WHEN 0 THEN 'Nữ' WHEN 1 THEN 'Nam' ELSE 'Khác' END AS gioi_tinh_hien_thi,
    nv.chuc_vu,
    nv.luong_co_dinh,
    nv.ngay_vao_lam,
    nv.ma_nv_quan_ly,
    ql.ho_ten AS ho_ten_nguoi_quan_ly,
    ql.chuc_vu AS chuc_vu_nguoi_quan_ly,
    nv.trang_thai
FROM nhan_vien nv
LEFT JOIN nhan_vien ql ON nv.ma_nv_quan_ly = ql.ma_nv
WHERE nv.is_deleted = FALSE;


-- =========================================================================
-- PHẦN 5: CHÈN BỘ DỮ LIỆU MẪU MỞ RỘNG (SEED DATA)
-- =========================================================================

INSERT INTO nhan_vien (ma_nv, ho_ten, gioi_tinh, ngay_sinh, cccd, so_dien_thoai, email, chuc_vu, ngay_vao_lam, luong_co_dinh, ma_nv_quan_ly, trang_thai)
VALUES 
('NV01', 'TS. Nguyễn Văn Hùng', 1, '1980-05-15', '001080001234', '0901234567', 'hung.nv@ptit.edu.vn', 'Giám đốc Trung tâm', '2020-01-01', 5000000, NULL, 'DANG_LAM'),
('NV02', 'ThS. Lê Thị Bình', 0, '1986-09-20', '001186002345', '0912345678', 'binh.lt@ptit.edu.vn', 'Trưởng phòng Đào tạo', '2021-03-15', 5000000, 'NV01', 'DANG_LAM'),
('NV03', 'ThS. Trần Quốc Bảo', 1, '1988-11-10', '001088003456', '0923456789', 'bao.tq@ptit.edu.vn', 'Trưởng phòng Khảo thí & ĐBCL', '2021-06-01', 5000000, 'NV01', 'DANG_LAM'),
('NV04', 'Hoàng Thu Trang', 0, '1995-12-05', '001195004567', '0934567890', 'trang.ht@ptit.edu.vn', 'Chuyên viên Quản lý CTĐT Data', '2022-08-01', 5000000, 'NV02', 'DANG_LAM'),
('NV05', 'Phạm Minh Đức', 1, '1994-07-25', '001094005678', '0945678901', 'duc.pm@ptit.edu.vn', 'Chuyên viên Quản lý CTĐT Web', '2022-10-15', 5000000, 'NV02', 'DANG_LAM'),
('NV06', 'Vũ Thị Mai', 0, '1997-03-18', '001197006789', '0956789012', 'mai.vt@ptit.edu.vn', 'Chuyên viên Quản lý CTĐT AI', '2023-02-01', 5000000, 'NV03', 'DANG_LAM');

INSERT INTO chuong_trinh_dao_tao (ma_ctdt, ten_ctdt, mo_ta, phu_cap_ql_moi_hv, ma_nv_quan_ly, trang_thai)
VALUES 
('CT01', 'Khoa Học Dữ Liệu & Phân Tích Chuyên Sâu', 'Chương trình đào tạo phân tích dữ liệu ứng dụng SQL, Python và PowerBI', 60000, 'NV04', 'DANG_MO'),
('CT02', 'Lập Trình Web Fullstack Chuyên Nghiệp', 'Chương trình đào tạo lập trình Frontend và Backend với Next.js & Spring Boot', 50000, 'NV05', 'DANG_MO'),
('CT03', 'Trí Tuệ Nhân Tạo & Học Máy Ứng Dụng', 'Chương trình đào tạo AI ứng dụng chuyên sâu cho kỹ sư phần mềm', 70000, 'NV06', 'DANG_MO');

INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, mo_ta, ma_ctdt, loai_mon)
VALUES 
('CT01-M01', 'Cơ sở dữ liệu Nâng cao & SQL For Analytics', 24, 'Thiết kế CSDL quan hệ, tối ưu truy vấn SQL, PL/pgSQL', 'CT01', 'BAT_BUOC'),
('CT01-M02', 'Lập trình Python cho Khoa học Dữ liệu', 30, 'Cú pháp Python, thư viện NumPy, Pandas, làm sạch dữ liệu', 'CT01', 'BAT_BUOC'),
('CT01-M03', 'Trực quan hóa Dữ liệu với PowerBI', 20, 'Thiết kế Dashboard báo cáo kinh doanh thông minh', 'CT01', 'BAT_BUOC'),
('CT02-M01', 'Lập trình Web Frontend Hiện Đại (Next.js/React)', 30, 'React hooks, Next.js Server Components, Tailwind CSS', 'CT02', 'BAT_BUOC'),
('CT02-M02', 'Lập trình Backend RESTful API & Microservices', 30, 'Xây dựng API bảo mật, xử lý xác thực JWT, cơ chế Cache', 'CT02', 'BAT_BUOC'),
('CT02-M03', 'Triển khai DevOps & CI/CD Cloud', 20, 'Container hóa Docker, tự động hóa quy trình với GitHub Actions', 'CT02', 'BAT_BUOC'),
('CT03-M01', 'Toán ứng dụng cho Machine Learning', 24, 'Đại số tuyến tính, giải tích và xác suất thống kê cho AI', 'CT03', 'BAT_BUOC'),
('CT03-M02', 'Học máy Cơ bản & Nâng cao (Scikit-Learn)', 36, 'Các thuật toán hồi quy, phân loại, gom cụm và đánh giá mô hình', 'CT03', 'BAT_BUOC');

INSERT INTO ky_hoc (ma_ky_hoc, ten_ky_hoc, nam_hoc, tu_ngay, den_ngay, trang_thai)
VALUES 
('2026HK1', 'Học kỳ 1 Năm 2026', '2025-2026', '2026-08-15', '2026-12-31', 'DANG_DIEN_RA'),
('2026HK2', 'Học kỳ 2 Năm 2026', '2026-2027', '2027-01-15', '2027-05-30', 'SAP_MO');

INSERT INTO khoa_dao_tao (ma_khoa, ten_khoa, ngay_bat_dau, ngay_ket_thuc, ma_ctdt, ma_ky_hoc, trang_thai)
VALUES 
('CT01-2026HK1-K01', 'Khóa 01 - Khoa Học Dữ Liệu (Mùa Thu 2026)', '2026-09-01', '2026-12-15', 'CT01', '2026HK1', 'DANG_HOC'),
('CT02-2026HK1-K01', 'Khóa 01 - Fullstack Web Developer (Mùa Thu 2026)', '2026-09-01', '2026-12-20', 'CT02', '2026HK1', 'DANG_HOC'),
('CT03-2026HK1-K01', 'Khóa 01 - AI & Machine Learning (Mùa Thu 2026)', '2026-09-15', '2026-12-30', 'CT03', '2026HK1', 'DANG_HOC');

INSERT INTO hoc_vien (ma_hv, ho_ten, ngay_sinh, gioi_tinh, so_dien_thoai, email, dia_chi, trang_thai)
VALUES 
('HV001', 'Trần Tuấn Dũng', '2002-04-12', 1, '0981112233', 'dung.tt@gmail.com', 'Số 10 Hà Đông, Hà Nội', 'DANG_HOC'),
('HV002', 'Nguyễn Phương Thảo', '2003-08-25', 0, '0982223344', 'thao.np@gmail.com', 'Số 25 Cầu Giấy, Hà Nội', 'DANG_HOC'),
('HV003', 'Trịnh Bảo Ngọc', '2004-09-18', 0, '0983334455', 'ngoc.tb@gmail.com', 'Số 88 Thanh Xuân, Hà Nội', 'DANG_HOC'),
('HV004', 'Đặng Quốc Huy', '2001-12-05', 1, '0984445566', 'huy.dq@gmail.com', 'Số 15 Hai Bà Trưng, Hà Nội', 'DANG_HOC'),
('HV005', 'Vũ Hoàng Nam', '2002-06-30', 1, '0985556677', 'nam.vh@gmail.com', 'Số 42 Đống Đa, Hà Nội', 'DANG_HOC'),
('HV006', 'Phạm Khánh Linh', '2003-01-14', 0, '0986667788', 'linh.pk@gmail.com', 'Số 60 Ba Đình, Hà Nội', 'DANG_HOC'),
('HV007', 'Ngô Quang Khải', '2000-11-22', 1, '0987778899', 'khai.nq@gmail.com', 'Số 77 Hoàng Mai, Hà Nội', 'DANG_HOC'),
('HV008', 'Bùi Quỳnh Anh', '2004-03-08', 0, '0988889900', 'anh.bq@gmail.com', 'Số 12 Nam Từ Liêm, Hà Nội', 'DANG_HOC');

INSERT INTO dang_ky_khoa_hoc (ma_hv, ma_khoa, ngay_dang_ky, hoc_phi_da_dong, trang_thai)
VALUES 
('HV001', 'CT01-2026HK1-K01', '2026-08-20 09:30:00', 8500000, 'DANG_HOC'),
('HV002', 'CT01-2026HK1-K01', '2026-08-21 14:15:00', 8500000, 'DANG_HOC'),
('HV003', 'CT01-2026HK1-K01', '2026-08-22 10:00:00', 8500000, 'DANG_HOC'),
('HV004', 'CT01-2026HK1-K01', '2026-08-23 16:45:00', 8500000, 'DANG_HOC'),
('HV004', 'CT02-2026HK1-K01', '2026-08-24 11:00:00', 9000000, 'DANG_HOC'),
('HV005', 'CT02-2026HK1-K01', '2026-08-25 08:30:00', 9000000, 'DANG_HOC'),
('HV006', 'CT02-2026HK1-K01', '2026-08-26 15:20:00', 9000000, 'DANG_HOC'),
('HV007', 'CT03-2026HK1-K01', '2026-09-01 10:30:00', 12000000, 'DANG_HOC'),
('HV008', 'CT03-2026HK1-K01', '2026-09-02 14:00:00', 12000000, 'DANG_HOC');

INSERT INTO giao_vien (ma_gv, ho_ten, cccd, so_dien_thoai, email, chuyen_mon, hoc_vi, luong_tro_giang_gio, loai_hop_dong, trang_thai)
VALUES 
('GV01', 'TS. Nguyễn Văn An', '001075001111', '0911001122', 'an.nv@lecturer.ptit.edu.vn', 'Cơ sở dữ liệu & Data Engineering', 'Tiến sĩ', 120000, 'FULLTIME', 'DANG_DAY'),
('GV02', 'ThS. Trần Thị Mai', '001185002222', '0922002233', 'mai.tt@lecturer.ptit.edu.vn', 'Khoa học Dữ liệu & Python', 'Thạc sĩ', 100000, 'PARTTIME', 'DANG_DAY'),
('GV03', 'ThS. Lê Hoàng Long', '001088003333', '0933003344', 'long.lh@lecturer.ptit.edu.vn', 'Lập trình Web & Cloud Computing', 'Thạc sĩ', 110000, 'FULLTIME', 'DANG_DAY'),
('GV04', 'KS. Phạm Hải Đăng', '001096004444', '0944004455', 'dang.ph@assistant.ptit.edu.vn', 'Trợ giảng Data & Python', 'Kỹ sư', 90000, 'PARTTIME', 'DANG_DAY'),
('GV05', 'KS. Vũ Thu Hà', '001198005555', '0955005566', 'ha.vt@assistant.ptit.edu.vn', 'Trợ giảng Web Frontend & Backend', 'Kỹ sư', 85000, 'PARTTIME', 'DANG_DAY'),
('GV06', 'TS. Đỗ Gia Huy', '001079006666', '0966006677', 'huy.dg@lecturer.ptit.edu.vn', 'Trí tuệ nhân tạo & Deep Learning', 'Tiến sĩ', 150000, 'FULLTIME', 'DANG_DAY');

INSERT INTO lop_mon_hoc (ma_lop_mon, ma_khoa, ma_mon, trang_thai)
VALUES 
('LM_CT01_K01_M01', 'CT01-2026HK1-K01', 'CT01-M01', 'DANG_HOC'),
('LM_CT01_K01_M02', 'CT01-2026HK1-K01', 'CT01-M02', 'DANG_HOC'),
('LM_CT01_K01_M03', 'CT01-2026HK1-K01', 'CT01-M03', 'SAP_MO'),
('LM_CT02_K01_M01', 'CT02-2026HK1-K01', 'CT02-M01', 'DANG_HOC'),
('LM_CT02_K01_M02', 'CT02-2026HK1-K01', 'CT02-M02', 'DANG_HOC'),
('LM_CT02_K01_M03', 'CT02-2026HK1-K01', 'CT02-M03', 'SAP_MO'),
('LM_CT03_K01_M01', 'CT03-2026HK1-K01', 'CT03-M01', 'DANG_HOC'),
('LM_CT03_K01_M02', 'CT03-2026HK1-K01', 'CT03-M02', 'SAP_MO');

INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro, ngay_phan_cong)
VALUES 
('LM_CT01_K01_M01', 'GV01', 'GIANG_VIEN', '2026-08-28'),
('LM_CT01_K01_M01', 'GV04', 'TRO_GIANG', '2026-08-28'),
('LM_CT01_K01_M02', 'GV02', 'GIANG_VIEN', '2026-08-28'),
('LM_CT01_K01_M02', 'GV04', 'TRO_GIANG', '2026-08-28'),
('LM_CT02_K01_M01', 'GV03', 'GIANG_VIEN', '2026-08-29'),
('LM_CT02_K01_M01', 'GV05', 'TRO_GIANG', '2026-08-29'),
('LM_CT03_K01_M01', 'GV06', 'GIANG_VIEN', '2026-09-05');

INSERT INTO phong_hoc (ma_phong, ten_phong, vi_tri, suc_chua, loai_phong, trang_thai, mo_ta)
VALUES 
('LAB_301', 'Phòng Thực Hành Lab 301', 'Tòa A2 - Tầng 3', 40, 'THUC_HANH_LAB', 'SAN_SANG', '40 máy tính cấu hình cao Intel i7, 32GB RAM'),
('LAB_302', 'Phòng Thực Hành Lab 302', 'Tòa A2 - Tầng 3', 35, 'THUC_HANH_LAB', 'SAN_SANG', '35 máy tính thực hành Web & Data'),
('P_201', 'Phòng Lý Thuyết Đa Năng 201', 'Tòa A1 - Tầng 2', 50, 'LY_THUYET', 'SAN_SANG', 'Trang bị máy chiếu 4K và điều hòa trung tâm'),
('P_202', 'Phòng Lý Thuyết 202', 'Tòa A1 - Tầng 2', 45, 'LY_THUYET', 'SAN_SANG', 'Phòng học tiêu chuẩn có âm thanh micro'),
('HT_A', 'Hội Trường Lớn Khu A', 'Tòa A1 - Tầng 1', 150, 'HOI_TRUONG', 'SAN_SANG', 'Tổ chức hội thảo và các kỳ thi tập trung');

INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
VALUES 
('LM_CT01_K01_M01', 1, '2026-09-02', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 2, '2026-09-05', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 3, '2026-09-09', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 4, '2026-09-12', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 5, '2026-09-16', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 6, '2026-09-19', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M02', 1, '2026-09-03', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT01_K01_M02', 2, '2026-09-07', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT01_K01_M02', 3, '2026-09-10', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT01_K01_M02', 4, '2026-09-14', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT02_K01_M01', 1, '2026-09-04', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT02_K01_M01', 2, '2026-09-08', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT02_K01_M01', 3, '2026-09-11', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT02_K01_M01', 4, '2026-09-15', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT03_K01_M01', 1, '2026-09-18', '08:00:00', '10:00:00', 'P_201', 'HOAN_THANH'),
('LM_CT03_K01_M01', 2, '2026-09-22', '08:00:00', '10:00:00', 'P_201', 'HOAN_THANH');

INSERT INTO ket_qua_thi (ma_hv, ma_lop_mon, lan_thi, ngay_thi, diem_thi, ghi_chu)
VALUES 
('HV001', 'LM_CT01_K01_M01', 1, '2026-09-25', 8.5, 'Thi lần đầu đạt loại giỏi'),
('HV001', 'LM_CT01_K01_M02', 1, '2026-09-26', 4.0, 'Thi lần đầu chưa đạt lý thuyết'),
('HV001', 'LM_CT01_K01_M02', 2, '2026-10-05', 7.5, 'Thi lại lần 2 đạt yêu cầu'),
('HV002', 'LM_CT01_K01_M01', 1, '2026-09-25', 3.5, 'Thi lần đầu bị rớt SQL tối ưu'),
('HV002', 'LM_CT01_K01_M01', 2, '2026-10-05', 4.5, 'Thi lại lần 2 vẫn chưa đạt 5.0'),
('HV003', 'LM_CT01_K01_M01', 1, '2026-09-25', 9.0, 'Điểm xuất sắc'),
('HV004', 'LM_CT01_K01_M01', 1, '2026-09-25', 6.0, 'Đạt'),
('HV004', 'LM_CT02_K01_M01', 1, '2026-09-28', 8.0, 'Đạt điểm cao phần React/Next.js'),
('HV005', 'LM_CT02_K01_M01', 1, '2026-09-28', 5.0, 'Thi lần 1 chưa đạt (5.0 <= 5)'),
('HV005', 'LM_CT02_K01_M01', 2, '2026-10-08', 7.0, 'Thi lại lần 2 đạt yêu cầu'),
('HV007', 'LM_CT03_K01_M01', 1, '2026-09-30', 8.5, 'Đạt điểm cao phần Đại số tuyến tính');


-- =========================================================================
-- PHẦN 6: 5 STORED PROCEDURES QUẢN LÝ GIAO DỊCH (TRANSACTIONS)
-- =========================================================================

-- PROCEDURE 1: Mở khóa đào tạo & Tự động tạo Lớp môn học
CREATE OR REPLACE PROCEDURE sp_mo_khoa_dao_tao_moi(
    p_ma_khoa VARCHAR,
    p_ten_khoa VARCHAR,
    p_ma_ctdt VARCHAR,
    p_ma_ky_hoc VARCHAR,
    p_ngay_bat_dau DATE,
    p_ngay_ket_thuc DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_mon RECORD;
    v_ma_lop_mon VARCHAR(40);
    v_so_mon_tao INT := 0;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM chuong_trinh_dao_tao WHERE ma_ctdt = p_ma_ctdt AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Chương trình đào tạo % không tồn tại.', p_ma_ctdt;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ky_hoc WHERE ma_ky_hoc = p_ma_ky_hoc AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Kỳ học % không tồn tại.', p_ma_ky_hoc;
    END IF;

    INSERT INTO khoa_dao_tao (ma_khoa, ten_khoa, ngay_bat_dau, ngay_ket_thuc, ma_ctdt, ma_ky_hoc, trang_thai)
    VALUES (p_ma_khoa, p_ten_khoa, p_ngay_bat_dau, p_ngay_ket_thuc, p_ma_ctdt, p_ma_ky_hoc, 'MO_DANG_KY');

    FOR v_mon IN 
        SELECT ma_mon 
        FROM mon_hoc 
        WHERE ma_ctdt = p_ma_ctdt AND is_deleted = FALSE
        ORDER BY ma_mon
    LOOP
        v_ma_lop_mon := ('LM_' || REPLACE(p_ma_khoa, '-', '_') || '_' || REPLACE(v_mon.ma_mon, '-', '_'));
        
        INSERT INTO lop_mon_hoc (ma_lop_mon, ma_khoa, ma_mon, trang_thai)
        VALUES (v_ma_lop_mon, p_ma_khoa, v_mon.ma_mon, 'SAP_MO');

        v_so_mon_tao := v_so_mon_tao + 1;
    END LOOP;

    RAISE NOTICE 'Giao dịch thành công: Đã mở khóa % và tự động tạo % lớp môn học.', p_ma_khoa, v_so_mon_tao;
END;
$$;

-- PROCEDURE 2: Đăng ký khóa học và đóng học phí
CREATE OR REPLACE PROCEDURE sp_dang_ky_khoa_hoc_va_dong_phi(
    p_ma_hv VARCHAR,
    p_ma_khoa VARCHAR,
    p_hoc_phi_dong NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hoc_vien WHERE ma_hv = p_ma_hv AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Học viên % không tồn tại.', p_ma_hv;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM khoa_dao_tao 
        WHERE ma_khoa = p_ma_khoa 
          AND trang_thai IN ('MO_DANG_KY', 'DANG_HOC') 
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Khóa đào tạo % hiện không ở trạng thái mở đăng ký.', p_ma_khoa;
    END IF;

    INSERT INTO dang_ky_khoa_hoc (ma_hv, ma_khoa, hoc_phi_da_dong, trang_thai)
    VALUES (p_ma_hv, p_ma_khoa, p_hoc_phi_dong, 'DANG_HOC')
    ON CONFLICT (ma_hv, ma_khoa) DO UPDATE 
    SET hoc_phi_da_dong = dang_ky_khoa_hoc.hoc_phi_da_dong + EXCLUDED.hoc_phi_da_dong,
        trang_thai = 'DANG_HOC',
        is_deleted = FALSE;

    UPDATE hoc_vien
    SET trang_thai = 'DANG_HOC',
        updated_at = CURRENT_TIMESTAMP
    WHERE ma_hv = p_ma_hv;

    RAISE NOTICE 'Giao dịch thành công: Học viên % đã đăng ký khóa % và nộp % VNĐ học phí.', p_ma_hv, p_ma_khoa, p_hoc_phi_dong;
END;
$$;

-- PROCEDURE 3: Phân công giáo viên và Sinh lịch học
CREATE OR REPLACE PROCEDURE sp_phan_cong_va_len_lich_buoi_hoc(
    p_ma_lop_mon VARCHAR,
    p_ma_gv_chinh VARCHAR,
    p_ma_gv_ta VARCHAR,
    p_ma_phong VARCHAR,
    p_ngay_bat_dau DATE,
    p_gio_bat_dau TIME,
    p_khoang_cach_ngay INT DEFAULT 3
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_so_buoi INT;
    v_i INT;
    v_ngay_hoc DATE;
BEGIN
    SELECT mh.so_buoi_hoc INTO v_so_buoi
    FROM lop_mon_hoc lm
    JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
    WHERE lm.ma_lop_mon = p_ma_lop_mon AND lm.is_deleted = FALSE;

    IF v_so_buoi IS NULL OR v_so_buoi <= 0 THEN
        RAISE EXCEPTION 'Lớp môn học % không hợp lệ hoặc chưa có số buổi học.', p_ma_lop_mon;
    END IF;

    INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro)
    VALUES (p_ma_lop_mon, p_ma_gv_chinh, 'GIANG_VIEN')
    ON CONFLICT (ma_lop_mon, ma_gv) DO UPDATE SET vai_tro = 'GIANG_VIEN', is_deleted = FALSE;

    IF p_ma_gv_ta IS NOT NULL AND p_ma_gv_ta <> '' THEN
        INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro)
        VALUES (p_ma_lop_mon, p_ma_gv_ta, 'TRO_GIANG')
        ON CONFLICT (ma_lop_mon, ma_gv) DO UPDATE SET vai_tro = 'TRO_GIANG', is_deleted = FALSE;
    END IF;

    v_ngay_hoc := p_ngay_bat_dau;
    FOR v_i IN 1..v_so_buoi LOOP
        INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
        VALUES (
            p_ma_lop_mon,
            v_i,
            v_ngay_hoc,
            p_gio_bat_dau,
            p_gio_bat_dau + INTERVAL '2 hours',
            p_ma_phong,
            'DA_LEN_LICH'
        );

        v_ngay_hoc := v_ngay_hoc + p_khoang_cach_ngay;
    END LOOP;

    UPDATE lop_mon_hoc SET trang_thai = 'DANG_HOC' WHERE ma_lop_mon = p_ma_lop_mon;

    RAISE NOTICE 'Giao dịch thành công: Đã phân công giáo viên và tạo % buổi học cho lớp %.', v_so_buoi, p_ma_lop_mon;
END;
$$;

-- PROCEDURE 4: Ghi nhận điểm thi & Tự động xét tốt nghiệp
CREATE OR REPLACE PROCEDURE sp_ghi_nhan_ket_qua_thi(
    p_ma_hv VARCHAR,
    p_ma_lop_mon VARCHAR,
    p_diem_thi NUMERIC,
    p_ngay_thi DATE,
    p_ghi_chu VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_lan_thi_moi INT;
    v_ma_khoa VARCHAR(40);
    v_so_mon_chua_dat INT;
BEGIN
    SELECT ma_khoa INTO v_ma_khoa
    FROM lop_mon_hoc
    WHERE ma_lop_mon = p_ma_lop_mon AND is_deleted = FALSE;

    SELECT COALESCE(MAX(lan_thi), 0) + 1 INTO v_lan_thi_moi
    FROM ket_qua_thi
    WHERE ma_hv = p_ma_hv AND ma_lop_mon = p_ma_lop_mon;

    INSERT INTO ket_qua_thi (ma_hv, ma_lop_mon, lan_thi, ngay_thi, diem_thi, ghi_chu)
    VALUES (p_ma_hv, p_ma_lop_mon, v_lan_thi_moi, p_ngay_thi, p_diem_thi, p_ghi_chu);

    WITH cac_lop_khoa AS (
        SELECT ma_lop_mon FROM lop_mon_hoc WHERE ma_khoa = v_ma_khoa AND is_deleted = FALSE
    ),
    mon_da_dat AS (
        SELECT DISTINCT kq.ma_lop_mon
        FROM ket_qua_thi kq
        JOIN cac_lop_khoa clk ON kq.ma_lop_mon = clk.ma_lop_mon
        WHERE kq.ma_hv = p_ma_hv AND kq.diem_thi > 5.0 AND kq.is_deleted = FALSE
    )
    SELECT COUNT(*) INTO v_so_mon_chua_dat
    FROM cac_lop_khoa clk
    LEFT JOIN mon_da_dat mdd ON clk.ma_lop_mon = mdd.ma_lop_mon
    WHERE mdd.ma_lop_mon IS NULL;

    IF v_so_mon_chua_dat = 0 THEN
        UPDATE dang_ky_khoa_hoc
        SET trang_thai = 'HOAN_THANH',
            updated_at = CURRENT_TIMESTAMP
        WHERE ma_hv = p_ma_hv AND ma_khoa = v_ma_khoa;

        RAISE NOTICE 'CHÚC MỪNG: Học viên % đã hoàn thành tất cả các môn và ĐẠT tốt nghiệp khóa đào tạo %!', p_ma_hv, v_ma_khoa;
    ELSE
        RAISE NOTICE 'Giao dịch thành công: Đã ghi nhận điểm lần % (% điểm) cho học viên %. (Còn % môn chưa đạt).',
            v_lan_thi_moi, p_diem_thi, p_ma_hv, v_so_mon_chua_dat;
    END IF;
END;
$$;

-- PROCEDURE 5: Chuyển khóa học và kết chuyển bảo lưu học phí
CREATE OR REPLACE PROCEDURE sp_chuyen_khoa_hoc_vien(
    p_ma_hv VARCHAR,
    p_ma_khoa_cu VARCHAR,
    p_ma_khoa_moi VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_hoc_phi_cu NUMERIC;
BEGIN
    SELECT hoc_phi_da_dong INTO v_hoc_phi_cu
    FROM dang_ky_khoa_hoc
    WHERE ma_hv = p_ma_hv AND ma_khoa = p_ma_khoa_cu AND is_deleted = FALSE;

    IF v_hoc_phi_cu IS NULL THEN
        RAISE EXCEPTION 'Học viên % chưa từng đăng ký khóa học cũ %.', p_ma_hv, p_ma_khoa_cu;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM khoa_dao_tao 
        WHERE ma_khoa = p_ma_khoa_moi 
          AND trang_thai IN ('MO_DANG_KY', 'DANG_HOC') 
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Khóa học mới % không ở trạng thái mở tiếp nhận học viên.', p_ma_khoa_moi;
    END IF;

    UPDATE dang_ky_khoa_hoc
    SET trang_thai = 'HUY',
        updated_at = CURRENT_TIMESTAMP
    WHERE ma_hv = p_ma_hv AND ma_khoa = p_ma_khoa_cu;

    INSERT INTO dang_ky_khoa_hoc (ma_hv, ma_khoa, hoc_phi_da_dong, trang_thai)
    VALUES (p_ma_hv, p_ma_khoa_moi, v_hoc_phi_cu, 'DANG_HOC')
    ON CONFLICT (ma_hv, ma_khoa) DO UPDATE 
    SET hoc_phi_da_dong = EXCLUDED.hoc_phi_da_dong,
        trang_thai = 'DANG_HOC',
        is_deleted = FALSE;

    RAISE NOTICE 'Giao dịch thành công: Đã chuyển học viên % từ khóa % sang khóa %, kết chuyển bảo lưu % VNĐ học phí.',
        p_ma_hv, p_ma_khoa_cu, p_ma_khoa_moi, v_hoc_phi_cu;
END;
$$;