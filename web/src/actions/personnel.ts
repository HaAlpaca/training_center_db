'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

// --- STAFF (NHÂN VIÊN & CÂY PHÂN CẤP) ---
export async function getStaffList(search?: string) {
  try {
    let sql = `
      SELECT 
        s.staff_id,
        s.full_name,
        s.gender,
        s.date_of_birth,
        s.email,
        s.phone_number,
        s.position,
        s.manager_id,
        m.full_name AS manager_name,
        s.status
      FROM staff s
      LEFT JOIN staff m ON s.manager_id = m.staff_id
      WHERE s.is_deleted = FALSE
    `;
    const params: any[] = [];
    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (s.full_name ILIKE $1 OR s.staff_id ILIKE $1 OR s.position ILIKE $1)`;
    }
    sql += ` ORDER BY s.staff_id`;

    const res = await query(sql, params);
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}

export async function createStaff(formData: {
  staff_id: string;
  full_name: string;
  gender: number;
  date_of_birth: string;
  email: string;
  phone_number: string;
  position: string;
  manager_id?: string | null;
}) {
  try {
    await query(
      `INSERT INTO staff (staff_id, full_name, gender, date_of_birth, email, phone_number, position, manager_id, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'Active')`,
      [
        formData.staff_id.trim().toUpperCase(),
        formData.full_name.trim(),
        formData.gender,
        formData.date_of_birth,
        formData.email.trim(),
        formData.phone_number.trim(),
        formData.position.trim(),
        formData.manager_id || null,
      ]
    );
    revalidatePath('/personnel');
    return { success: true, message: 'Thêm nhân viên thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

// --- INSTRUCTOR (GIẢNG VIÊN) ---
export async function getInstructorsList(search?: string) {
  try {
    let sql = `
      SELECT 
        i.instructor_id,
        i.full_name,
        i.email,
        i.phone_number,
        i.specialization,
        i.degree,
        i.contract_type
      FROM instructor i
      WHERE i.is_deleted = FALSE
    `;
    const params: any[] = [];
    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (i.full_name ILIKE $1 OR i.instructor_id ILIKE $1 OR i.specialization ILIKE $1)`;
    }
    sql += ` ORDER BY i.instructor_id`;

    const res = await query(sql, params);
    return { success: true, data: res.rows };
  } catch (error: any) {
    return { success: false, error: error.message, data: [] };
  }
}

export async function createInstructor(formData: {
  instructor_id: string;
  full_name: string;
  email: string;
  phone_number: string;
  specialization: string;
  degree: string;
  contract_type: 'FULLTIME' | 'PARTTIME';
}) {
  try {
    await query(
      `INSERT INTO instructor (instructor_id, full_name, email, phone_number, specialization, degree, contract_type)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        formData.instructor_id.trim().toUpperCase(),
        formData.full_name.trim(),
        formData.email.trim(),
        formData.phone_number.trim(),
        formData.specialization.trim(),
        formData.degree.trim(),
        formData.contract_type,
      ]
    );
    revalidatePath('/personnel');
    return { success: true, message: 'Thêm giảng viên thành công' };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
