'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

// --- NHAN_VIEN (NHÂN VIÊN & CÂY PHÂN CẤP) ---
export async function getStaffList(search?: string) {
  try {
    let sql = `
      SELECT 
        s.ma_nv AS staff_id,
        s.ho_ten AS full_name,
        s.gioi_tinh AS gender,
        s.ngay_sinh AS date_of_birth,
        s.email,
        s.so_dien_thoai AS phone_number,
        s.chuc_vu AS position,
        s.ma_nv_quan_ly AS manager_id,
        m.ho_ten AS manager_name,
        s.trang_thai AS status
      FROM nhan_vien s
      LEFT JOIN nhan_vien m ON s.ma_nv_quan_ly = m.ma_nv
      WHERE s.is_deleted = FALSE
    `;
    const params: any[] = [];
    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (s.ho_ten ILIKE $1 OR s.ma_nv ILIKE $1 OR s.chuc_vu ILIKE $1)`;
    }
    sql += ` ORDER BY s.ma_nv`;

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
      `INSERT INTO nhan_vien (ma_nv, ho_ten, gioi_tinh, ngay_sinh, email, so_dien_thoai, chuc_vu, ma_nv_quan_ly, trang_thai)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'DANG_LAM')`,
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

// --- GIAO_VIEN (GIẢNG VIÊN / TRỢ GIẢNG) ---
export async function getInstructorsList(search?: string) {
  try {
    let sql = `
      SELECT 
        i.ma_gv AS instructor_id,
        i.ho_ten AS full_name,
        i.email,
        i.so_dien_thoai AS phone_number,
        i.chuyen_mon AS specialization,
        i.hoc_vi AS degree,
        i.loai_hop_dong AS contract_type,
        i.luong_tro_giang_gio AS hourly_ta_rate
      FROM giao_vien i
      WHERE i.is_deleted = FALSE
    `;
    const params: any[] = [];
    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (i.ho_ten ILIKE $1 OR i.ma_gv ILIKE $1 OR i.chuyen_mon ILIKE $1)`;
    }
    sql += ` ORDER BY i.ma_gv`;

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
      `INSERT INTO giao_vien (ma_gv, ho_ten, email, so_dien_thoai, chuyen_mon, hoc_vi, loai_hop_dong)
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
