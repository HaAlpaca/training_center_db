-- =========================================================================
-- HỆ CSDL QUẢN LÝ TRUNG TÂM ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL
-- PHẦN 5: DỮ LIỆU MẪU MỞ RỘNG (SEED DATA) BAO PHỦ TOÀN DIỆN MỘT HỌC KỲ
-- =========================================================================

SET client_encoding = 'UTF8';

-- Tắt kiểm tra trigger tạm thời khi chèn nếu cần thiết, hoặc chèn theo đúng thứ tự logic
-- =========================================================================
-- 1. CHÈN DỮ LIỆU: NHAN_VIEN (Cây phân cấp quản lý)
-- =========================================================================
-- STF01: Giám đốc (Cấp cao nhất, ma_nv_quan_ly là NULL hoặc tự quy ước)
INSERT INTO nhan_vien (ma_nv, ho_ten, gioi_tinh, ngay_sinh, cccd, so_dien_thoai, email, chuc_vu, ngay_vao_lam, luong_co_dinh, ma_nv_quan_ly, trang_thai)
VALUES 
('NV01', 'TS. Nguyễn Văn Hùng', 1, '1980-05-15', '001080001234', '0901234567', 'hung.nv@ptit.edu.vn', 'Giám đốc Trung tâm', '2020-01-01', 5000000, NULL, 'DANG_LAM');

-- STF02, STF03: Trưởng phòng / Quản lý (Được quản lý bởi NV01)
INSERT INTO nhan_vien (ma_nv, ho_ten, gioi_tinh, ngay_sinh, cccd, so_dien_thoai, email, chuc_vu, ngay_vao_lam, luong_co_dinh, ma_nv_quan_ly, trang_thai)
VALUES 
('NV02', 'ThS. Lê Thị Bình', 0, '1986-09-20', '001186002345', '0912345678', 'binh.lt@ptit.edu.vn', 'Trưởng phòng Đào tạo', '2021-03-15', 5000000, 'NV01', 'DANG_LAM'),
('NV03', 'ThS. Trần Quốc Bảo', 1, '1988-11-10', '001088003456', '0923456789', 'bao.tq@ptit.edu.vn', 'Trưởng phòng Khảo thí & ĐBCL', '2021-06-01', 5000000, 'NV01', 'DANG_LAM');

-- STF04, STF05, STF06: Chuyên viên giáo vụ (Được quản lý bởi NV02 và NV03)
INSERT INTO nhan_vien (ma_nv, ho_ten, gioi_tinh, ngay_sinh, cccd, so_dien_thoai, email, chuc_vu, ngay_vao_lam, luong_co_dinh, ma_nv_quan_ly, trang_thai)
VALUES 
('NV04', 'Hoàng Thu Trang', 0, '1995-12-05', '001195004567', '0934567890', 'trang.ht@ptit.edu.vn', 'Chuyên viên Quản lý CTĐT Data', '2022-08-01', 5000000, 'NV02', 'DANG_LAM'),
('NV05', 'Phạm Minh Đức', 1, '1994-07-25', '001094005678', '0945678901', 'duc.pm@ptit.edu.vn', 'Chuyên viên Quản lý CTĐT Web', '2022-10-15', 5000000, 'NV02', 'DANG_LAM'),
('NV06', 'Vũ Thị Mai', 0, '1997-03-18', '001197006789', '0956789012', 'mai.vt@ptit.edu.vn', 'Chuyên viên Quản lý CTĐT AI', '2023-02-01', 5000000, 'NV03', 'DANG_LAM');

-- =========================================================================
-- 2. CHÈN DỮ LIỆU: CHUONG_TRINH_DAO_TAO
-- =========================================================================
INSERT INTO chuong_trinh_dao_tao (ma_ctdt, ten_ctdt, mo_ta, phu_cap_ql_moi_hv, ma_nv_quan_ly, trang_thai)
VALUES 
('CT01', 'Khoa Học Dữ Liệu & Phân Tích Chuyên Sâu', 'Chương trình đào tạo phân tích dữ liệu ứng dụng SQL, Python và PowerBI', 60000, 'NV04', 'DANG_MO'),
('CT02', 'Lập Trình Web Fullstack Chuyên Nghiệp', 'Chương trình đào tạo lập trình Frontend và Backend với Next.js & Spring Boot', 50000, 'NV05', 'DANG_MO'),
('CT03', 'Trí Tuệ Nhân Tạo & Học Máy Ứng Dụng', 'Chương trình đào tạo AI ứng dụng chuyên sâu cho kỹ sư phần mềm', 70000, 'NV06', 'DANG_MO');

