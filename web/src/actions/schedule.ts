'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getClassSessions() {
  try {
    const res = await query(
      `SELECT 
        bh.ma_buoi AS session_id,
        lm.ma_khoa AS class_id,
        kdt.ten_khoa AS class_name,
        lm.ma_mon AS subject_id,
        mh.ten_mon AS subject_name,
        bh.ma_phong AS room_id,
        r.ten_phong AS room_name,
        r.vi_tri AS location,
        (bh.ngay_hoc || ' ' || bh.gio_bat_dau)::TIMESTAMP AS start_time,
        (bh.ngay_hoc || ' ' || bh.gio_ket_thuc)::TIMESTAMP AS end_time,
        gv_main.ma_gv AS main_instructor_id,
        gv_main.ho_ten AS main_instructor_name,
        gv_ta.ma_gv AS teaching_assistant_id,
        gv_ta.ho_ten AS teaching_assistant_name,
        'NORMAL' AS session_type,
        bh.trang_thai AS status
       FROM buoi_hoc bh
       JOIN lop_mon_hoc lm ON bh.ma_lop_mon = lm.ma_lop_mon
       JOIN mon_hoc mh ON lm.ma_mon = mh.ma_mon
       JOIN khoa_dao_tao kdt ON lm.ma_khoa = kdt.ma_khoa
       JOIN phong_hoc r ON bh.ma_phong = r.ma_phong
       LEFT JOIN phan_cong_giang_day pc_main ON lm.ma_lop_mon = pc_main.ma_lop_mon AND pc_main.vai_tro = 'GIANG_VIEN' AND pc_main.is_deleted = FALSE
       LEFT JOIN giao_vien gv_main ON pc_main.ma_gv = gv_main.ma_gv
       LEFT JOIN phan_cong_giang_day pc_ta ON lm.ma_lop_mon = pc_ta.ma_lop_mon AND pc_ta.vai_tro = 'TRO_GIANG' AND pc_ta.is_deleted = FALSE
       LEFT JOIN giao_vien gv_ta ON pc_ta.ma_gv = gv_ta.ma_gv
       WHERE bh.is_deleted = FALSE
       ORDER BY bh.ngay_hoc ASC, bh.gio_bat_dau ASC`
    );

    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getClassSessions error:', error);
    return { success: false, error: error.message, data: [] };
  }
}

export async function createClassSession(formData: {
  class_id: string; // mã khóa đào tạo
  subject_id: string; // mã môn học
  room_id: string;
  start_time: string; // ISO String or YYYY-MM-DD HH:mm:ss
  end_time: string;
  main_instructor_id: string;
  teaching_assistant_id?: string | null;
  session_type?: 'NORMAL' | 'MAKEUP' | 'EXAM';
}) {
  try {
    const start = new Date(formData.start_time);
    const end = new Date(formData.end_time);
    if (end <= start) {
      return { success: false, error: 'Thời gian kết thúc phải lớn hơn thời gian bắt đầu!' };
    }

    const ngayHoc = formData.start_time.substring(0, 10);
    const gioBatDau = formData.start_time.length >= 16 ? formData.start_time.substring(11, 19) : '18:30:00';
    const gioKetThuc = formData.end_time.length >= 16 ? formData.end_time.substring(11, 19) : '20:30:00';

    // 1. Tìm hoặc tạo LopMonHoc
    let lopMonRes = await query(
      `SELECT ma_lop_mon FROM lop_mon_hoc WHERE ma_khoa = $1 AND ma_mon = $2 AND is_deleted = FALSE`,
      [formData.class_id, formData.subject_id]
    );

    let maLopMon = '';
    if (lopMonRes.rows.length === 0) {
      maLopMon = `LM_${formData.class_id}_${formData.subject_id}`.replace(/-/g, '_');
      await query(
        `INSERT INTO lop_mon_hoc (ma_lop_mon, ma_khoa, ma_mon, trang_thai) VALUES ($1, $2, $3, 'DANG_HOC')
         ON CONFLICT (ma_khoa, ma_mon) DO NOTHING`,
        [maLopMon, formData.class_id, formData.subject_id]
      );
    } else {
      maLopMon = lopMonRes.rows[0].ma_lop_mon;
    }

    // 2. Phân công giảng viên chính
    if (formData.main_instructor_id) {
      await query(
        `INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro) VALUES ($1, $2, 'GIANG_VIEN')
         ON CONFLICT (ma_lop_mon, ma_gv) DO UPDATE SET vai_tro = 'GIANG_VIEN', is_deleted = FALSE`,
        [maLopMon, formData.main_instructor_id]
      );
    }

    // 3. Phân công trợ giảng (nếu có)
    if (formData.teaching_assistant_id) {
      await query(
        `INSERT INTO phan_cong_giang_day (ma_lop_mon, ma_gv, vai_tro) VALUES ($1, $2, 'TRO_GIANG')
         ON CONFLICT (ma_lop_mon, ma_gv) DO UPDATE SET vai_tro = 'TRO_GIANG', is_deleted = FALSE`,
        [maLopMon, formData.teaching_assistant_id]
      );
    }

    // 4. Lấy thứ tự buổi tiếp theo
    const countRes = await query(
      `SELECT COUNT(*) AS count FROM buoi_hoc WHERE ma_lop_mon = $1 AND is_deleted = FALSE`,
      [maLopMon]
    );
    const thuTu = parseInt(countRes.rows[0].count, 10) + 1;

    // 5. Thêm buổi học (Trigger kiểm tra xung đột phòng và trùng lịch GV sẽ kích hoạt)
    await query(
      `INSERT INTO buoi_hoc (ma_lop_mon, thu_tu_buoi, ngay_hoc, gio_bat_dau, gio_ket_thuc, ma_phong, trang_thai)
       VALUES ($1, $2, $3, $4, $4::time + INTERVAL '2 hours', $5, 'DA_LEN_LICH')`,
      [maLopMon, thuTu, ngayHoc, gioBatDau, formData.room_id]
    );

    revalidatePath('/schedule');
    return { success: true, message: 'Xếp lịch buổi học thành công!' };
  } catch (error: any) {
    const errorMsg = error?.message || 'Có lỗi xảy ra khi xếp lịch';
    console.warn('[Conflict Trigger Caught]:', errorMsg);
    return {
      success: false,
      error: errorMsg,
      isTriggerViolation: true,
    };
  }
}

export async function getScheduleMetadata() {
  try {
    const [classesRes, subjectsRes, roomsRes, instructorsRes] = await Promise.all([
      query(`SELECT ma_khoa AS class_id, ten_khoa AS class_name FROM khoa_dao_tao WHERE is_deleted = FALSE AND trang_thai <> 'HUY' ORDER BY ten_khoa`),
      query(`SELECT ma_mon AS subject_id, ten_mon AS subject_name, ma_ctdt AS program_id FROM mon_hoc WHERE is_deleted = FALSE ORDER BY ten_mon`),
      query(`SELECT ma_phong AS room_id, ten_phong AS room_name, suc_chua AS capacity, loai_phong AS room_type FROM phong_hoc WHERE is_deleted = FALSE AND trang_thai = 'SAN_SANG' ORDER BY ma_phong`),
      query(`SELECT ma_gv AS instructor_id, ho_ten AS full_name, loai_hop_dong AS contract_type FROM giao_vien WHERE is_deleted = FALSE ORDER BY ho_ten`),
    ]);

    return {
      success: true,
      classes: classesRes.rows,
      subjects: subjectsRes.rows,
      rooms: roomsRes.rows,
      instructors: instructorsRes.rows,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
