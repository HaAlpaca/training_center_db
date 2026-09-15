'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getPrograms(search?: string) {
  try {
    let sql = `
      SELECT 
        p.ma_ctdt AS program_id,
        p.ten_ctdt AS program_name,
        p.mo_ta AS description,
        '1.0' AS version,
        p.ma_nv_quan_ly AS manager_id,
        p.trang_thai AS status,
        s.ho_ten AS manager_name,
        s.email AS manager_email,
        COUNT(sub.ma_mon) FILTER (WHERE sub.is_deleted = FALSE) AS subject_count
      FROM chuong_trinh_dao_tao p
      JOIN nhan_vien s ON p.ma_nv_quan_ly = s.ma_nv
      LEFT JOIN mon_hoc sub ON p.ma_ctdt = sub.ma_ctdt
      WHERE p.is_deleted = FALSE
    `;
    const params: any[] = [];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (p.ten_ctdt ILIKE $1 OR p.ma_ctdt ILIKE $1)`;
    }

    sql += ` GROUP BY p.ma_ctdt, p.ten_ctdt, p.mo_ta, p.ma_nv_quan_ly, p.trang_thai, s.ho_ten, s.email
             ORDER BY p.ma_ctdt`;

    const res = await query(sql, params);
    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getPrograms error:', error);
    return { success: false, error: error.message, data: [] };
  }
}

export async function createProgram(formData: {
  program_id: string;
  program_name: string;
  description?: string;
  version?: string;
  manager_id: string;
  status?: string;
}) {
  try {
    await query(
      `INSERT INTO chuong_trinh_dao_tao (ma_ctdt, ten_ctdt, mo_ta, ma_nv_quan_ly, trang_thai)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        formData.program_id.trim().toUpperCase(),
        formData.program_name.trim(),
        formData.description || '',
        formData.manager_id,
        formData.status || 'DANG_MO',
      ]
    );
    revalidatePath('/programs');
    return { success: true, message: 'Tạo chương trình đào tạo thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function updateProgram(
  program_id: string,
  formData: {
    program_name: string;
    description?: string;
    version?: string;
    manager_id: string;
    status: string;
  }
) {
  try {
    await query(
      `UPDATE chuong_trinh_dao_tao
       SET ten_ctdt = $1, mo_ta = $2, ma_nv_quan_ly = $3, trang_thai = $4, updated_at = CURRENT_TIMESTAMP
       WHERE ma_ctdt = $5 AND is_deleted = FALSE`,
      [
        formData.program_name.trim(),
        formData.description || '',
        formData.manager_id,
        formData.status,
        program_id,
      ]
    );
    revalidatePath('/programs');
    return { success: true, message: 'Cập nhật chương trình thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function deleteProgram(program_id: string) {
  try {
    await query(
      `UPDATE chuong_trinh_dao_tao SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE ma_ctdt = $1`,
      [program_id]
    );
    revalidatePath('/programs');
    return { success: true, message: 'Đã xóa chương trình đào tạo' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

// --- MON_HOC ACTIONS ---
export async function getSubjectsByProgram(program_id: string) {
  try {
    const res = await query(
      `SELECT 
        s.ma_mon AS subject_id,
        s.ten_mon AS subject_name,
        s.ma_ctdt AS program_id,
        s.tong_so_gio AS total_hours,
        s.so_buoi_hoc AS total_sessions,
        s.loai_mon AS subject_type,
        s.created_at
       FROM mon_hoc s
       WHERE s.ma_ctdt = $1 AND s.is_deleted = FALSE
       ORDER BY s.ma_mon`,
      [program_id]
    );
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}

export async function createSubject(formData: {
  subject_id: string;
  subject_name: string;
  program_id: string;
  total_hours: number;
  subject_type: 'CORE' | 'ELECTIVE' | 'BAT_BUOC' | 'TU_CHON';
}) {
  try {
    // 1. Kiểm tra validation trước giao dịch (Tối đa 10 môn)
    const checkRes = await query(
      `SELECT COUNT(*) AS count FROM mon_hoc WHERE ma_ctdt = $1 AND is_deleted = FALSE`,
      [formData.program_id]
    );
    const count = parseInt(checkRes.rows[0].count, 10);
    if (count >= 10) {
      return {
        success: false,
        error: 'Ràng buộc quy chế: Mỗi chương trình đào tạo chỉ được phép có tối đa 10 môn học!',
      };
    }

    if (formData.total_hours <= 0 || formData.total_hours % 2 !== 0) {
      return {
        success: false,
        error: 'Thời lượng môn học phải là số chẵn dương (mỗi buổi học kéo dài đúng 2 giờ)!',
      };
    }

    const loaiMon = formData.subject_type === 'ELECTIVE' || formData.subject_type === 'TU_CHON' ? 'TU_CHON' : 'BAT_BUOC';

    // 2. Thực thi Insert
    await query(
      `INSERT INTO mon_hoc (ma_mon, ten_mon, ma_ctdt, tong_so_gio, loai_mon)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        formData.subject_id.trim().toUpperCase(),
        formData.subject_name.trim(),
        formData.program_id,
        formData.total_hours,
        loaiMon,
      ]
    );
    revalidatePath('/programs');
    return { success: true, message: 'Thêm môn học thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function deleteSubject(subject_id: string) {
  try {
    await query(
      `UPDATE mon_hoc SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE ma_mon = $1`,
      [subject_id]
    );
    revalidatePath('/programs');
    return { success: true, message: 'Đã xóa môn học' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function getStaffDropdown() {
  try {
    const res = await query(
      `SELECT ma_nv AS staff_id, ho_ten AS full_name, chuc_vu AS position FROM nhan_vien WHERE is_deleted = FALSE AND trang_thai = 'DANG_LAM' ORDER BY ho_ten`
    );
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}