-- =========================================================================
-- 3. CHÈN DỮ LIỆU: MON_HOC (1 đến 10 môn cho mỗi CTĐT)
-- =========================================================================
INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, mo_ta, ma_ctdt, loai_mon)
VALUES 
-- Môn thuộc CT01 (Data Science)
('CT01-M01', 'Cơ sở dữ liệu Nâng cao & SQL For Analytics', 24, 'Thiết kế CSDL quan hệ, tối ưu truy vấn SQL, PL/pgSQL', 'CT01', 'BAT_BUOC'),
('CT01-M02', 'Lập trình Python cho Khoa học Dữ liệu', 30, 'Cú pháp Python, thư viện NumPy, Pandas, làm sạch dữ liệu', 'CT01', 'BAT_BUOC'),
('CT01-M03', 'Trực quan hóa Dữ liệu với PowerBI', 20, 'Thiết kế Dashboard báo cáo kinh doanh thông minh', 'CT01', 'BAT_BUOC'),

-- Môn thuộc CT02 (Fullstack Web)
('CT02-M01', 'Lập trình Web Frontend Hiện Đại (Next.js/React)', 30, 'React hooks, Next.js Server Components, Tailwind CSS', 'CT02', 'BAT_BUOC'),
('CT02-M02', 'Lập trình Backend RESTful API & Microservices', 30, 'Xây dựng API bảo mật, xử lý xác thực JWT, cơ chế Cache', 'CT02', 'BAT_BUOC'),
('CT02-M03', 'Triển khai DevOps & CI/CD Cloud', 20, 'Container hóa Docker, tự động hóa quy trình với GitHub Actions', 'CT02', 'BAT_BUOC'),

-- Môn thuộc CT03 (AI & Machine Learning)
('CT03-M01', 'Toán ứng dụng cho Machine Learning', 24, 'Đại số tuyến tính, giải tích và xác suất thống kê cho AI', 'CT03', 'BAT_BUOC'),
('CT03-M02', 'Học máy Cơ bản & Nâng cao (Scikit-Learn)', 36, 'Các thuật toán hồi quy, phân loại, gom cụm và đánh giá mô hình', 'CT03', 'BAT_BUOC');

-- =========================================================================
-- 4. CHÈN DỮ LIỆU: KY_HOC
-- =========================================================================
INSERT INTO ky_hoc (ma_ky_hoc, ten_ky_hoc, nam_hoc, tu_ngay, den_ngay, trang_thai)
VALUES 
('2026HK1', 'Học kỳ 1 Năm 2026', '2025-2026', '2026-08-15', '2026-12-31', 'DANG_DIEN_RA'),
('2026HK2', 'Học kỳ 2 Năm 2026', '2026-2027', '2027-01-15', '2027-05-30', 'SAP_MO');

-- =========================================================================
-- 5. CHÈN DỮ LIỆU: KHOA_DAO_TAO
-- =========================================================================
INSERT INTO khoa_dao_tao (ma_khoa, ten_khoa, ngay_bat_dau, ngay_ket_thuc, ma_ctdt, ma_ky_hoc, trang_thai)
VALUES 
('CT01-2026HK1-K01', 'Khóa 01 - Khoa Học Dữ Liệu (Mùa Thu 2026)', '2026-09-01', '2026-12-15', 'CT01', '2026HK1', 'DANG_HOC'),
('CT02-2026HK1-K01', 'Khóa 01 - Fullstack Web Developer (Mùa Thu 2026)', '2026-09-01', '2026-12-20', 'CT02', '2026HK1', 'DANG_HOC'),
('CT03-2026HK1-K01', 'Khóa 01 - AI & Machine Learning (Mùa Thu 2026)', '2026-09-15', '2026-12-30', 'CT03', '2026HK1', 'DANG_HOC');

-- =========================================================================
-- 6. CHÈN DỮ LIỆU: HOC_VIEN
-- =========================================================================
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

