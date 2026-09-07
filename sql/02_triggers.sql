-- =========================================================================
-- HỆ CSDL QUẢN LÝ ĐÀO TẠO (ĐỀ TÀI 3) - POSTGRESQL DIALECT
-- PHẦN 2: PL/PGSQL TRIGGERS KIỂM SOÁT RÀNG BUỘC TOÀN VẸN
-- =========================================================================

-- 2.1. Ràng buộc: Mỗi CTĐT chỉ có tối đa 10 môn học
CREATE OR REPLACE FUNCTION fn_check_max_subjects_per_program()
RETURNS TRIGGER AS $$
DECLARE
    v_subject_count INT;
BEGIN
    SELECT COUNT(*) INTO v_subject_count
    FROM subject
    WHERE program_id = NEW.program_id AND is_deleted = FALSE;

    IF v_subject_count > 10 THEN
        RAISE EXCEPTION 'Mỗi chương trình đào tạo chỉ được phép có tối đa 10 môn học.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_max_subjects ON subject;
CREATE TRIGGER trg_check_max_subjects
AFTER INSERT OR UPDATE ON subject
FOR EACH ROW
EXECUTE FUNCTION fn_check_max_subjects_per_program();


-- 2.2. Ràng buộc: Tránh xung đột trùng phòng học
CREATE OR REPLACE FUNCTION fn_check_room_schedule_conflict()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM class_session
        WHERE room_id = NEW.room_id
          AND session_id <> COALESCE(NEW.session_id, -1)
          AND status <> 'CANCELED'
          AND is_deleted = FALSE
          AND NEW.status <> 'CANCELED'
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time
    ) THEN
        RAISE EXCEPTION 'Phòng học % đã có lịch học trong khoảng thời gian này.', NEW.room_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_room_conflict ON class_session;
CREATE TRIGGER trg_check_room_conflict
BEFORE INSERT OR UPDATE ON class_session
FOR EACH ROW
EXECUTE FUNCTION fn_check_room_schedule_conflict();


-- 2.3. Ràng buộc: Tránh xung đột trùng lịch giảng viên (Chính & Trợ giảng)
CREATE OR REPLACE FUNCTION fn_check_instructor_schedule_conflict()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM class_session
        WHERE session_id <> COALESCE(NEW.session_id, -1)
          AND status <> 'CANCELED'
          AND is_deleted = FALSE
          AND NEW.status <> 'CANCELED'
          AND (
              main_instructor_id = NEW.main_instructor_id
              OR (NEW.teaching_assistant_id IS NOT NULL AND main_instructor_id = NEW.teaching_assistant_id)
              OR (teaching_assistant_id IS NOT NULL AND teaching_assistant_id = NEW.main_instructor_id)
              OR (teaching_assistant_id IS NOT NULL AND NEW.teaching_assistant_id IS NOT NULL AND teaching_assistant_id = NEW.teaching_assistant_id)
          )
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time
    ) THEN
        RAISE EXCEPTION 'Giảng viên hoặc Trợ giảng đã có lịch giảng dạy khác trong khung giờ này.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_instructor_conflict ON class_session;
CREATE TRIGGER trg_check_instructor_conflict
BEFORE INSERT OR UPDATE ON class_session
FOR EACH ROW
EXECUTE FUNCTION fn_check_instructor_schedule_conflict();
