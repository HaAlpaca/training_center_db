'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getStudents(search?: string) {
  try {
    let sql = `
      SELECT 
        s.ma_hv AS student_id,
        s.ho_ten AS full_name,
        s.ngay_sinh AS date_of_birth,
        s.so_dien_thoai AS phone_number,
        s.email,
        s.dia_chi AS source,
        s.trang_thai AS status,
        COUNT(e.ma_khoa) AS enrolled_classes_count
      FROM hoc_vien s
      LEFT JOIN dang_ky_khoa_hoc e ON s.ma_hv = e.ma_hv AND e.is_deleted = FALSE
      WHERE s.is_deleted = FALSE
    `;
    const params: any[] = [];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (s.ho_ten ILIKE $1 OR s.ma_hv ILIKE $1 OR s.so_dien_thoai ILIKE $1 OR s.email ILIKE $1)`;
    }

    sql += ` GROUP BY s.ma_hv, s.ho_ten, s.ngay_sinh, s.so_dien_thoai, s.email, s.dia_chi, s.trang_thai
             ORDER BY s.ma_hv`;

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
      `INSERT INTO hoc_vien (ma_hv, ho_ten, ngay_sinh, so_dien_thoai, email, dia_chi, trang_thai)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        formData.student_id.trim().toUpperCase(),
        formData.full_name.trim(),
        formData.date_of_birth || null,
        formData.phone_number.trim(),
        formData.email?.trim() || null,
        formData.source || null,
        formData.status || 'DANG_HOC',
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
      `UPDATE hoc_vien
       SET ho_ten = $1, ngay_sinh = $2, so_dien_thoai = $3, email = $4, trang_thai = $5, updated_at = CURRENT_TIMESTAMP
       WHERE ma_hv = $6 AND is_deleted = FALSE`,
      [formData.full_name.trim(), formData.date_of_birth || null, formData.phone_number.trim(), formData.email?.trim() || null, formData.status, student_id]
    );
    revalidatePath('/students');
    return { success: true, message: 'Cập nhật thông tin học viên thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function deleteStudent(student_id: string) {
  try {
    await query(`UPDATE hoc_vien SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE ma_hv = $1`, [student_id]);
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
      `SELECT ma_hv AS student_id, ho_ten AS full_name, email, so_dien_thoai AS phone_number, trang_thai AS status FROM hoc_vien WHERE ma_hv = $1 AND is_deleted = FALSE`,
      [student_id]
    );
    if (stuRes.rows.length === 0) {
      return { success: false, error: 'Không tìm thấy học viên với mã đã nhập.' };
    }

    // 2. Gọi Function nghiệp vụ fn_bang_diem_hoc_vien
    const transcriptRes = await query(
      `SELECT 
        ma_hv AS student_id,
        ho_ten_hv AS student_name,
        ma_khoa AS class_id,
        ten_khoa AS class_name,
        ma_mon AS subject_id,
        ten_mon AS subject_name,
        lan_thi AS attempt_number,
        diem_thi AS score,
        ngay_thi AS exam_date,
        ket_qua AS evaluation
       FROM fn_bang_diem_hoc_vien($1)`,
      [student_id]
    );

    // 3. Truy vấn tổng hợp điểm lần thi mới nhất & GPA của mỗi khóa học
    const gpaRes = await query(
      `WITH latest_scores AS (
        SELECT 
            kq.ma_hv,
            lm.ma_khoa,
            lm.ma_mon,
            kq.diem_thi,
            kq.lan_thi,
            ROW_NUMBER() OVER (PARTITION BY kq.ma_hv, lm.ma_khoa, lm.ma_mon ORDER BY kq.lan_thi DESC) AS rn
        FROM ket_qua_thi kq
        JOIN lop_mon_hoc lm ON kq.ma_lop_mon = lm.ma_lop_mon
        WHERE kq.ma_hv = $1 AND kq.is_deleted = FALSE
      )
      SELECT 
        c.ma_khoa AS class_id,
        c.ten_khoa AS class_name,
        p.ten_ctdt AS program_name,
        ROUND(AVG(ls.diem_thi), 2) AS class_gpa,
        COUNT(ls.ma_mon) AS graded_subjects_count
      FROM dang_ky_khoa_hoc e
      JOIN khoa_dao_tao c ON e.ma_khoa = c.ma_khoa
      JOIN chuong_trinh_dao_tao p ON c.ma_ctdt = p.ma_ctdt
      LEFT JOIN latest_scores ls ON e.ma_khoa = ls.ma_khoa AND ls.rn = 1
      WHERE e.ma_hv = $1 AND e.is_deleted = FALSE
      GROUP BY c.ma_khoa, c.ten_khoa, p.ten_ctdt`,
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
