-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- TẬP HỢP TẤT CẢ CÁC CÂU TRUY VẤN (SQL QUERIES) THEO 6 YÊU CẦU LỚN CỦA ĐỀ BÀI
-- =========================================================================

-- =========================================================================
-- YÊU CẦU 1: THỰC HIỆN CÁC CHỨC NĂNG THÊM / XOÁ / SỬA / TÌM KIẾM (CRUD)
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1.1. CHƯƠNG TRÌNH ĐÀO TẠO (CHUONG_TRINH_DAO_TAO)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm mới CTĐT
INSERT INTO chuong_trinh_dao_tao (ma_ctdt, ten_ctdt, mo_ta, phu_cap_ql_moi_hv, ma_nv_quan_ly, trang_thai)
VALUES ('CT04', 'An Toàn Thông Tin & An Ninh Mạng', 'Đào tạo kỹ sư an toàn thông tin chuyên sâu', 65000, 'NV02', 'DANG_MO');

-- [UPDATE] Sửa thông tin CTĐT
UPDATE chuong_trinh_dao_tao
SET ten_ctdt = 'An Toàn Thông Tin & Phòng Thủ Không Gian Mạng',
    phu_cap_ql_moi_hv = 70000,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_ctdt = 'CT04' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm CTĐT
UPDATE chuong_trinh_dao_tao
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_ctdt = 'CT04';

-- [SEARCH] Tìm kiếm CTĐT kèm họ tên nhân viên quản lý
SELECT 
    ct.ma_ctdt,
    ct.ten_ctdt,
    ct.phu_cap_ql_moi_hv,
    ct.trang_thai,
    nv.ho_ten AS ho_ten_nv_quan_ly,
    nv.email AS email_nv_quan_ly
FROM chuong_trinh_dao_tao ct
JOIN nhan_vien nv ON ct.ma_nv_quan_ly = nv.ma_nv
WHERE ct.is_deleted = FALSE
  AND (ct.ten_ctdt ILIKE '%Dữ liệu%' OR ct.ma_ctdt ILIKE '%CT01%')
ORDER BY ct.ma_ctdt;


-- -------------------------------------------------------------------------
-- 1.2. MÔN HỌC (MON_HOC)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm môn học mới (Mã môn chứa mã CTĐT, số giờ chẵn)
INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, mo_ta, ma_ctdt, loai_mon)
VALUES ('CT01-M04', 'Xử Lý Dữ Liệu Lớn với Apache Spark', 30, 'Phân tán dữ liệu trên cụm máy chủ Spark', 'CT01', 'TU_CHON');

-- [UPDATE] Sửa thời lượng môn học
UPDATE mon_hoc
SET tong_so_gio = 36,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_mon = 'CT01-M04' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm môn học
UPDATE mon_hoc
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_mon = 'CT01-M04';

-- [SEARCH] Tìm kiếm môn học theo tên và CTĐT
SELECT 
    mh.ma_mon,
    mh.ten_mon,
    ct.ten_ctdt,
    mh.tong_so_gio,
    mh.so_buoi_hoc,
    mh.loai_mon
FROM mon_hoc mh
JOIN chuong_trinh_dao_tao ct ON mh.ma_ctdt = ct.ma_ctdt
WHERE mh.is_deleted = FALSE
  AND mh.ma_ctdt = 'CT01'
ORDER BY mh.ma_mon;


-- -------------------------------------------------------------------------
-- 1.3. NHÂN VIÊN (NHAN_VIEN)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm nhân viên mới (có giới tính, CCCD, lương cố định)
INSERT INTO nhan_vien (ma_nv, ho_ten, gioi_tinh, ngay_sinh, cccd, so_dien_thoai, email, chuc_vu, ngay_vao_lam, luong_co_dinh, ma_nv_quan_ly, trang_thai)
VALUES ('NV07', 'Nguyễn Thị Hồng', 0, '1996-05-12', '001196007890', '0967890123', 'hong.nth@ptit.edu.vn', 'Chuyên viên Hỗ trợ Đào tạo', '2023-05-01', 5000000, 'NV02', 'DANG_LAM');

