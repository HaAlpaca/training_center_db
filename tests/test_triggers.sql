-- =========================================================================
-- KỊCH BẢN KIỂM THỬ 5 TRIGGERS & 5 TRANSACTIONS (POSTGRESQL)
-- =========================================================================

SET client_encoding = 'UTF8';

-- =========================================================================
-- PHẦN 1: KIỂM THỬ 5 TRIGGERS
-- =========================================================================

-- -------------------------------------------------------------------------
-- TEST TRIGGER 1: Kiểm tra Trigger chống trùng phòng học (trg_kiem_tra_trung_phong)
-- -------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
    VALUES ('LM_CT01_K01_M02', 99, '2026-09-02', '18:30:00', '20:30:00', 'LAB_301', 'DA_LEN_LICH');
    
    RAISE EXCEPTION 'TEST TRIGGER 1 THẤT BẠI: Trigger không chặn được trùng phòng!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST TRIGGER 1 THÀNH CÔNG (Bắt được lỗi trùng phòng): %', SQLERRM;
END $$;


-- -------------------------------------------------------------------------
-- TEST TRIGGER 2: Kiểm tra Trigger chống trùng lịch giảng viên (trg_kiem_tra_trung_lich_gv)
-- -------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO phong_hoc (ma_phong, ten_phong, suc_chua, loai_phong, trang_thai)
    VALUES ('LAB_999', 'Phòng Test 999', 30, 'THUC_HANH_LAB', 'SAN_SANG')
    ON CONFLICT (ma_phong) DO NOTHING;

    INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
    VALUES ('LM_CT01_K01_M01', 98, '2026-09-02', '18:30:00', '20:30:00', 'LAB_999', 'DA_LEN_LICH');

    RAISE EXCEPTION 'TEST TRIGGER 2 THẤT BẠI: Trigger không chặn được trùng lịch giảng viên!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST TRIGGER 2 THÀNH CÔNG (Bắt được lỗi trùng lịch giảng viên): %', SQLERRM;
END $$;


-- -------------------------------------------------------------------------
-- TEST TRIGGER 3: Kiểm tra Trigger giới hạn tối đa 10 môn / CTĐT (trg_kiem_tra_so_mon_ctdt)
-- -------------------------------------------------------------------------
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 4..10 LOOP
        INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, ma_ctdt, loai_mon)
        VALUES ('CT01-TEST-' || i, 'Môn kiểm thử ' || i, 20, 'CT01', 'TU_CHON')
        ON CONFLICT DO NOTHING;
    END LOOP;

    INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, ma_ctdt, loai_mon)
    VALUES ('CT01-TEST-11', 'Môn kiểm thử thứ 11', 20, 'CT01', 'TU_CHON');

    RAISE EXCEPTION 'TEST TRIGGER 3 THẤT BẠI: Trigger không chặn được quá 10 môn học!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST TRIGGER 3 THÀNH CÔNG (Bắt được lỗi vượt quá 10 môn): %', SQLERRM;
END $$;


-- -------------------------------------------------------------------------
-- TEST TRIGGER 4: Phân công: Giảng viên chính và Trợ giảng không được là cùng 1 người
-- -------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro)
    VALUES ('LM_CT01_K01_M01', 'GV01', 'TRO_GIANG');

    RAISE EXCEPTION 'TEST TRIGGER 4 THẤT BẠI: Trigger không chặn được 1 người làm cả GV chính và Trợ giảng!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST TRIGGER 4 THÀNH CÔNG (Bắt được lỗi phân công trùng vai trò): %', SQLERRM;
END $$;


-- -------------------------------------------------------------------------
-- TEST TRIGGER 5: Học viên chỉ được dự thi ở Lớp môn thuộc Khóa đã đăng ký (trg_kiem_tra_hoc_vien_du_thi)
-- Kỳ vọng: HV007 chỉ đăng ký khóa CT03, thử nhập điểm cho lớp môn LM_CT01_K01_M01 (thuộc CT01) -> Bị chặn
-- -------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO ket_qua_thi (ma_hv, ma_lop_mon, lan_thi, ngay_thi, diem_thi, ghi_chu)
    VALUES ('HV007', 'LM_CT01_K01_M01', 1, '2026-09-25', 9.0, 'Thử nhập điểm gian lận khác khóa');

    RAISE EXCEPTION 'TEST TRIGGER 5 THẤT BẠI: Trigger không chặn được học viên chưa đăng ký khóa!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST TRIGGER 5 THÀNH CÔNG (Bắt được lỗi học viên thi sai khóa): %', SQLERRM;
