'use server';

import { query } from '@/lib/db';

export async function getDashboardData() {
  try {
    // 1. KPI Counts
    const countsRes = await query(`
      SELECT
        (SELECT COUNT(*) FROM student WHERE is_deleted = FALSE) AS total_students,
        (SELECT COUNT(*) FROM program WHERE is_deleted = FALSE) AS total_programs,
        (SELECT COUNT(*) FROM class WHERE is_deleted = FALSE) AS total_classes,
        (SELECT COUNT(*) FROM instructor WHERE is_deleted = FALSE) AS total_instructors,
        (SELECT COUNT(*) FROM room WHERE is_deleted = FALSE) AS total_rooms,
        (SELECT COUNT(*) FROM staff WHERE is_deleted = FALSE) AS total_staff
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
        class_id,
        class_name,
        program_name,
        semester_name,
        max_capacity,
        current_students,
        remaining_slots,
        total_tuition_collected,
        class_status
      FROM v_class_enrollment_summary
      ORDER BY class_id
    `);

    // 3. Subject Pass Rate View
    const passRateRes = await query(`
      SELECT 
        class_id,
        class_name,
        subject_id,
        subject_name,
        total_candidates,
        passed_count,
        failed_count,
        pass_rate_percent
      FROM v_subject_pass_rate
      ORDER BY class_id, subject_id
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
    };
  }
}
