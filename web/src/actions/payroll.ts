'use server';

import { query } from '@/lib/db';

// =========================================================================
// YÊU CẦU 4: TÍNH LƯƠNG CHO GIẢNG VIÊN TRONG MỘT THÁNG
// =========================================================================
export async function calculateInstructorSalary(
  month: number,
  year: number,
  baseHourlyRate: number = 100000
) {
  try {
    if (!month || month < 1 || month > 12) {
      return { success: false, error: 'Tháng không hợp lệ (1-12).' };
    }
    if (!year || year < 2020) {
      return { success: false, error: 'Năm không hợp lệ.' };
    }

    const res = await query(
      `SELECT 
        ma_gv AS instructor_id,
        ho_ten_gv AS full_name,
        loai_hop_dong AS contract_type,
        gio_day_chinh AS teaching_hours,
        gio_tro_giang AS ta_hours,
        tong_luong AS total_salary
       FROM fn_tinh_luong_giao_vien($1, $2)`,
      [month, year]
    );

    // Tính tổng quỹ lương
    const totalPayroll = res.rows.reduce(
      (sum, row) => sum + parseFloat(row.total_salary || 0),
      0
    );

    return {
      success: true,
      data: res.rows,
      summary: {
        totalInstructors: res.rows.length,
        totalPayroll,
        month,
        year,
        baseHourlyRate,
      },
    };
  } catch (error: any) {
    console.error('calculateInstructorSalary error:', error);
    return { success: false, error: error.message, data: [] };
  }
}

// =========================================================================
// YÊU CẦU 5: TÍNH LƯƠNG CHO CÁC NHÂN VIÊN
// =========================================================================
export async function calculateStaffSalary(ratePerStudent: number = 50000) {
  try {
    const res = await query(
      `SELECT 
        ma_nv AS staff_id,
        ho_ten_nv AS full_name,
        chuc_vu AS staff_position,
        luong_co_dinh AS base_salary,
        so_nv_cap_duoi AS subordinates_count,
        phu_cap_quan_ly_nv AS management_bonus,
        tong_so_hoc_vien_ctdt AS managed_students_count,
        luong_quan_ly_ctdt AS program_management_pay,
        tong_thu_nhap AS total_income
       FROM fn_tinh_luong_nhan_vien()`
    );

    const totalPayroll = res.rows.reduce(
      (sum, row) => sum + parseFloat(row.total_income || 0),
      0
    );

    return {
      success: true,
      data: res.rows,
      summary: {
        totalStaff: res.rows.length,
        totalPayroll,
        ratePerStudent,
      },
    };
  } catch (error: any) {
    console.error('calculateStaffSalary error:', error);
    return { success: false, error: error.message, data: [] };
  }
}
