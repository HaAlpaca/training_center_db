'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getStudents(search?: string) {
  try {
    let sql = `
      SELECT 
        s.student_id,
        s.full_name,
        s.date_of_birth,
        s.phone_number,
        s.email,
        s.source,
        s.status,
        COUNT(e.class_id) AS enrolled_classes_count
      FROM student s
      LEFT JOIN enrollment e ON s.student_id = e.student_id AND e.is_deleted = FALSE
      WHERE s.is_deleted = FALSE
    `;
    const params: any[] = [];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (s.full_name ILIKE $1 OR s.student_id ILIKE $1 OR s.phone_number ILIKE $1 OR s.email ILIKE $1)`;
    }

    sql += ` GROUP BY s.student_id, s.full_name, s.date_of_birth, s.phone_number, s.email, s.source, s.status
             ORDER BY s.student_id`;

    const res = await query(sql, params);
    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getStudents error:', error);
    return { success: false, error: error.message, data: [] };
  }
}

export async function createStudent(formData: {
  student_id: string;
  full_name: string;
  date_of_birth: string;
  phone_number: string;
  email?: string;
  source?: string;
  status?: string;
}) {
  try {
    await query(
      `INSERT INTO student (student_id, full_name, date_of_birth, phone_number, email, source, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        formData.student_id.trim().toUpperCase(),
        formData.full_name.trim(),
        formData.date_of_birth,
        formData.phone_number.trim(),
        formData.email?.trim() || null,
        formData.source || 'Direct',
        formData.status || 'ACTIVE',
      ]
    );
    revalidatePath('/students');
    return { success: true, message: 'Thêm học viên mới thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function updateStudent(
  student_id: string,
  formData: {
    full_name: string;
    date_of_birth: string;
    phone_number: string;
    email?: string;
    status: string;
  }
) {
  try {
    await query(
      `UPDATE student
       SET full_name = $1, date_of_birth = $2, phone_number = $3, email = $4, status = $5, updated_at = CURRENT_TIMESTAMP
       WHERE student_id = $6 AND is_deleted = FALSE`,
      [formData.full_name.trim(), formData.date_of_birth, formData.phone_number.trim(), formData.email?.trim() || null, formData.status, student_id]
    );
    revalidatePath('/students');
    return { success: true, message: 'Cập nhật thông tin học viên thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function deleteStudent(student_id: string) {
  try {
    await query(`UPDATE student SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE student_id = $1`, [student_id]);
    revalidatePath('/students');
    return { success: true, message: 'Đã xóa học viên' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

// =========================================================================
// YÊU CẦU 2: HIỂN THỊ KẾT QUẢ HỌC TẬP CỦA HỌC VIÊN
// =========================================================================
export async function getStudentTranscript(student_id: string) {
  try {
    // 1. Lấy thông tin học viên
    const stuRes = await query(
      `SELECT student_id, full_name, email, phone_number, status FROM student WHERE student_id = $1 AND is_deleted = FALSE`,
      [student_id]
    );
    if (stuRes.rows.length === 0) {
      return { success: false, error: 'Không tìm thấy học viên với mã đã nhập.' };
    }

    // 2. Gọi Function nghiệp vụ fn_get_student_academic_transcript
    const transcriptRes = await query(
      `SELECT * FROM fn_get_student_academic_transcript($1)`,
      [student_id]
    );

    // 3. Truy vấn tổng hợp điểm lần thi mới nhất & GPA của mỗi khóa học
    const gpaRes = await query(
      `WITH latest_scores AS (
        SELECT 
            er.student_id,
            er.class_id,
            er.subject_id,
            er.score,
            er.attempt_number,
            ROW_NUMBER() OVER (PARTITION BY er.student_id, er.class_id, er.subject_id ORDER BY er.attempt_number DESC) AS rn
        FROM exam_result er
        WHERE er.student_id = $1 AND er.is_deleted = FALSE
      )
      SELECT 
        c.class_id,
        c.class_name,
        p.program_name,
        ROUND(AVG(ls.score), 2) AS class_gpa,
        COUNT(ls.subject_id) AS graded_subjects_count
      FROM enrollment e
      JOIN class c ON e.class_id = c.class_id
      JOIN program p ON c.program_id = p.program_id
      LEFT JOIN latest_scores ls ON e.class_id = ls.class_id AND ls.rn = 1
      WHERE e.student_id = $1 AND e.is_deleted = FALSE
      GROUP BY c.class_id, c.class_name, p.program_name`,
      [student_id]
    );

    return {
      success: true,
      student: stuRes.rows[0],
      transcript: transcriptRes.rows,
      classSummaries: gpaRes.rows,
    };
  } catch (error: any) {
    console.error('getStudentTranscript error:', error);
    return { success: false, error: error.message };
  }
}