-- =========================================================================
-- 7. CHÈN DỮ LIỆU: DANG_KY_KHOA_HOC
-- =========================================================================
INSERT INTO dang_ky_khoa_hoc (ma_hv, ma_khoa, ngay_dang_ky, hoc_phi_da_dong, trang_thai)
VALUES 
-- Học viên đăng ký khóa Data Science (CT01-2026HK1-K01)
('HV001', 'CT01-2026HK1-K01', '2026-08-20 09:30:00', 8500000, 'DANG_HOC'),
('HV002', 'CT01-2026HK1-K01', '2026-08-21 14:15:00', 8500000, 'DANG_HOC'),
('HV003', 'CT01-2026HK1-K01', '2026-08-22 10:00:00', 8500000, 'DANG_HOC'),
('HV004', 'CT01-2026HK1-K01', '2026-08-23 16:45:00', 8500000, 'DANG_HOC'),

-- Học viên đăng ký khóa Fullstack Web (CT02-2026HK1-K01)
('HV004', 'CT02-2026HK1-K01', '2026-08-24 11:00:00', 9000000, 'DANG_HOC'), -- HV004 đăng ký 2 khóa khác nhau
('HV005', 'CT02-2026HK1-K01', '2026-08-25 08:30:00', 9000000, 'DANG_HOC'),
('HV006', 'CT02-2026HK1-K01', '2026-08-26 15:20:00', 9000000, 'DANG_HOC'),

-- Học viên đăng ký khóa AI (CT03-2026HK1-K01)
('HV007', 'CT03-2026HK1-K01', '2026-09-01 10:30:00', 12000000, 'DANG_HOC'),
('HV008', 'CT03-2026HK1-K01', '2026-09-02 14:00:00', 12000000, 'DANG_HOC');

-- =========================================================================
-- 8. CHÈN DỮ LIỆU: GIAO_VIEN
-- =========================================================================
INSERT INTO giao_vien (ma_gv, ho_ten, cccd, so_dien_thoai, email, chuyen_mon, hoc_vi, luong_tro_giang_gio, loai_hop_dong, trang_thai)
VALUES 
('GV01', 'TS. Nguyễn Văn An', '001075001111', '0911001122', 'an.nv@lecturer.ptit.edu.vn', 'Cơ sở dữ liệu & Data Engineering', 'Tiến sĩ', 120000, 'FULLTIME', 'DANG_DAY'),
('GV02', 'ThS. Trần Thị Mai', '001185002222', '0922002233', 'mai.tt@lecturer.ptit.edu.vn', 'Khoa học Dữ liệu & Python', 'Thạc sĩ', 100000, 'PARTTIME', 'DANG_DAY'),
('GV03', 'ThS. Lê Hoàng Long', '001088003333', '0933003344', 'long.lh@lecturer.ptit.edu.vn', 'Lập trình Web & Cloud Computing', 'Thạc sĩ', 110000, 'FULLTIME', 'DANG_DAY'),
('GV04', 'KS. Phạm Hải Đăng', '001096004444', '0944004455', 'dang.ph@assistant.ptit.edu.vn', 'Trợ giảng Data & Python', 'Kỹ sư', 90000, 'PARTTIME', 'DANG_DAY'),
('GV05', 'KS. Vũ Thu Hà', '001198005555', '0955005566', 'ha.vt@assistant.ptit.edu.vn', 'Trợ giảng Web Frontend & Backend', 'Kỹ sư', 85000, 'PARTTIME', 'DANG_DAY'),
('GV06', 'TS. Đỗ Gia Huy', '001079006666', '0966006677', 'huy.dg@lecturer.ptit.edu.vn', 'Trí tuệ nhân tạo & Deep Learning', 'Tiến sĩ', 150000, 'FULLTIME', 'DANG_DAY');

-- =========================================================================
-- 9. CHÈN DỮ LIỆU: LOP_MON_HOC (Môn học triển khai trong khóa cụ thể)
-- =========================================================================
INSERT INTO lop_mon_hoc (ma_lop_mon, ma_khoa, ma_mon, trang_thai)
VALUES 
-- Lớp môn học của Khóa Data (CT01-2026HK1-K01)
('LM_CT01_K01_M01', 'CT01-2026HK1-K01', 'CT01-M01', 'DANG_HOC'), -- Môn CSDL Nâng cao
('LM_CT01_K01_M02', 'CT01-2026HK1-K01', 'CT01-M02', 'DANG_HOC'), -- Môn Python
('LM_CT01_K01_M03', 'CT01-2026HK1-K01', 'CT01-M03', 'SAP_MO'),   -- Môn PowerBI

