-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 2: PL/PGSQL TRIGGERS KIỂM SOÁT 5 RÀNG BUỘC TOÀN VẸN NÂNG CAO
-- =========================================================================

-- =========================================================================
-- 2.1. TRIGGER 1: Mỗi Chương trình đào tạo chỉ có tối thiểu 1 và tối đa 10 môn học
-- =========================================================================
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


-- =========================================================================
-- 2.2. TRIGGER 2: Tránh xung đột trùng phòng học tại cùng một thời điểm
-- =========================================================================
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


-- =========================================================================
-- 2.3. TRIGGER 3: Tránh xung đột trùng lịch của Giáo viên (Giảng viên & Trợ giảng)
-- =========================================================================
CREATE OR REPLACE FUNCTION fn_kiem_tra_trung_lich_giao_vien()
RETURNS TRIGGER AS $$
DECLARE
    v_gv RECORD;
BEGIN
    -- Lấy danh sách giáo viên tham gia lớp môn học này
    FOR v_gv IN 
        SELECT ma_gv, vai_tro 
        FROM phan_cong_giang_day 
        WHERE ma_lop_mon = NEW.ma_lop_mon AND is_deleted = FALSE
    LOOP
        -- Kiểm tra xem giáo viên này có đang dạy buổi học nào khác trùng khung giờ không
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


-- =========================================================================
-- 2.4. TRIGGER 4: Giảng viên chính và Trợ giảng của cùng một lớp môn phải là 2 người khác nhau
-- =========================================================================
CREATE OR REPLACE FUNCTION fn_kiem_tra_phan_cong_giao_vien()
RETURNS TRIGGER AS $$
BEGIN
    -- Kiểm tra nếu lớp môn học đã có phân công vai trò khác với cùng 1 giáo viên
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

    -- Kiểm tra mỗi lớp chỉ có tối đa 1 GIANG_VIEN
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


-- =========================================================================
-- 2.5. TRIGGER 5: Học viên chỉ được dự thi ở Lớp môn học thuộc Khóa mà mình đã đăng ký
-- =========================================================================
CREATE OR REPLACE FUNCTION fn_kiem_tra_hoc_vien_du_thi()
RETURNS TRIGGER AS $$
DECLARE
    v_ma_khoa VARCHAR(40);
BEGIN
    -- Tìm mã khóa đào tạo của lớp môn học đang được ghi nhận điểm
    SELECT ma_khoa INTO v_ma_khoa
    FROM lop_mon_hoc
    WHERE ma_lop_mon = NEW.ma_lop_mon AND is_deleted = FALSE;

    IF v_ma_khoa IS NULL THEN
        RAISE EXCEPTION 'Lớp môn học % không tồn tại hoặc đã bị xóa.', NEW.ma_lop_mon;
    END IF;

    -- Kiểm tra xem học viên đã đăng ký khóa đào tạo này chưa
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
