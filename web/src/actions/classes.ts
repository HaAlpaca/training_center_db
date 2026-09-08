'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getClasses(search?: string) {
  try {
    let sql = `
      SELECT 
        c.class_id,
        c.class_name,
        c.program_id,
        p.program_name,
        c.semester_id,
        sem.semester_name,
        c.max_capacity,
        COUNT(e.student_id) AS current_enrolled,
        (c.max_capacity - COUNT(e.student_id)) AS remaining_slots,
        c.status
      FROM class c
      JOIN program p ON c.program_id = p.program_id
      JOIN semester sem ON c.semester_id = sem.semester_id
      LEFT JOIN enrollment e ON c.class_id = e.class_id AND e.is_deleted = FALSE
      WHERE c.is_deleted = FALSE
    `;
    const params: any[] = [];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (c.class_name ILIKE $1 OR c.class_id ILIKE $1 OR p.program_name ILIKE $1)`;
    }

    sql += ` GROUP BY c.class_id, c.class_name, c.program_id, p.program_name, c.semester_id, sem.semester_name, c.max_capacity, c.status
             ORDER BY c.class_id`;

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
      `INSERT INTO class (class_id, class_name, program_id, semester_id, max_capacity, status)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        formData.class_id.trim().toUpperCase(),
        formData.class_name.trim(),
        formData.program_id,
        formData.semester_id,
        formData.max_capacity,
        formData.status || 'OPEN',
      ]
    );
    revalidatePath('/classes');
    return { success: true, message: 'Tạo khóa đào tạo / lớp học thành công' };
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
    // 1. Kiểm tra sĩ số lớp trước khi ghi danh (Validation 6.2)
    const checkCapRes = await query(
      `SELECT c.max_capacity, COUNT(e.student_id) AS current_enrolled
       FROM class c
       LEFT JOIN enrollment e ON c.class_id = e.class_id AND e.is_deleted = FALSE
       WHERE c.class_id = $1 AND c.is_deleted = FALSE
       GROUP BY c.max_capacity`,
      [formData.class_id]
    );

    if (checkCapRes.rows.length === 0) {
      return { success: false, error: 'Lớp học không tồn tại!' };
    }

    const { max_capacity, current_enrolled } = checkCapRes.rows[0];
    if (Number(current_enrolled) >= Number(max_capacity)) {
      return {
        success: false,
        error: `Lớp học đã đạt sĩ số tối đa (${current_enrolled}/${max_capacity}). Không thể đăng ký thêm học viên!`,
      };
    }

    // 2. Thêm vào enrollment
    await query(
      `INSERT INTO enrollment (student_id, class_id, tuition_paid, status)
       VALUES ($1, $2, $3, 'ENROLLED')
       ON CONFLICT (student_id, class_id) DO UPDATE 
       SET is_deleted = FALSE, status = 'ENROLLED', tuition_paid = EXCLUDED.tuition_paid`,
      [formData.student_id, formData.class_id, formData.tuition_paid || 0]
    );

    revalidatePath('/classes');
    return { success: true, message: 'Ghi danh học viên vào lớp thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function getClassEnrollments(class_id: string) {
  try {
    const res = await query(
      `SELECT 
        e.enrollment_id,
        e.student_id,
        s.full_name AS student_name,
        s.phone_number,
        s.email,
        e.enrolled_date,
        e.tuition_paid,
        e.status
       FROM enrollment e
       JOIN student s ON e.student_id = s.student_id
       WHERE e.class_id = $1 AND e.is_deleted = FALSE
       ORDER BY e.enrolled_date DESC`,
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
      `SELECT semester_id, semester_name, status FROM semester WHERE is_deleted = FALSE ORDER BY start_date DESC`
    );
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}
