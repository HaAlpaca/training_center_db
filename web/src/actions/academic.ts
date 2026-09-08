'use server';

import { query } from '@/lib/db';

// =========================================================================
// YÊU CẦU 3: LIỆT KÊ TOÀN BỘ CÁC HỌC VIÊN CHƯA HOÀN THÀNH XONG CÁC MÔN HỌC
// CỦA KHÓA ĐÀO TẠO KÈM ĐIỂM THI CỦA CÁC LẦN DỰ THI CHƯA ĐẠT (NẾU ĐÃ DỰ THI)
// =========================================================================
export async function getIncompleteStudentsByClass(class_id: string) {
  try {
    const res = await query(
      `WITH class_target_subjects AS (
          SELECT c.class_id, c.class_name, s.subject_id, s.subject_name
          FROM class c
          JOIN subject s ON c.program_id = s.program_id
          WHERE c.class_id = $1 AND s.is_deleted = FALSE
      ),
      failed_attempts AS (
          SELECT 
              er.student_id,
              er.class_id,
              er.subject_id,
              STRING_AGG(
                  'Lần ' || er.attempt_number || ': ' || er.score || ' điểm (Ngày ' || TO_CHAR(er.exam_date, 'DD/MM/YYYY') || ')', 
                  '; ' ORDER BY er.attempt_number
              ) AS failed_exam_history,
              MAX(er.score) AS highest_failed_score,
              COUNT(*) AS total_failed_attempts
          FROM exam_result er
          WHERE er.class_id = $1
            AND er.score <= 5.0
            AND er.is_deleted = FALSE
          GROUP BY er.student_id, er.class_id, er.subject_id
      ),
      passed_subjects AS (
          SELECT DISTINCT er.student_id, er.class_id, er.subject_id
          FROM exam_result er
          WHERE er.class_id = $1
            AND er.score > 5.0
            AND er.is_deleted = FALSE
      )
      SELECT 
          e.student_id,
          st.full_name AS student_name,
          cts.class_id,
          cts.class_name,
          cts.subject_id,
          cts.subject_name,
          CASE 
              WHEN fa.total_failed_attempts IS NOT NULL THEN 'Chưa đạt (Thi rớt)'
              ELSE 'Chưa hoàn thành (Chưa dự thi)'
          END AS completion_status,
          COALESCE(fa.failed_exam_history, 'Chưa có lượt thi nào') AS failed_exam_details,
          COALESCE(fa.total_failed_attempts, 0) AS failed_attempts_count
      FROM enrollment e
      JOIN student st ON e.student_id = st.student_id
      CROSS JOIN class_target_subjects cts
      LEFT JOIN passed_subjects ps 
             ON e.student_id = ps.student_id 
            AND cts.subject_id = ps.subject_id
      LEFT JOIN failed_attempts fa 
             ON e.student_id = fa.student_id 
            AND cts.subject_id = fa.subject_id
      WHERE e.class_id = $1
        AND e.is_deleted = FALSE
        AND ps.subject_id IS NULL
      ORDER BY e.student_id, cts.subject_id;`,
      [class_id]
    );

    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getIncompleteStudentsByClass error:', error);
    return { success: false, error: error.message, data: [] };
  }
}
