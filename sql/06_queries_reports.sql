-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 6: KỊCH BẢN TRUY VẤN MẪU & BÁO CÁO NGHIỆP VỤ (DEMO & TESTING)
-- =========================================================================

-- 1. Xem bảng điểm chi tiết của học viên qua các lần thi (Gọi Function)
SELECT * FROM fn_bang_diem_hoc_vien('HV001');

-- 2. Liệt kê các học viên chưa hoàn thành một khóa đào tạo kèm điểm thi rớt (Gọi Function)
SELECT * FROM fn_hoc_vien_chua_hoan_thanh_khoa('CT01-2026HK1-K01');

-- 3. Bảng tính thù lao giảng dạy của giáo viên trong tháng 09/2026 (Gọi Function)
SELECT * FROM fn_tinh_luong_giao_vien(9, 2026);

-- 4. Bảng lương nhân viên trung tâm kèm phụ cấp quản lý cấp dưới và CTĐT (Gọi Function)
SELECT * FROM fn_tinh_luong_nhan_vien();

-- 5. Xem báo cáo tổng hợp sĩ số và doanh thu các khóa đào tạo (Từ View)
SELECT * FROM v_thong_ke_khoa_dao_tao;

-- 6. Xem lịch giảng dạy chi tiết theo phòng và giáo viên (Từ View)
SELECT * FROM v_tong_quan_lich_giang_day;

-- 7. Xem thống kê tỷ lệ đạt của từng lớp môn học (Từ View)
SELECT * FROM v_ty_le_dat_mon_hoc;

-- 8. Xem danh sách phân cấp quản lý nhân sự (Từ View)
SELECT * FROM v_phan_cap_nhan_su;

-- 9. Truy vấn nâng cao: Top 3 học viên có điểm thi trung bình cao nhất
WITH diem_trung_binh_hv AS (
    SELECT 
        hv.ma_hv,
        hv.ho_ten,
        ROUND(AVG(kq.diem_thi), 2) AS diem_tb,
        DENSE_RANK() OVER (ORDER BY AVG(kq.diem_thi) DESC) AS xep_hang
    FROM hoc_vien hv
    JOIN ket_qua_thi kq ON hv.ma_hv = kq.ma_hv
    WHERE hv.is_deleted = FALSE AND kq.is_deleted = FALSE
    GROUP BY hv.ma_hv, hv.ho_ten
)
SELECT ma_hv, ho_ten, diem_tb, xep_hang
FROM diem_trung_binh_hv
WHERE xep_hang <= 3;
