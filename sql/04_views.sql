-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 4: CÁC VIEWS BÁO CÁO THỐNG KÊ NGHIỆP VỤ & TỔNG QUAN
-- =========================================================================

-- =========================================================================
-- 4.1. VIEW: Thống kê số lượng học viên và học phí theo Khóa đào tạo
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


-- =========================================================================
-- 4.2. VIEW: Tổng quan Lịch giảng dạy & Phòng học của các lớp môn học
-- =========================================================================
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


-- =========================================================================
-- 4.3. VIEW: Thống kê Tỷ lệ Đạt / Chưa đạt theo từng Lớp môn học
-- =========================================================================
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


-- =========================================================================
-- 4.4. VIEW: Danh sách phân cấp Quản lý Nhân sự
-- =========================================================================
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
