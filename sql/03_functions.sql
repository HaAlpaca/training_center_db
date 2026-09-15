-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 3: STORED FUNCTIONS XỬ LÝ NGHIỆP VỤ & TÍNH TOÁN LƯƠNG
-- =========================================================================

-- =========================================================================
-- 3.1. FUNCTION: Hiển thị kết quả học tập của từng học viên qua các lần thi
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


-- =========================================================================
-- 3.2. FUNCTION: Liệt kê các học viên chưa hoàn thành khóa đào tạo
-- (Kèm danh sách các môn chưa đạt và chi tiết lịch sử các lần thi rớt)
-- =========================================================================
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
        -- Tất cả các môn được triển khai trong khóa đào tạo
        SELECT lm.ma_lop_mon, lm.ma_khoa, lm.ma_mon, mh.ten_mon
        FROM lop_mon_hoc lm
        JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
        WHERE lm.ma_khoa = p_ma_khoa AND lm.is_deleted = FALSE
    ),
    hoc_vien_khoa AS (
        -- Tất cả học viên đã đăng ký khóa đào tạo
        SELECT dk.ma_hv, hv.ho_ten
        FROM dang_ky_khoa_hoc dk
        JOIN hoc_vien hv ON dk.ma_hv = hv.ma_hv
        WHERE dk.ma_khoa = p_ma_khoa AND dk.is_deleted = FALSE
    ),
    mon_da_dat AS (
        -- Các môn mà học viên ĐÃ THI ĐẠT (điểm > 5.0)
        SELECT DISTINCT kq.ma_hv, kq.ma_lop_mon
        FROM ket_qua_thi kq
        JOIN cac_lop_mon_khoa clm ON kq.ma_lop_mon = clm.ma_lop_mon
        WHERE kq.diem_thi > 5.0 AND kq.is_deleted = FALSE
    ),
    lich_su_thi_rot AS (
        -- Tổng hợp chuỗi các lần thi chưa đạt của học viên
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
    WHERE mdd.ma_lop_mon IS NULL -- Chỉ lấy những môn CHƯA ĐẠT
    ORDER BY hvk.ma_hv, clm.ma_mon;
END;
$$ LANGUAGE plpgsql;


-- =========================================================================
-- 3.3. FUNCTION: Tính lương Giáo viên theo tháng
-- (Giảng viên = 2 * LuongTroGiangGio; Trợ giảng = 1 * LuongTroGiangGio)
-- =========================================================================
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


-- =========================================================================
-- 3.4. FUNCTION: Tính lương Nhân viên theo quy tắc đề bài
-- (Lương cứng 5.000.000 + 5% x số cấp dưới + Lương quản lý CTĐT theo số học viên)
-- =========================================================================
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
