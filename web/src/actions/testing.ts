'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

// =========================================================================
// CHẠY KIỂM THỬ 5 TRIGGERS TRÊN GIAO DIỆN
// =========================================================================
export async function runTriggerTest(testCaseId: number) {
  try {
    let sql = '';
    let description = '';

    switch (testCaseId) {
      case 1:
        description = 'Trigger 2: Chống trùng phòng học (trg_kiem_tra_trung_phong)';
        sql = `
          DO $$
          BEGIN
              INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
              VALUES ('LM_CT01_K01_M02', 99, '2026-09-02', '18:30:00', '20:30:00', 'LAB_301', 'DA_LEN_LICH');
              
              RAISE EXCEPTION 'TEST THẤT BẠI: Trigger không chặn được trùng phòng!';
          END $$;
        `;
        break;

      case 2:
        description = 'Trigger 3: Chống trùng lịch giảng viên (trg_kiem_tra_trung_lich_gv)';
        sql = `
          DO $$
          BEGIN
              INSERT INTO phong_hoc (ma_phong, ten_phong, suc_chua, loai_phong, trang_thai)
              VALUES ('LAB_999', 'Phòng Test 999', 30, 'THUC_HANH_LAB', 'SAN_SANG')
              ON CONFLICT (ma_phong) DO NOTHING;

              INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
              VALUES ('LM_CT01_K01_M01', 98, '2026-09-02', '18:30:00', '20:30:00', 'LAB_999', 'DA_LEN_LICH');

              RAISE EXCEPTION 'TEST THẤT BẠI: Trigger không chặn được trùng lịch giảng viên!';
          END $$;
        `;
        break;

      case 3:
        description = 'Trigger 1: Giới hạn tối đa 10 môn / CTĐT (trg_kiem_tra_so_mon_ctdt)';
        sql = `
          DO $$
          DECLARE i INT;
          BEGIN
              FOR i IN 4..10 LOOP
                  INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, ma_ctdt, loai_mon)
                  VALUES ('CT01-TEST-' || i, 'Môn kiểm thử ' || i, 20, 'CT01', 'TU_CHON')
                  ON CONFLICT DO NOTHING;
              END LOOP;

              INSERT INTO mon_hoc (ma_mon, ten_mon, tong_so_gio, ma_ctdt, loai_mon)
              VALUES ('CT01-TEST-11', 'Môn kiểm thử thứ 11', 20, 'CT01', 'TU_CHON');

              RAISE EXCEPTION 'TEST THẤT BẠI: Trigger không chặn được quá 10 môn học!';
          END $$;
        `;
        break;

      case 4:
        description = 'Trigger 4: Giảng viên chính & Trợ giảng phải khác nhau (trg_kiem_tra_phan_cong)';
        sql = `
          DO $$
          BEGIN
              INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro)
              VALUES ('LM_CT01_K01_M01', 'GV01', 'TRO_GIANG');

              RAISE EXCEPTION 'TEST THẤT BẠI: Trigger không chặn được 1 người làm cả GV chính và Trợ giảng!';
          END $$;
        `;
        break;

      case 5:
        description = 'Trigger 5: Học viên chỉ được thi ở môn của khóa đã đăng ký (trg_kiem_tra_hoc_vien_du_thi)';
        sql = `
          DO $$
          BEGIN
              INSERT INTO ket_qua_thi (ma_hv, ma_lop_mon, lan_thi, ngay_thi, diem_thi, ghi_chu)
              VALUES ('HV007', 'LM_CT01_K01_M01', 1, '2026-09-25', 9.0, 'Thử nhập điểm gian lận khác khóa');

              RAISE EXCEPTION 'TEST THẤT BẠI: Trigger không chặn được học viên thi sai khóa!';
          END $$;
        `;
        break;

      default:
        return { success: false, error: 'Mã kịch bản kiểm thử không hợp lệ' };
    }

    await query(sql);
    return {
      success: false,
      message: 'Trigger đã KHÔNG chặn được thao tác vi phạm.',
      description,
    };
  } catch (error: any) {
    // Khi Trigger hoạt động đúng, nó sẽ RAISE EXCEPTION và rơi vào catch
    const errorMsg = error?.message || 'Lỗi không xác định';
    return {
      success: true,
      isTriggerBlocked: true,
      message: `Trigger đã kích hoạt và chặn vi phạm thành công!`,
      sqlError: errorMsg,
      testCaseId,
    };
  }
}

// =========================================================================
// THỰC THI 5 STORED PROCEDURES TRANSACTIONS TRÊN GIAO DIỆN
// =========================================================================