-- Lớp môn học của Khóa Web (CT02-2026HK1-K01)
('LM_CT02_K01_M01', 'CT02-2026HK1-K01', 'CT02-M01', 'DANG_HOC'), -- Môn Next.js
('LM_CT02_K01_M02', 'CT02-2026HK1-K01', 'CT02-M02', 'DANG_HOC'), -- Môn Backend REST API
('LM_CT02_K01_M03', 'CT02-2026HK1-K01', 'CT02-M03', 'SAP_MO'),   -- Môn DevOps

-- Lớp môn học của Khóa AI (CT03-2026HK1-K01)
('LM_CT03_K01_M01', 'CT03-2026HK1-K01', 'CT03-M01', 'DANG_HOC'), -- Môn Toán cho AI
('LM_CT03_K01_M02', 'CT03-2026HK1-K01', 'CT03-M02', 'SAP_MO');   -- Môn Machine Learning

-- =========================================================================
-- 10. CHÈN DỮ LIỆU: PHAN_CONG_GIANG_DAY
-- =========================================================================
INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro, ngay_phan_cong)
VALUES 
-- Lớp LM_CT01_K01_M01 (CSDL Nâng cao): GV01 dạy chính, GV04 trợ giảng
('LM_CT01_K01_M01', 'GV01', 'GIANG_VIEN', '2026-08-28'),
('LM_CT01_K01_M01', 'GV04', 'TRO_GIANG', '2026-08-28'),

-- Lớp LM_CT01_K01_M02 (Python Data): GV02 dạy chính, GV04 trợ giảng
('LM_CT01_K01_M02', 'GV02', 'GIANG_VIEN', '2026-08-28'),
('LM_CT01_K01_M02', 'GV04', 'TRO_GIANG', '2026-08-28'),

-- Lớp LM_CT02_K01_M01 (Web Frontend): GV03 dạy chính, GV05 trợ giảng
('LM_CT02_K01_M01', 'GV03', 'GIANG_VIEN', '2026-08-29'),
('LM_CT02_K01_M01', 'GV05', 'TRO_GIANG', '2026-08-29'),

-- Lớp LM_CT03_K01_M01 (Toán AI): GV06 dạy chính (không có trợ giảng)
('LM_CT03_K01_M01', 'GV06', 'GIANG_VIEN', '2026-09-05');

-- =========================================================================
-- 11. CHÈN DỮ LIỆU: PHONG_HOC
-- =========================================================================
INSERT INTO phong_hoc (ma_phong, ten_phong, vi_tri, suc_chua, loai_phong, trang_thai, mo_ta)
VALUES 
('LAB_301', 'Phòng Thực Hành Lab 301', 'Tòa A2 - Tầng 3', 40, 'THUC_HANH_LAB', 'SAN_SANG', '40 máy tính cấu hình cao Intel i7, 32GB RAM'),
('LAB_302', 'Phòng Thực Hành Lab 302', 'Tòa A2 - Tầng 3', 35, 'THUC_HANH_LAB', 'SAN_SANG', '35 máy tính thực hành Web & Data'),
('P_201', 'Phòng Lý Thuyết Đa Năng 201', 'Tòa A1 - Tầng 2', 50, 'LY_THUYET', 'SAN_SANG', 'Trang bị máy chiếu 4K và điều hòa trung tâm'),
('P_202', 'Phòng Lý Thuyết 202', 'Tòa A1 - Tầng 2', 45, 'LY_THUYET', 'SAN_SANG', 'Phòng học tiêu chuẩn có âm thanh micro'),
('HT_A', 'Hội Trường Lớn Khu A', 'Tòa A1 - Tầng 1', 150, 'HOI_TRUONG', 'SAN_SANG', 'Tổ chức hội thảo và các kỳ thi tập trung');

