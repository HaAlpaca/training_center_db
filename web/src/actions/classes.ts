'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getClasses(search?: string) {
  try {
    let sql = `
      SELECT 
        c.ma_khoa AS class_id,
        c.ten_khoa AS class_name,
        c.ma_ctdt AS program_id,
        p.ten_ctdt AS program_name,
        c.ma_ky_hoc AS semester_id,
        sem.ten_ky_hoc AS semester_name,
        100 AS max_capacity,
        COUNT(e.ma_hv) AS current_enrolled,
        (100 - COUNT(e.ma_hv)) AS remaining_slots,
        c.trang_thai AS status
      FROM khoa_dao_tao c
      JOIN chuong_trinh_dao_tao p ON c.ma_ctdt = p.ma_ctdt
      JOIN ky_hoc sem ON c.ma_ky_hoc = sem.ma_ky_hoc
      LEFT JOIN dang_ky_khoa_hoc e ON c.ma_khoa = e.ma_khoa AND e.is_deleted = FALSE
      WHERE c.is_deleted = FALSE
    `;
    const params: any[] = [];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (c.ten_khoa ILIKE $1 OR c.ma_khoa ILIKE $1 OR p.ten_ctdt ILIKE $1)`;
    }

    sql += ` GROUP BY c.ma_khoa, c.ten_khoa, c.ma_ctdt, p.ten_ctdt, c.ma_ky_hoc, sem.ten_ky_hoc, c.trang_thai
             ORDER BY c.ma_khoa`;

    const res = await query(sql, params);
    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getClasses error:', error);
    return { success: false, error: error.message, data: [] };
  }
}

export async function createClass(formData: {
  class_id: string;
  class_name: string;
  program_id: string;
  semester_id: string;
  max_capacity: number;
  status?: string;
}) {
  try {
    await query(
      `INSERT INTO khoa_dao_tao (ma_khoa, ten_khoa, ma_ctdt, ma_ky_hoc, ngay_bat_dau, ngay_ket_thuc, trang_thai)
       VALUES ($1, $2, $3, $4, CURRENT_DATE, CURRENT_DATE + INTERVAL '4 months', $5)`,
      [
        formData.class_id.trim().toUpperCase(),
        formData.class_name.trim(),
        formData.program_id,
        formData.semester_id,
        formData.status || 'MO_DANG_KY',
      ]
    );
    revalidatePath('/classes');
    return { success: true, message: 'Tạo khóa đào tạo thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function enrollStudent(formData: {
  class_id: string;
  student_id: string;
  tuition_paid?: number;
}) {
  try {
    await query(
      `INSERT INTO dang_ky_khoa_hoc (ma_hv, ma_khoa, hoc_phi_da_dong, trang_thai)
       VALUES ($1, $2, $3, 'DANG_HOC')
       ON CONFLICT (ma_hv, ma_khoa) DO UPDATE 
       SET is_deleted = FALSE, trang_thai = 'DANG_HOC', hoc_phi_da_dong = EXCLUDED.hoc_phi_da_dong`,
      [formData.student_id, formData.class_id, formData.tuition_paid || 0]
    );

    revalidatePath('/classes');
    return { success: true, message: 'Ghi danh học viên vào khóa học thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function getClassEnrollments(class_id: string) {
  try {
    const res = await query(
      `SELECT 
        (e.ma_hv || '_' || e.ma_khoa) AS enrollment_id,
        e.ma_hv AS student_id,
        s.ho_ten AS student_name,
        s.so_dien_thoai AS phone_number,
        s.email,
        e.ngay_dang_ky AS enrolled_date,
        e.hoc_phi_da_dong AS tuition_paid,
        e.trang_thai AS status
       FROM dang_ky_khoa_hoc e
       JOIN hoc_vien s ON e.ma_hv = s.ma_hv
       WHERE e.ma_khoa = $1 AND e.is_deleted = FALSE
       ORDER BY e.ngay_dang_ky DESC`,
      [class_id]
    );
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}

export async function getSemestersDropdown() {
  try {
    const res = await query(
      `SELECT ma_ky_hoc AS semester_id, ten_ky_hoc AS semester_name, trang_thai AS status FROM ky_hoc WHERE is_deleted = FALSE ORDER BY tu_ngay DESC`
    );
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}
