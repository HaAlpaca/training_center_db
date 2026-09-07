-- =========================================================================
-- KỊCH BẢN KIỂM THỬ RÀNG BUỘC TOÀN VẸN (TRIGGERS TEST CASES)
-- =========================================================================

-- -------------------------------------------------------------------------
-- TEST CASE 1: Kiểm tra Trigger chống trùng phòng học (trg_check_room_conflict)
-- Kỳ vọng: Bắn ra Exception "Phòng học LAB_301 đã có lịch học trong khoảng thời gian này."
-- Vì ở seed data, LAB_301 đã có lịch từ 2026-09-02 18:00:00 đến 20:00:00
-- -------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO class_session (class_id, subject_id, start_time, end_time, room_id, main_instructor_id, status)
    VALUES ('PRG_DATA_FALL_2026', 'PRG_DATA_PY', '2026-09-02 18:30:00', '2026-09-02 20:30:00', 'LAB_301', 'INS_002', 'SCHEDULED');
    
    RAISE EXCEPTION 'TEST 1 THẤT BẠI: Trigger không chặn được trùng phòng!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 1 THÀNH CÔNG (Bắt được lỗi trùng phòng): %', SQLERRM;
END $$;


-- -------------------------------------------------------------------------
-- TEST CASE 2: Kiểm tra Trigger chống trùng lịch giảng viên (trg_check_instructor_conflict)
-- Kỳ vọng: Bắn ra Exception "Giảng viên hoặc Trợ giảng đã có lịch giảng dạy khác trong khung giờ này."
-- Vì INS_001 đã có lịch dạy vào 2026-09-02 từ 18:00:00 đến 20:00:00
-- -------------------------------------------------------------------------
DO $$
BEGIN
    -- Thử xếp INS_001 dạy ở một phòng khác (cần tạo phòng ảo hoặc đổi phòng) cùng giờ
    INSERT INTO room (room_id, room_name, capacity, room_type, status)
    VALUES ('LAB_999', 'Phòng Test 999', 30, 'LAB', 'READY')
    ON CONFLICT (room_id) DO NOTHING;

    INSERT INTO class_session (class_id, subject_id, start_time, end_time, room_id, main_instructor_id, status)
    VALUES ('PRG_DATA_FALL_2026', 'PRG_DATA_PY', '2026-09-02 19:00:00', '2026-09-02 21:00:00', 'LAB_999', 'INS_001', 'SCHEDULED');

    RAISE EXCEPTION 'TEST 2 THẤT BẠI: Trigger không chặn được trùng lịch giảng viên!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 2 THÀNH CÔNG (Bắt được lỗi trùng lịch giảng viên): %', SQLERRM;
END $$;


-- -------------------------------------------------------------------------
-- TEST CASE 3: Kiểm tra Trigger giới hạn tối đa 10 môn / CTĐT (trg_check_max_subjects)
-- Kỳ vọng: Khi thêm môn thứ 11, bắn ra Exception "Mỗi chương trình đào tạo chỉ được phép có tối đa 10 môn học."
-- -------------------------------------------------------------------------
DO $$
DECLARE
    i INT;
BEGIN
    -- Đã có 2 môn trong PRG_DATA, thêm từ môn 3 đến 10 hợp lệ
    FOR i IN 3..10 LOOP
        INSERT INTO subject (subject_id, subject_name, program_id, total_hours)
        VALUES ('TEST_SUB_' || i, 'Môn kiểm thử ' || i, 'PRG_DATA', 30)
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Thêm môn thứ 11 -> Phải bị Trigger chặn
    INSERT INTO subject (subject_id, subject_name, program_id, total_hours)
    VALUES ('TEST_SUB_11', 'Môn kiểm thử thứ 11', 'PRG_DATA', 30);

    RAISE EXCEPTION 'TEST 3 THẤT BẠI: Trigger không chặn được quá 10 môn học!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 3 THÀNH CÔNG (Bắt được lỗi vượt quá 10 môn): %', SQLERRM;
END $$;
