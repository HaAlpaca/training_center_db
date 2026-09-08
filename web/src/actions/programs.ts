'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getPrograms(search?: string) {
  try {
    let sql = `
      SELECT 
        p.program_id,
        p.program_name,
        p.description,
        p.version,
        p.manager_id,
        p.status,
        s.full_name AS manager_name,
        s.email AS manager_email,
        COUNT(sub.subject_id) FILTER (WHERE sub.is_deleted = FALSE) AS subject_count
      FROM program p
      JOIN staff s ON p.manager_id = s.staff_id
      LEFT JOIN subject sub ON p.program_id = sub.program_id
      WHERE p.is_deleted = FALSE
    `;
    const params: any[] = [];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (p.program_name ILIKE $1 OR p.program_id ILIKE $1)`;
    }

    sql += ` GROUP BY p.program_id, p.program_name, p.description, p.version, p.manager_id, p.status, s.full_name, s.email
             ORDER BY p.program_id`;

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
      `INSERT INTO program (program_id, program_name, description, version, manager_id, status)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        formData.program_id.trim().toUpperCase(),
        formData.program_name.trim(),
        formData.description || '',
        formData.version || '1.0',
        formData.manager_id,
        formData.status || 'ACTIVE',
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
      `UPDATE program
       SET program_name = $1, description = $2, version = $3, manager_id = $4, status = $5, updated_at = CURRENT_TIMESTAMP
       WHERE program_id = $6 AND is_deleted = FALSE`,
      [
        formData.program_name.trim(),
        formData.description || '',
        formData.version || '1.0',
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
      `UPDATE program SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE program_id = $1`,
      [program_id]
    );
    revalidatePath('/programs');
    return { success: true, message: 'Đã xóa chương trình đào tạo' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

// --- SUBJECT ACTIONS ---
export async function getSubjectsByProgram(program_id: string) {
  try {
    const res = await query(
      `SELECT 
        s.subject_id,
        s.subject_name,
        s.program_id,
        s.total_hours,
        s.total_sessions,
        s.subject_type,
        s.created_at
       FROM subject s
       WHERE s.program_id = $1 AND s.is_deleted = FALSE
       ORDER BY s.subject_id`,
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
  subject_type: 'CORE' | 'ELECTIVE';
}) {
  try {
    // 1. Kiểm tra validation trước giao dịch (Validation Query 6.1)
    const checkRes = await query(
      `SELECT COUNT(*) AS count FROM subject WHERE program_id = $1 AND is_deleted = FALSE`,
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

    // 2. Thực thi Insert (Trigger trg_check_max_subjects cũng sẽ bảo vệ tầng CSDL)
    await query(
      `INSERT INTO subject (subject_id, subject_name, program_id, total_hours, subject_type)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        formData.subject_id.trim().toUpperCase(),
        formData.subject_name.trim(),
        formData.program_id,
        formData.total_hours,
        formData.subject_type || 'CORE',
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
      `UPDATE subject SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE subject_id = $1`,
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
      `SELECT staff_id, full_name, position FROM staff WHERE is_deleted = FALSE AND status = 'Active' ORDER BY full_name`
    );
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}
