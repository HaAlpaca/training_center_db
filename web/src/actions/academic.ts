'use server';

import { query } from '@/lib/db';

// =========================================================================
// YÊU CẦU 3: LIỆT KÊ TOÀN BỘ CÁC HỌC VIÊN CHƯA HOÀN THÀNH XONG CÁC MÔN HỌC
// CỦA KHÓA ĐÀO TẠO KÈM ĐIỂM THI CỦA CÁC LẦN DỰ THI CHƯA ĐẠT (NẾU ĐÃ DỰ THI)
// =========================================================================
export async function getIncompleteStudentsByClass(class_id: string) {
  try {
    const res = await query(
      `SELECT 
        ma_hv AS student_id,
        ho_ten_hv AS student_name,
        $1 AS class_id,
        $1 AS class_name,
        ma_mon AS subject_id,
        ten_mon AS subject_name,
        trang_thai_hoan_thanh AS completion_status,
        chi_tiet_lan_rot AS failed_exam_details,
        so_lan_thi_rot AS failed_attempts_count
       FROM fn_hoc_vien_chua_hoan_thanh_khoa($1)`,
      [class_id]
    );

    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getIncompleteStudentsByClass error:', error);
    return { success: false, error: error.message, data: [] };
  }
}