-- [UPDATE] Cập nhật chức vụ, số điện thoại
UPDATE nhan_vien
SET chuc_vu = 'Chuyên viên Chính Quản lý Đào tạo',
    so_dien_thoai = '0967890999',
    updated_at = CURRENT_TIMESTAMP
WHERE ma_nv = 'NV07' AND is_deleted = FALSE;

-- [DELETE] Cập nhật nhân viên thôi việc / Xóa mềm
UPDATE nhan_vien
SET trang_thai = 'DA_NGHI_VIEC',
    is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_nv = 'NV07';

-- [SEARCH] Tìm kiếm nhân viên kèm thông tin người quản lý trực tiếp
SELECT 
    nv.ma_nv,
    nv.ho_ten,
    CASE nv.gioi_tinh WHEN 0 THEN 'Nữ' WHEN 1 THEN 'Nam' ELSE 'Khác' END AS gioi_tinh,
    nv.cccd,
    nv.email,
    nv.chuc_vu,
    ql.ho_ten AS nguoi_quan_ly_truc_tiep,
    nv.luong_co_dinh
FROM nhan_vien nv
LEFT JOIN nhan_vien ql ON nv.ma_nv_quan_ly = ql.ma_nv
WHERE nv.is_deleted = FALSE
  AND (nv.ho_ten ILIKE '%Bình%' OR nv.chuc_vu ILIKE '%Trưởng phòng%')
ORDER BY nv.ma_nv;


-- -------------------------------------------------------------------------
-- 1.4. GIÁO VIÊN (GIAO_VIEN)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm giáo viên mới
INSERT INTO giao_vien (ma_gv, ho_ten, cccd, so_dien_thoai, email, chuyen_mon, hoc_vi, luong_tro_giang_gio, loai_hop_dong, trang_thai)
VALUES ('GV07', 'ThS. Chu Đức Trọng', '001089007777', '0977007788', 'trong.cd@lecturer.ptit.edu.vn', 'An ninh mạng & Hệ thống thông tin', 'Thạc sĩ', 115000, 'PARTTIME', 'DANG_DAY');

-- [UPDATE] Sửa học vị và lương chuẩn trợ giảng
UPDATE giao_vien
SET hoc_vi = 'Tiến sĩ',
    luong_tro_giang_gio = 135000,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_gv = 'GV07' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm giáo viên
UPDATE giao_vien
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_gv = 'GV07';

-- [SEARCH] Tìm kiếm giáo viên theo chuyên môn
SELECT 
    ma_gv,
    ho_ten,
    hoc_vi,
    chuyen_mon,
    luong_tro_giang_gio,
    (luong_tro_giang_gio * 2) AS don_gia_giang_vien_gio,
    loai_hop_dong
FROM giao_vien
WHERE is_deleted = FALSE
  AND (chuyen_mon ILIKE '%Dữ liệu%' OR hoc_vi = 'Tiến sĩ')
ORDER BY ma_gv;


-- -------------------------------------------------------------------------
-- 1.5. HỌC VIÊN (HOC_VIEN)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm học viên mới
INSERT INTO hoc_vien (ma_hv, ho_ten, ngay_sinh, gioi_tinh, so_dien_thoai, email, dia_chi, trang_thai)
VALUES ('HV009', 'Lê Quốc Tuấn', '2003-10-10', 1, '0989990011', 'tuan.lq@gmail.com', 'Số 99 Thanh Xuân, Hà Nội', 'DANG_HOC');

-- [UPDATE] Cập nhật thông tin liên hệ
UPDATE hoc_vien
SET so_dien_thoai = '0989990022',
    dia_chi = 'Số 100 Cầu Giấy, Hà Nội',
    updated_at = CURRENT_TIMESTAMP
WHERE ma_hv = 'HV009' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm học viên
UPDATE hoc_vien
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_hv = 'HV009';

