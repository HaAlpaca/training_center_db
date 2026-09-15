'use server';

import { query } from '@/lib/db';

export async function getDashboardData() {
  try {
    // 1. KPI Counts
    const countsRes = await query(`
      SELECT
        (SELECT COUNT(*) FROM hoc_vien WHERE is_deleted = FALSE) AS total_students,
        (SELECT COUNT(*) FROM chuong_trinh_dao_tao WHERE is_deleted = FALSE) AS total_programs,
        (SELECT COUNT(*) FROM khoa_dao_tao WHERE is_deleted = FALSE) AS total_classes,
        (SELECT COUNT(*) FROM giao_vien WHERE is_deleted = FALSE) AS total_instructors,
        (SELECT COUNT(*) FROM phong_hoc WHERE is_deleted = FALSE) AS total_rooms,
        (SELECT COUNT(*) FROM nhan_vien WHERE is_deleted = FALSE) AS total_staff
    `);
    const counts = countsRes.rows[0] || {
      total_students: 0,
      total_programs: 0,
      total_classes: 0,
      total_instructors: 0,
      total_rooms: 0,
      total_staff: 0,
    };

    // 2. Class Enrollment Summary View
    const enrollmentRes = await query(`
      SELECT 
        ma_khoa AS class_id,
        ten_khoa AS class_name,
        ten_ctdt AS program_name,
        ten_ky_hoc AS semester_name,
        100 AS max_capacity,
        so_hoc_vien_dang_ky AS current_students,
        (100 - so_hoc_vien_dang_ky) AS remaining_slots,
        tong_hoc_phi_thu_duoc AS total_tuition_collected,
        trang_thai AS class_status
      FROM v_thong_ke_khoa_dao_tao
      ORDER BY ma_khoa
    `);

    // 3. Subject Pass Rate View
    const passRateRes = await query(`
      SELECT 
        ma_lop_mon AS class_id,
        ten_khoa AS class_name,
        ma_mon AS subject_id,
        ten_mon AS subject_name,
        tong_so_hv_du_thi AS total_candidates,
        so_hv_dat AS passed_count,
        so_hv_chua_dat AS failed_count,
        ty_le_dat_phan_tram AS pass_rate_percent
      FROM v_ty_le_dat_mon_hoc
      ORDER BY ma_lop_mon, ma_mon
    `);

    // 4. Program Distribution (Students & Revenue)
    const programDistRes = await query(`
      SELECT 
        ct.ma_ctdt AS program_id,
        ct.ten_ctdt AS program_name,
        COUNT(dk.ma_hv)::int AS student_count,
        COALESCE(SUM(dk.hoc_phi_da_dong), 0)::numeric AS total_revenue
      FROM chuong_trinh_dao_tao ct
      LEFT JOIN khoa_dao_tao k ON ct.ma_ctdt = k.ma_ctdt AND k.is_deleted = FALSE
      LEFT JOIN dang_ky_khoa_hoc dk ON k.ma_khoa = dk.ma_khoa AND dk.trang_thai != 'HUY'
      WHERE ct.is_deleted = FALSE
      GROUP BY ct.ma_ctdt, ct.ten_ctdt
      ORDER BY student_count DESC
    `);

    // 5. Instructor Degree & Contract Breakdown
    const instructorDegreesRes = await query(`
      SELECT hoc_vi AS degree, COUNT(*)::int AS count
      FROM giao_vien
      WHERE is_deleted = FALSE
      GROUP BY hoc_vi
      ORDER BY count DESC
    `);

    const instructorContractsRes = await query(`
      SELECT loai_hop_dong AS contract_type, COUNT(*)::int AS count
      FROM giao_vien
      WHERE is_deleted = FALSE
      GROUP BY loai_hop_dong
      ORDER BY count DESC
    `);

    return {
      success: true,
      counts: {
        totalStudents: Number(counts.total_students),
        totalPrograms: Number(counts.total_programs),
        totalClasses: Number(counts.total_classes),
        totalInstructors: Number(counts.total_instructors),
        totalRooms: Number(counts.total_rooms),
        totalStaff: Number(counts.total_staff),
      },
      enrollmentSummary: enrollmentRes.rows,
      passRates: passRateRes.rows,
      programDistribution: programDistRes.rows,
      instructorDegrees: instructorDegreesRes.rows,
      instructorContracts: instructorContractsRes.rows,
    };
  } catch (error: any) {
    console.error('Error fetching dashboard data:', error);
    return {
      success: false,
      error: error.message || 'Không thể tải dữ liệu bảng điều khiển',
      counts: {
        totalStudents: 0,
        totalPrograms: 0,
        totalClasses: 0,
        totalInstructors: 0,
        totalRooms: 0,
        totalStaff: 0,
      },
      enrollmentSummary: [],
      passRates: [],
      programDistribution: [],
      instructorDegrees: [],
      instructorContracts: [],
    };
  }
}