-- =========================================================================
-- 12. CHÈN DỮ LIỆU: BUOI_HOC (Mỗi buổi 2 tiếng, không trùng phòng)
-- =========================================================================
INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
VALUES 
-- Lớp CSDL Nâng cao (LM_CT01_K01_M01) - Tháng 9/2026
('LM_CT01_K01_M01', 1, '2026-09-02', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 2, '2026-09-05', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 3, '2026-09-09', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 4, '2026-09-12', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 5, '2026-09-16', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT01_K01_M01', 6, '2026-09-19', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),

-- Lớp Python (LM_CT01_K01_M02) - Tháng 9/2026
('LM_CT01_K01_M02', 1, '2026-09-03', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT01_K01_M02', 2, '2026-09-07', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT01_K01_M02', 3, '2026-09-10', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),
('LM_CT01_K01_M02', 4, '2026-09-14', '18:30:00', '20:30:00', 'LAB_302', 'HOAN_THANH'),

-- Lớp Web Next.js (LM_CT02_K01_M01) - Tháng 9/2026
('LM_CT02_K01_M01', 1, '2026-09-04', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT02_K01_M01', 2, '2026-09-08', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT02_K01_M01', 3, '2026-09-11', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),
('LM_CT02_K01_M01', 4, '2026-09-15', '18:30:00', '20:30:00', 'LAB_301', 'HOAN_THANH'),

-- Lớp Toán AI (LM_CT03_K01_M01) - Tháng 9/2026
('LM_CT03_K01_M01', 1, '2026-09-18', '08:00:00', '10:00:00', 'P_201', 'HOAN_THANH'),
('LM_CT03_K01_M01', 2, '2026-09-22', '08:00:00', '10:00:00', 'P_201', 'HOAN_THANH');

-- =========================================================================
-- 13. CHÈN DỮ LIỆU: KET_QUA_THI
-- Kịch bản đa dạng:
-- - HV001: Môn CSDL thi 1 lần đỗ (8.5), Môn Python thi lần 1 rớt (4.0), thi lần 2 đỗ (7.5)
-- - HV002: Môn CSDL thi lần 1 rớt (3.5), thi lần 2 rớt (4.5) -> Chưa đạt môn này
-- - HV003: Môn CSDL thi 1 lần đỗ (9.0), Môn Python chưa dự thi
-- - HV004: Đạt môn CSDL (6.0), Đạt môn Web Next.js (8.0)
-- =========================================================================
INSERT INTO ket_qua_thi (ma_hv, ma_lop_mon, lan_thi, ngay_thi, diem_thi, ghi_chu)
VALUES 
-- HV001
('HV001', 'LM_CT01_K01_M01', 1, '2026-09-25', 8.5, 'Thi lần đầu đạt loại giỏi'),
('HV001', 'LM_CT01_K01_M02', 1, '2026-09-26', 4.0, 'Thi lần đầu chưa đạt lý thuyết'),
('HV001', 'LM_CT01_K01_M02', 2, '2026-10-05', 7.5, 'Thi lại lần 2 đạt yêu cầu'),

-- HV002 (Chưa hoàn thành môn CSDL)
('HV002', 'LM_CT01_K01_M01', 1, '2026-09-25', 3.5, 'Thi lần đầu bị rớt SQL tối ưu'),
('HV002', 'LM_CT01_K01_M01', 2, '2026-10-05', 4.5, 'Thi lại lần 2 vẫn chưa đạt 5.0'),

-- HV003 (Đạt môn 1, chưa thi môn 2)
('HV003', 'LM_CT01_K01_M01', 1, '2026-09-25', 9.0, 'Điểm xuất sắc'),

-- HV004
('HV004', 'LM_CT01_K01_M01', 1, '2026-09-25', 6.0, 'Đạt'),
('HV004', 'LM_CT02_K01_M01', 1, '2026-09-28', 8.0, 'Đạt điểm cao phần React/Next.js'),

-- HV005
('HV005', 'LM_CT02_K01_M01', 1, '2026-09-28', 5.0, 'Thi lần 1 chưa đạt (5.0 <= 5)'),
('HV005', 'LM_CT02_K01_M01', 2, '2026-10-08', 7.0, 'Thi lại lần 2 đạt yêu cầu'),

-- HV007
('HV007', 'LM_CT03_K01_M01', 1, '2026-09-30', 8.5, 'Đạt điểm cao phần Đại số tuyến tính');