-- [SEARCH] Tìm kiếm học viên
SELECT ma_hv, ho_ten, ngay_sinh, CASE gioi_tinh WHEN 0 THEN 'Nữ' WHEN 1 THEN 'Nam' ELSE 'Khác' END AS gioi_tinh, so_dien_thoai, email, dia_chi
FROM hoc_vien
WHERE is_deleted = FALSE
  AND (ho_ten ILIKE '%Dũng%' OR so_dien_thoai LIKE '%0981%')
ORDER BY ma_hv;


-- -------------------------------------------------------------------------
-- 1.6. PHÒNG HỌC (PHONG_HOC)
-- -------------------------------------------------------------------------

-- [CREATE] Thêm phòng học
INSERT INTO phong_hoc (ma_phong, ten_phong, vi_tri, suc_chua, loai_phong, trang_thai, mo_ta)
VALUES ('LAB_401', 'Phòng Lab Chuyên Dụng 401', 'Tòa A2 - Tầng 4', 40, 'THUC_HANH_LAB', 'SAN_SANG', 'Máy tính chuyên dụng xử lý AI GPU');

-- [UPDATE] Đưa phòng vào diện bảo trì
UPDATE phong_hoc
SET trang_thai = 'BAO_TRI',
    updated_at = CURRENT_TIMESTAMP
WHERE ma_phong = 'LAB_401' AND is_deleted = FALSE;

-- [DELETE] Xóa mềm phòng học
UPDATE phong_hoc
SET is_deleted = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE ma_phong = 'LAB_401';

-- [SEARCH] Tìm phòng học thực hành còn sẵn sàng
SELECT ma_phong, ten_phong, vi_tri, suc_chua, loai_phong, trang_thai
FROM phong_hoc
WHERE is_deleted = FALSE
  AND trang_thai = 'SAN_SANG'
  AND suc_chua >= 35
ORDER BY suc_chua DESC;


-- =========================================================================
-- YÊU CẦU 2: HIỂN THỊ KẾT QUẢ HỌC TẬP CỦA MỖI HỌC VIÊN
-- TRONG CÁC KHÓA ĐÀO TẠO ĐÃ THAM GIA / HOÀN THÀNH
-- =========================================================================

-- CÁCH 1: Truy vấn Raw SQL đầy đủ chi tiết điểm từng lần thi & điểm cao nhất
WITH diem_cao_nhat AS (
    SELECT 
        kq.ma_hv,
        kq.ma_lop_mon,
        MAX(kq.diem_thi) AS diem_cao_nhat,
        COUNT(kq.lan_thi) AS so_lan_thi
    FROM ket_qua_thi kq
    WHERE kq.is_deleted = FALSE
    GROUP BY kq.ma_hv, kq.ma_lop_mon
)
SELECT 
    hv.ma_hv,
    hv.ho_ten AS ho_ten_hoc_vien,
    kdt.ma_khoa,
    kdt.ten_khoa,
    mh.ma_mon,
    mh.ten_mon,
    dcn.so_lan_thi,
    dcn.diem_cao_nhat,
    CASE 
        WHEN dcn.diem_cao_nhat IS NULL THEN 'Chưa dự thi'
        WHEN dcn.diem_cao_nhat > 5.0 THEN 'ĐẠT'
        ELSE 'CHƯA ĐẠT'
    END AS trang_thai_mon
FROM hoc_vien hv
JOIN dang_ky_khoa_hoc dk ON hv.ma_hv = dk.ma_hv
JOIN khoa_dao_tao kdt ON dk.ma_khoa = kdt.ma_khoa
JOIN lop_mon_hoc lm ON kdt.ma_khoa = lm.ma_khoa
JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
LEFT JOIN diem_cao_nhat dcn ON hv.ma_hv = dcn.ma_hv AND lm.ma_lop_mon = dcn.ma_lop_mon
WHERE hv.is_deleted = FALSE AND dk.is_deleted = FALSE
ORDER BY hv.ma_hv, kdt.ma_khoa, mh.ma_mon;

-- CÁCH 2: Gọi Stored Function cho một học viên cụ thể
SELECT * FROM fn_bang_diem_hoc_vien('HV001');


