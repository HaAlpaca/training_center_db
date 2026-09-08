'use server';

import { query } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function getClassSessions() {
  try {
    const res = await query(
      `SELECT 
        cs.session_id,
        cs.class_id,
        c.class_name,
        cs.subject_id,
        sub.subject_name,
        cs.room_id,
        r.room_name,
        r.location,
        cs.start_time,
        cs.end_time,
        cs.main_instructor_id,
        ins.full_name AS main_instructor_name,
        cs.teaching_assistant_id,
        ta.full_name AS teaching_assistant_name,
        cs.session_type,
        cs.status
       FROM class_session cs
       JOIN class c ON cs.class_id = c.class_id
       JOIN subject sub ON cs.subject_id = sub.subject_id
       JOIN room r ON cs.room_id = r.room_id
       JOIN instructor ins ON cs.main_instructor_id = ins.instructor_id
       LEFT JOIN instructor ta ON cs.teaching_assistant_id = ta.instructor_id
       WHERE cs.is_deleted = FALSE
       ORDER BY cs.start_time ASC`
    );

    return { success: true, data: res.rows };
  } catch (error: any) {
    console.error('getClassSessions error:', error);
    return { success: false, error: error.message, data: [] };
  }
}

// =========================================================================
// YÊU CẦU 6: TẠO BUỔI HỌC VỚI KIỂM TRA XUNG ĐỘT PHÒNG VÀ LỊCH GIẢNG VIÊN
// (Bắt lỗi trực tiếp từ Trigger trg_check_room_conflict & trg_check_instructor_conflict)
// =========================================================================
export async function createClassSession(formData: {
  class_id: string;
  subject_id: string;
  room_id: string;
  start_time: string; // ISO String format YYYY-MM-DD HH:mm:ss
  end_time: string;
  main_instructor_id: string;
  teaching_assistant_id?: string | null;
  session_type?: 'NORMAL' | 'MAKEUP' | 'EXAM';
}) {
  try {
    // 1. Kiểm tra thời gian logic
    const start = new Date(formData.start_time);
    const end = new Date(formData.end_time);
    if (end <= start) {
      return { success: false, error: 'Thời gian kết thúc phải lớn hơn thời gian bắt đầu!' };
    }

    // 2. Thực thi Insert xuống PostgreSQL
    // Nếu có xung đột, Database Trigger sẽ kích hoạt RAISE EXCEPTION
    await query(
      `INSERT INTO class_session (
        class_id, subject_id, room_id, start_time, end_time, 
        main_instructor_id, teaching_assistant_id, session_type, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'SCHEDULED')`,
      [
        formData.class_id,
        formData.subject_id,
        formData.room_id,
        formData.start_time,
        formData.end_time,
        formData.main_instructor_id,
        formData.teaching_assistant_id || null,
        formData.session_type || 'NORMAL',
      ]
    );

    revalidatePath('/schedule');
    return { success: true, message: 'Xếp lịch buổi học thành công!' };
  } catch (error: any) {
    // Bắt thông điệp lỗi chính xác do PostgreSQL Trigger bắn ra
    const errorMsg = error?.message || 'Có lỗi xảy ra khi xếp lịch';
    console.warn('[Conflict Trigger Caught]:', errorMsg);
    return {
      success: false,
      error: errorMsg,
      isTriggerViolation: true,
    };
  }
}

export async function getScheduleMetadata() {
  try {
    const [classesRes, subjectsRes, roomsRes, instructorsRes] = await Promise.all([
      query(`SELECT class_id, class_name FROM class WHERE is_deleted = FALSE AND status <> 'CLOSED' ORDER BY class_name`),
      query(`SELECT subject_id, subject_name, program_id FROM subject WHERE is_deleted = FALSE ORDER BY subject_name`),
      query(`SELECT room_id, room_name, capacity, room_type FROM room WHERE is_deleted = FALSE AND status = 'READY' ORDER BY room_id`),
      query(`SELECT instructor_id, full_name, contract_type FROM instructor WHERE is_deleted = FALSE ORDER BY full_name`),
    ]);

    return {
      success: true,
      classes: classesRes.rows,
      subjects: subjectsRes.rows,
      rooms: roomsRes.rows,
      instructors: instructorsRes.rows,
    };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