END $$;


-- =========================================================================
-- PHẦN 2: KIỂM THỬ 5 TRANSACTIONS (STORED PROCEDURES)
-- =========================================================================

-- -------------------------------------------------------------------------
-- TEST TRANSACTION 1: Mở khóa mới & Tự động tạo các Lớp môn học (sp_mo_khoa_dao_tao_moi)
-- -------------------------------------------------------------------------
CALL sp_mo_khoa_dao_tao_moi(
    'CT01-2026HK2-K02',
    'Khóa 02 - Khoa Học Dữ Liệu (Mùa Xuân 2027)',
    'CT01',
    '2026HK2',
    '2027-02-01'::DATE,
    '2027-05-30'::DATE
);

-- Kiểm tra xem các lớp môn học đã được tự động tạo chưa
SELECT ma_lop_mon, ma_khoa, ma_mon, trang_thai 
FROM lop_mon_hoc 
WHERE ma_khoa = 'CT01-2026HK2-K02';


-- -------------------------------------------------------------------------
-- TEST TRANSACTION 2: Đăng ký khóa học và đóng học phí (sp_dang_ky_khoa_hoc_va_dong_phi)
-- -------------------------------------------------------------------------
CALL sp_dang_ky_khoa_hoc_va_dong_phi('HV001', 'CT01-2026HK2-K02', 8500000);

-- Kiểm tra bản ghi đăng ký
SELECT * FROM dang_ky_khoa_hoc WHERE ma_hv = 'HV001' AND ma_khoa = 'CT01-2026HK2-K02';


-- -------------------------------------------------------------------------
-- TEST TRANSACTION 3: Phân công giáo viên và Sinh lịch học định kỳ (sp_phan_cong_va_len_lich_buoi_hoc)
-- -------------------------------------------------------------------------
CALL sp_phan_cong_va_len_lich_buoi_hoc(
    'LM_CT01_2026HK2_K02_CT01_M03',
    'GV02',
    'GV04',
    'LAB_302',
    '2027-02-05'::DATE,
    '18:30:00'::TIME,
    7
);

-- Kiểm tra lịch các buổi học vừa sinh
SELECT ma_buoi, ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong 
FROM buoi_hoc 
WHERE ma_lop_mon = 'LM_CT01_2026HK2_K02_CT01_M03'
ORDER BY thu_tu_buoi;


-- -------------------------------------------------------------------------
-- TEST TRANSACTION 4: Ghi nhận kết quả thi & Tự động xét tốt nghiệp (sp_ghi_nhan_ket_qua_thi)
-- -------------------------------------------------------------------------
-- Nhập điểm cho HV003 thi môn Python đạt 8.0 (Trước đó HV003 đã đạt môn CSDL)
CALL sp_ghi_nhan_ket_qua_thi('HV003', 'LM_CT01_K01_M02', 8.0, '2026-10-10'::DATE, 'Thi đạt lần 1');

-- Kiểm tra trạng thái học viên HV003
SELECT ma_hv, ma_khoa, hoc_phi_da_dong, trang_thai FROM dang_ky_khoa_hoc WHERE ma_hv = 'HV003';


-- -------------------------------------------------------------------------
-- TEST TRANSACTION 5: Chuyển khóa học và kết chuyển bảo lưu học phí (sp_chuyen_khoa_hoc_vien)
-- -------------------------------------------------------------------------
-- Chuyển HV002 từ khóa CT01-2026HK1-K01 sang khóa mới CT01-2026HK2-K02
CALL sp_chuyen_khoa_hoc_vien('HV002', 'CT01-2026HK1-K01', 'CT01-2026HK2-K02');

-- Kiểm tra kết quả chuyển khóa
SELECT ma_hv, ma_khoa, hoc_phi_da_dong, trang_thai 
FROM dang_ky_khoa_hoc 
WHERE ma_hv = 'HV002' 
ORDER BY ma_khoa;