-- =========================================================================
-- YÊU CẦU 3: LIỆT KÊ TOÀN BỘ CÁC HỌC VIÊN CHƯA HOÀN THÀNH XONG CÁC MÔN HỌC
-- CỦA KHÓA ĐÀO TẠO KÈM ĐIỂM THI CỦA CÁC LẦN DỰ THI CHƯA ĐẠT
-- =========================================================================

-- CÁCH 1: Gọi Stored Function lọc học viên chưa hoàn thành khóa CT01-2026HK1-K01
SELECT * FROM fn_hoc_vien_chua_hoan_thanh_khoa('CT01-2026HK1-K01');


-- =========================================================================
-- YÊU CẦU 4: TÍNH LƯƠNG CHO GIÁO VIÊN TRONG MỘT THÁNG
-- (Lương = Giờ dạy chính * (2 * Đơn giá TA) + Giờ trợ giảng * Đơn giá TA)
-- =========================================================================

-- CÁCH 1: Gọi Stored Function tính lương tháng 9/2026
SELECT * FROM fn_tinh_luong_giao_vien(9, 2026);


-- =========================================================================
-- YÊU CẦU 5: TÍNH LƯƠNG CHO CÁC NHÂN VIÊN
-- (Lương cứng 5tr + Thưởng quản lý CTĐT + 5% x số cấp dưới)
-- =========================================================================

-- CÁCH 1: Gọi Stored Function tính lương nhân viên
SELECT * FROM fn_tinh_luong_nhan_vien();


-- =========================================================================
-- YÊU CẦU 6: CÁC CÂU TRUY VẤN KIỂM TRA RÀNG BUỘC SỐ LƯỢNG BẢN GHI
-- (ỨNG DỤNG SỬ DỤNG ĐỂ VALIDATION TRƯỚC KHI THỰC HIỆN GIAO DỊCH)
-- =========================================================================

-- 6.1. Kiểm tra số lượng môn học trong một CTĐT trước khi thêm (Tối đa 10 môn)
SELECT 
    ma_ctdt,
    COUNT(*) AS so_mon_hien_tai,
    CASE 
        WHEN COUNT(*) >= 10 THEN 'BỊ CHẶN: Đã đủ tối đa 10 môn học'
        ELSE 'HỢP LỆ: Còn có thể thêm ' || (10 - COUNT(*)) || ' môn học'
    END AS ket_qua_kiem_tra
FROM mon_hoc
WHERE ma_ctdt = 'CT01' AND is_deleted = FALSE
GROUP BY ma_ctdt;

-- 6.2. Kiểm tra xung đột trùng phòng học trước khi xếp lịch buổi học mới
SELECT 
    ma_buoi,
    ma_lop_mon,
    ma_phong,
    ngay_hoc,
    gio_bat_dau,
    gio_ket_thuc
FROM buoi_hoc
WHERE ma_phong = 'LAB_301'
  AND ngay_hoc = '2026-09-02'
  AND trang_thai <> 'HUY_BUOI'
  AND is_deleted = FALSE
  -- Khung giờ dự kiến cần kiểm tra: '18:30:00' đến '20:30:00'
  AND gio_bat_dau < '20:30:00'
  AND gio_ket_thuc > '18:30:00';

-- 6.3. Kiểm tra xung đột trùng lịch giáo viên trước khi xếp lịch
SELECT 
    bh.ma_buoi,
    bh.ma_lop_mon,
    bh.ngay_hoc,
    bh.gio_bat_dau,
    bh.gio_ket_thuc,
    pc.ma_gv,
    pc.vai_tro
FROM buoi_hoc bh
JOIN phan_cong_giang_day pc ON bh.ma_lop_mon = pc.ma_lop_mon
WHERE pc.ma_gv = 'GV01'
  AND bh.ngay_hoc = '2026-09-02'
  AND bh.trang_thai <> 'HUY_BUOI'
  AND bh.is_deleted = FALSE
  -- Khung giờ dự kiến: '18:30:00' đến '20:30:00'
  AND bh.gio_bat_dau < '20:30:00'
  AND bh.gio_ket_thuc > '18:30:00';
