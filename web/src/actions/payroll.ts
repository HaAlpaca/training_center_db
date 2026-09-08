'use server';

import { query } from '@/lib/db';

// =========================================================================
// YÊU CẦU 4: TÍNH LƯƠNG CHO GIẢNG VIÊN TRONG MỘT THÁNG
// =========================================================================
export async function calculateInstructorSalary(
  month: number,
  year: number,
  baseHourlyRate: number
) {
  try {
    if (!month || month < 1 || month > 12) {
      return { success: false, error: 'Tháng không hợp lệ (1-12).' };
    }
    if (!year || year < 2020) {
      return { success: false, error: 'Năm không hợp lệ.' };
    }
    if (!baseHourlyRate || baseHourlyRate <= 0) {
      return { success: false, error: 'Đơn giá giờ dạy phải lớn hơn 0.' };
    }

    const res = await query(
      `SELECT * FROM fn_calculate_instructor_salary($1, $2, $3)`,
      [month, year, baseHourlyRate]
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
    if (ratePerStudent < 0) {
      return { success: false, error: 'Đơn giá quản lý học viên không hợp lệ.' };
    }

    const res = await query(
      `SELECT * FROM fn_calculate_staff_salary($1)`,
      [ratePerStudent]
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
