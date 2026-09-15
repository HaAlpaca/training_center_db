-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 8: 5 STORED PROCEDURES QUẢN LÝ GIAO DỊCH NGHIỆP VỤ (TRANSACTIONS)
-- =========================================================================

-- =========================================================================
-- TRANSACTION 1: Mở khóa đào tạo mới & Tự động tạo đầy đủ các Lớp môn học
-- =========================================================================
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
    -- 1. Kiểm tra CTĐT và Kỳ học hợp lệ
    IF NOT EXISTS (SELECT 1 FROM chuong_trinh_dao_tao WHERE ma_ctdt = p_ma_ctdt AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Chương trình đào tạo % không tồn tại.', p_ma_ctdt;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ky_hoc WHERE ma_ky_hoc = p_ma_ky_hoc AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Kỳ học % không tồn tại.', p_ma_ky_hoc;
    END IF;

    -- 2. Thêm mới Khóa đào tạo
    INSERT INTO khoa_dao_tao (ma_khoa, ten_khoa, ngay_bat_dau, ngay_ket_thuc, ma_ctdt, ma_ky_hoc, trang_thai)
    VALUES (p_ma_khoa, p_ten_khoa, p_ngay_bat_dau, p_ngay_ket_thuc, p_ma_ctdt, p_ma_ky_hoc, 'MO_DANG_KY');

    -- 3. Tự động sinh tất cả các Lớp môn học thuộc CTĐT của Khóa
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


-- =========================================================================
-- TRANSACTION 2: Đăng ký khóa học và Ghi nhận đóng học phí
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_dang_ky_khoa_hoc_va_dong_phi(
    p_ma_hv VARCHAR,
    p_ma_khoa VARCHAR,
    p_hoc_phi_dong NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Kiểm tra học viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM hoc_vien WHERE ma_hv = p_ma_hv AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Học viên % không tồn tại.', p_ma_hv;
    END IF;

    -- 2. Kiểm tra khóa đào tạo có đang mở
    IF NOT EXISTS (
        SELECT 1 FROM khoa_dao_tao 
        WHERE ma_khoa = p_ma_khoa 
          AND trang_thai IN ('MO_DANG_KY', 'DANG_HOC') 
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Khóa đào tạo % hiện không ở trạng thái mở đăng ký.', p_ma_khoa;
    END IF;

    -- 3. Ghi nhận đăng ký khóa học
    INSERT INTO dang_ky_khoa_hoc (ma_hv, ma_khoa, hoc_phi_da_dong, trang_thai)
    VALUES (p_ma_hv, p_ma_khoa, p_hoc_phi_dong, 'DANG_HOC')
    ON CONFLICT (ma_hv, ma_khoa) DO UPDATE 
    SET hoc_phi_da_dong = dang_ky_khoa_hoc.hoc_phi_da_dong + EXCLUDED.hoc_phi_da_dong,
        trang_thai = 'DANG_HOC',
        is_deleted = FALSE;

    -- 4. Đảm bảo trạng thái học viên là DANG_HOC
    UPDATE hoc_vien
    SET trang_thai = 'DANG_HOC',
        updated_at = CURRENT_TIMESTAMP
    WHERE ma_hv = p_ma_hv;

    RAISE NOTICE 'Giao dịch thành công: Học viên % đã đăng ký khóa % và nộp % VNĐ học phí.', p_ma_hv, p_ma_khoa, p_hoc_phi_dong;
END;
$$;


-- =========================================================================
-- TRANSACTION 3: Phân công giáo viên và Sinh lịch học định kỳ trọn gói
-- =========================================================================
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
    -- 1. Kiểm tra Lớp môn học
    SELECT mh.so_buoi_hoc INTO v_so_buoi
    FROM lop_mon_hoc lm
    JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
    WHERE lm.ma_lop_mon = p_ma_lop_mon AND lm.is_deleted = FALSE;

    IF v_so_buoi IS NULL OR v_so_buoi <= 0 THEN
        RAISE EXCEPTION 'Lớp môn học % không hợp lệ hoặc chưa có số buổi học.', p_ma_lop_mon;
    END IF;

    -- 2. Phân công Giảng viên chính
    INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro)
    VALUES (p_ma_lop_mon, p_ma_gv_chinh, 'GIANG_VIEN')
    ON CONFLICT (ma_lop_mon, ma_gv) DO UPDATE SET vai_tro = 'GIANG_VIEN', is_deleted = FALSE;

    -- 3. Phân công Trợ giảng (nếu có)
    IF p_ma_gv_ta IS NOT NULL AND p_ma_gv_ta <> '' THEN
        INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro)
        VALUES (p_ma_lop_mon, p_ma_gv_ta, 'TRO_GIANG')
        ON CONFLICT (ma_lop_mon, ma_gv) DO UPDATE SET vai_tro = 'TRO_GIANG', is_deleted = FALSE;
    END IF;

    -- 4. Tự động sinh lịch các buổi học (Mỗi buổi 2 tiếng)
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

    -- 5. Cập nhật trạng thái lớp môn
    UPDATE lop_mon_hoc SET trang_thai = 'DANG_HOC' WHERE ma_lop_mon = p_ma_lop_mon;

    RAISE NOTICE 'Giao dịch thành công: Đã phân công giáo viên và tạo % buổi học cho lớp %.', v_so_buoi, p_ma_lop_mon;
END;
$$;


-- =========================================================================
-- TRANSACTION 4: Nhập điểm thi, tự tăng lần thi & Tự động xét tốt nghiệp khóa
-- =========================================================================
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
    -- 1. Lấy mã khóa đào tạo từ lớp môn học
    SELECT ma_khoa INTO v_ma_khoa
    FROM lop_mon_hoc
    WHERE ma_lop_mon = p_ma_lop_mon AND is_deleted = FALSE;

    -- 2. Tự động xác định số thứ tự lần thi tiếp theo
    SELECT COALESCE(MAX(lan_thi), 0) + 1 INTO v_lan_thi_moi
    FROM ket_qua_thi
    WHERE ma_hv = p_ma_hv AND ma_lop_mon = p_ma_lop_mon;

    -- 3. Ghi nhận điểm thi (Trigger trg_kiem_tra_hoc_vien_du_thi sẽ kiểm tra học viên đã đăng ký khóa chưa)
    INSERT INTO ket_qua_thi (ma_hv, ma_lop_mon, lan_thi, ngay_thi, diem_thi, ghi_chu)
    VALUES (p_ma_hv, p_ma_lop_mon, v_lan_thi_moi, p_ngay_thi, p_diem_thi, p_ghi_chu);

    -- 4. Kiểm tra xem học viên đã hoàn thành (đạt > 5.0) TẤT CẢ các môn của khóa đào tạo chưa
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

    -- 5. Nếu không còn môn nào chưa đạt -> Cập nhật tốt nghiệp khóa học
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


-- =========================================================================
-- TRANSACTION 5: Chuyển khóa đào tạo và Kết chuyển học phí bảo lưu
-- =========================================================================
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
    -- 1. Lấy thông tin học phí đã nộp từ khóa cũ
    SELECT hoc_phi_da_dong INTO v_hoc_phi_cu
    FROM dang_ky_khoa_hoc
    WHERE ma_hv = p_ma_hv AND ma_khoa = p_ma_khoa_cu AND is_deleted = FALSE;

    IF v_hoc_phi_cu IS NULL THEN
        RAISE EXCEPTION 'Học viên % chưa từng đăng ký khóa học cũ %.', p_ma_hv, p_ma_khoa_cu;
    END IF;

    -- 2. Kiểm tra khóa mới có mở không
    IF NOT EXISTS (
        SELECT 1 FROM khoa_dao_tao 
        WHERE ma_khoa = p_ma_khoa_moi 
          AND trang_thai IN ('MO_DANG_KY', 'DANG_HOC') 
          AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Khóa học mới % không ở trạng thái mở tiếp nhận học viên.', p_ma_khoa_moi;
    END IF;

    -- 3. Cập nhật trạng thái khóa cũ sang HUY
    UPDATE dang_ky_khoa_hoc
    SET trang_thai = 'HUY',
        updated_at = CURRENT_TIMESTAMP
    WHERE ma_hv = p_ma_hv AND ma_khoa = p_ma_khoa_cu;

    -- 4. Ghi nhận đăng ký khóa mới và kết chuyển toàn bộ học phí cũ sang
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