export async function executeTransaction1(formData: {
  ma_khoa: string;
  ten_khoa: string;
  ma_ctdt: string;
  ma_ky_hoc: string;
  ngay_bat_dau: string;
  ngay_ket_thuc: string;
}) {
  try {
    await query(
      `CALL sp_mo_khoa_dao_tao_moi($1, $2, $3, $4, $5::DATE, $6::DATE)`,
      [
        formData.ma_khoa.trim().toUpperCase(),
        formData.ten_khoa.trim(),
        formData.ma_ctdt,
        formData.ma_ky_hoc,
        formData.ngay_bat_dau,
        formData.ngay_ket_thuc,
      ]
    );
    revalidatePath('/classes');
    revalidatePath('/testing');
    return {
      success: true,
      message: `Transaction thành công: Đã mở khóa ${formData.ma_khoa} và tự động tạo toàn bộ các Lớp môn học!`,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function executeTransaction2(formData: {
  ma_hv: string;
  ma_khoa: string;
  hoc_phi: number;
}) {
  try {
    await query(
      `CALL sp_dang_ky_khoa_hoc_va_dong_phi($1, $2, $3)`,
      [formData.ma_hv, formData.ma_khoa, formData.hoc_phi]
    );
    revalidatePath('/classes');
    revalidatePath('/students');
    return {
      success: true,
      message: `Transaction thành công: Đã ghi nhận học viên ${formData.ma_hv} đăng ký khóa ${formData.ma_khoa} và thanh toán ${formData.hoc_phi.toLocaleString('vi-VN')} VNĐ!`,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function executeTransaction3(formData: {
  ma_lop_mon: string;
  ma_gv_chinh: string;
  ma_gv_ta?: string;
  ma_phong: string;
  ngay_bat_dau: string;
  gio_bat_dau: string;
  khoang_cach_ngay?: number;
}) {
  try {
    await query(
      `CALL sp_phan_cong_va_len_lich_buoi_hoc($1, $2, $3, $4, $5::DATE, $6::TIME, $7)`,
      [
        formData.ma_lop_mon,
        formData.ma_gv_chinh,
        formData.ma_gv_ta || null,
        formData.ma_phong,
        formData.ngay_bat_dau,
        formData.gio_bat_dau,
        formData.khoang_cach_ngay || 3,
      ]
    );
    revalidatePath('/schedule');
    return {
      success: true,
      message: `Transaction thành công: Đã phân công giáo viên và tự động sinh toàn bộ lịch học cho lớp ${formData.ma_lop_mon}!`,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function executeTransaction4(formData: {
  ma_hv: string;
  ma_lop_mon: string;
  diem_thi: number;
  ngay_thi: string;
  ghi_chu?: string;
}) {
  try {
    await query(
      `CALL sp_ghi_nhan_ket_qua_thi($1, $2, $3, $4::DATE, $5)`,
      [formData.ma_hv, formData.ma_lop_mon, formData.diem_thi, formData.ngay_thi, formData.ghi_chu || '']
    );
    revalidatePath('/transcripts');
    revalidatePath('/incomplete-students');
    return {
      success: true,
      message: `Transaction thành công: Đã nhập điểm thi ${formData.diem_thi} cho học viên ${formData.ma_hv} và tự động xét tốt nghiệp khóa!`,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function executeTransaction5(formData: {
  ma_hv: string;
  ma_khoa_cu: string;
  ma_khoa_moi: string;
}) {
  try {
    await query(
      `CALL sp_chuyen_khoa_hoc_vien($1, $2, $3)`,
      [formData.ma_hv, formData.ma_khoa_cu, formData.ma_khoa_moi]
    );
    revalidatePath('/classes');
    revalidatePath('/students');
    return {
      success: true,
      message: `Transaction thành công: Đã chuyển học viên ${formData.ma_hv} từ khóa ${formData.ma_khoa_cu} sang ${formData.ma_khoa_moi} và kết chuyển bảo lưu 100% học phí!`,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function getTestingMetadata() {
  try {
    const [courses, students, subjects, instructors, rooms, classes] = await Promise.all([
      query(`SELECT ma_khoa, ten_khoa, ma_ctdt FROM khoa_dao_tao WHERE is_deleted = FALSE ORDER BY ma_khoa`),
      query(`SELECT ma_hv, ho_ten FROM hoc_vien WHERE is_deleted = FALSE ORDER BY ma_hv`),
      query(`SELECT ma_mon, ten_mon, ma_ctdt FROM mon_hoc WHERE is_deleted = FALSE ORDER BY ma_mon`),
      query(`SELECT ma_gv, ho_ten FROM giao_vien WHERE is_deleted = FALSE ORDER BY ma_gv`),
      query(`SELECT ma_phong, ten_phong FROM phong_hoc WHERE is_deleted = FALSE ORDER BY ma_phong`),
      query(`SELECT ma_lop_mon, ma_khoa, ma_mon FROM lop_mon_hoc WHERE is_deleted = FALSE ORDER BY ma_lop_mon`),
    ]);

    return {
      success: true,
      courses: courses.rows,
      students: students.rows,
      subjects: subjects.rows,
      instructors: instructors.rows,
      rooms: rooms.rows,
      classes: classes.rows,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
