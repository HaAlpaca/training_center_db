'use client';

import React, { useState, useEffect } from 'react';
import {
  getClassSessions,
  createClassSession,
  getScheduleMetadata,
} from '@/actions/schedule';

export default function SchedulePage() {
  const [sessions, setSessions] = useState<any[]>([]);
  const [metadata, setMetadata] = useState<any>({
    classes: [],
    subjects: [],
    rooms: [],
    instructors: [],
  });
  const [loading, setLoading] = useState(true);

  // Modal Xếp Buổi Học
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState({
    class_id: '',
    subject_id: '',
    room_id: '',
    start_time: '2026-10-10 18:00:00',
    end_time: '2026-10-10 20:00:00',
    main_instructor_id: '',
    teaching_assistant_id: '',
    session_type: 'NORMAL' as 'NORMAL' | 'MAKEUP' | 'EXAM',
  });

  const [triggerAlert, setTriggerAlert] = useState<{
    message: string;
    type: 'success' | 'error' | 'trigger';
  } | null>(null);

  const loadData = async () => {
    setLoading(true);
    const [sessRes, metaRes] = await Promise.all([
      getClassSessions(),
      getScheduleMetadata(),
    ]);

    if (sessRes.success && sessRes.data) setSessions(sessRes.data);
    if (metaRes.success && metaRes.classes) {
      setMetadata(metaRes);
      if (metaRes.classes.length > 0 && !form.class_id) {
        setForm((prev) => ({
          ...prev,
          class_id: metaRes.classes![0].class_id,
          subject_id: metaRes.subjects?.[0]?.subject_id || '',
          room_id: metaRes.rooms?.[0]?.room_id || '',
          main_instructor_id: metaRes.instructors?.[0]?.instructor_id || '',
        }));
      }
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData();
  }, []);

  // Submit normal session
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setTriggerAlert(null);
    const res = await createClassSession(form);
    if (res.success) {
      setTriggerAlert({ message: res.message || 'Xếp lịch thành công!', type: 'success' });
      setIsModalOpen(false);
      loadData();
    } else {
      setTriggerAlert({
        message: res.error,
        type: res.isTriggerViolation ? 'trigger' : 'error',
      });
    }
  };

  // TEST CASE 1: Cố tình vi phạm Trigger trùng phòng học (LAB_301 ngày 02/09/2026 lúc 18:30 - 20:30)
  const testRoomConflict = async () => {
    setTriggerAlert(null);
    const conflictPayload = {
      class_id: metadata.classes[0]?.class_id || 'PRG_DATA_FALL_2026',
      subject_id: metadata.subjects[0]?.subject_id || 'PRG_DATA_SQL',
      room_id: 'LAB_301',
      start_time: '2026-09-02 18:30:00', // Đã có lớp học từ 18:00 - 20:00
      end_time: '2026-09-02 20:30:00',
      main_instructor_id: 'INS_003',
      teaching_assistant_id: null,
      session_type: 'NORMAL' as const,
    };

    const res = await createClassSession(conflictPayload);
    if (!res.success) {
      setTriggerAlert({
        message: `[KÍCH HOẠT TRIGGER THÀNH CÔNG] PostgreSQL trg_check_room_conflict chặn lại:\n${res.error}`,
        type: 'trigger',
      });
    } else {
      alert('Tạo thành công (Không bị chặn)');
      loadData();
    }
  };

  // TEST CASE 2: Cố tình vi phạm Trigger trùng lịch giảng viên (INS_001 ngày 02/09/2026 lúc 19:00 - 21:00)
  const testInstructorConflict = async () => {
    setTriggerAlert(null);
    const conflictPayload = {
      class_id: 'PRG_WEB_FALL_2026',
      subject_id: 'PRG_WEB_HTML',
      room_id: 'LAB_302', // Phòng khác không trùng
      start_time: '2026-09-02 19:00:00', // INS_001 đang dạy ở LAB_301 từ 18:00 - 20:00
      end_time: '2026-09-02 21:00:00',
      main_instructor_id: 'INS_001',
      teaching_assistant_id: null,
      session_type: 'NORMAL' as const,
    };

    const res = await createClassSession(conflictPayload);
    if (!res.success) {
      setTriggerAlert({
        message: `[KÍCH HOẠT TRIGGER THÀNH CÔNG] PostgreSQL trg_check_instructor_conflict chặn lại:\n${res.error}`,
        type: 'trigger',
      });
    } else {
      alert('Tạo thành công (Không bị chặn)');
      loadData();
    }
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <div className="inline-flex items-center gap-2 rounded-md bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 mb-2">
          Yêu Cầu 6 Đề Bài • Ràng Buộc Triggers
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Lịch Giảng Dạy & Kiểm Thử Ràng Buộc Toàn Vẹn
        </h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Thời lượng mỗi buổi học đúng 2 giờ. Hệ thống tự động ngăn chặn xung đột trùng phòng học (
          <code className="text-brand-500">trg_check_room_conflict</code>) và trùng lịch giảng viên/trợ giảng (
          <code className="text-brand-500">trg_check_instructor_conflict</code>).
        </p>
      </div>

      {/* Trigger Simulation Controls Banner */}
      <div className="rounded-2xl border border-dashed border-amber-300 bg-amber-50/60 p-5 dark:border-amber-700/50 dark:bg-amber-900/10">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="text-sm font-bold text-amber-900 dark:text-amber-200">
              ⚡ Kịch Bản Kiểm Thử Ràng Buộc Toàn Vẹn Tự Động (Triggers Demo)
            </h2>
            <p className="text-xs text-amber-700 dark:text-amber-300 mt-0.5">
              Bấm thử các nút bên dưới để xem phản ứng bắt lỗi thời gian thực từ Database Triggers PostgreSQL:
            </p>
          </div>
          <div className="flex flex-wrap gap-2.5">
            <button
              onClick={testRoomConflict}
              className="rounded-lg bg-red-600 hover:bg-red-700 px-3.5 py-2 text-xs font-bold text-white transition shadow-sm"
            >
              🛑 Thử Xếp Trùng Phòng (LAB_301)
            </button>
            <button
              onClick={testInstructorConflict}
              className="rounded-lg bg-purple-600 hover:bg-purple-700 px-3.5 py-2 text-xs font-bold text-white transition shadow-sm"
            >
              🛑 Thử Xếp Trùng Lịch GV (INS_001)
            </button>
            <button
              onClick={() => setIsModalOpen(true)}
              className="rounded-lg bg-brand-500 hover:bg-brand-600 px-3.5 py-2 text-xs font-bold text-white transition shadow-sm"
            >
              ➕ Xếp Lịch Mới
            </button>
          </div>
        </div>

        {/* Trigger Alert Display */}
        {triggerAlert && (
          <div
            className={`mt-4 p-4 rounded-xl text-xs font-mono whitespace-pre-line border ${
              triggerAlert.type === 'trigger'
                ? 'bg-red-100 text-red-900 border-red-300 dark:bg-red-950/50 dark:text-red-200 dark:border-red-800'
                : triggerAlert.type === 'success'
                ? 'bg-green-100 text-green-900 border-green-300 dark:bg-green-950/50 dark:text-green-200 dark:border-green-800'
                : 'bg-amber-100 text-amber-900 border-amber-300'
            }`}
          >
            {triggerAlert.message}
          </div>
        )}
      </div>

      {/* Schedule Table */}
      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="p-4 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
          <h3 className="text-sm font-bold text-gray-900 dark:text-white">
            Danh Sách Buổi Học Đã Lên Lịch ({sessions.length} buổi)
          </h3>
          <span className="text-xs text-gray-400">Thời lượng chuẩn: 2 giờ/buổi</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
              <tr>
                <th className="px-4 py-3.5">Thời Gian (Khung Giờ)</th>
                <th className="px-4 py-3.5">Khóa Đào Tạo</th>
                <th className="px-4 py-3.5">Môn Học</th>
                <th className="px-4 py-3.5">Phòng Học</th>
                <th className="px-4 py-3.5">Giảng Viên Chính</th>
                <th className="px-4 py-3.5">Trợ Giảng</th>
                <th className="px-4 py-3.5 text-center">Trạng Thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    Đang tải lịch học...
                  </td>
                </tr>
              ) : sessions.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    Chưa có lịch học nào
                  </td>
                </tr>
              ) : (
                sessions.map((s) => {
                  const start = new Date(s.start_time);
                  const end = new Date(s.end_time);
                  const isCompleted = s.status === 'COMPLETED';

                  return (
                    <tr key={s.session_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-mono text-xs">
                        <span className="font-bold text-gray-900 dark:text-white block">
                          {start.toLocaleDateString('vi-VN')}
                        </span>
                        <span className="text-gray-400 text-[11px]">
                          {start.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} -{' '}
                          {end.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} (2h)
                        </span>
                      </td>
                      <td className="px-4 py-3.5 font-medium text-xs text-gray-900 dark:text-white">
                        {s.class_name}
                      </td>
                      <td className="px-4 py-3.5 font-semibold text-xs text-brand-600">
                        {s.subject_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs">
                        <span className="inline-block font-mono font-semibold px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300">
                          {s.room_id}
                        </span>
                        <span className="block text-[10px] text-gray-400">{s.room_name}</span>
                      </td>
                      <td className="px-4 py-3.5 text-xs font-medium text-gray-900 dark:text-white">
                        {s.main_instructor_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs text-gray-500">
                        {s.teaching_assistant_name || '—'}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span
                          className={`inline-block px-2.5 py-0.5 rounded text-[10px] font-bold ${
                            isCompleted
                              ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
                              : 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
                          }`}
                        >
                          {s.status}
                        </span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Xếp Buổi Học Mới */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              Xếp Buổi Học Mới (Kiểm Tra Xung Đột)
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Khóa Đào Tạo *
                </label>
                <select
                  value={form.class_id}
                  onChange={(e) => setForm({ ...form, class_id: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                >
                  {metadata.classes.map((c: any) => (
                    <option key={c.class_id} value={c.class_id}>
                      {c.class_name} ({c.class_id})
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Môn Học *
                  </label>
                  <select
                    value={form.subject_id}
                    onChange={(e) => setForm({ ...form, subject_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {metadata.subjects.map((s: any) => (
                      <option key={s.subject_id} value={s.subject_id}>
                        {s.subject_name}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Phòng Học *
                  </label>
                  <select
                    value={form.room_id}
                    onChange={(e) => setForm({ ...form, room_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {metadata.rooms.map((r: any) => (
                      <option key={r.room_id} value={r.room_id}>
                        {r.room_id} ({r.room_name} - {r.capacity} chỗ)
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Giảng Viên Chính *
                  </label>
                  <select
                    value={form.main_instructor_id}
                    onChange={(e) => setForm({ ...form, main_instructor_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {metadata.instructors.map((ins: any) => (
                      <option key={ins.instructor_id} value={ins.instructor_id}>
                        {ins.full_name} ({ins.instructor_id})
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Trợ Giảng (Nếu có)
                  </label>
                  <select
                    value={form.teaching_assistant_id}
                    onChange={(e) => setForm({ ...form, teaching_assistant_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    <option value="">-- Không có trợ giảng --</option>
                    {metadata.instructors.map((ins: any) => (
                      <option key={ins.instructor_id} value={ins.instructor_id}>
                        {ins.full_name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Thời Gian Bắt Đầu (YYYY-MM-DD HH:mm:ss) *
                  </label>
                  <input
                    type="text"
                    required
                    value={form.start_time}
                    onChange={(e) => setForm({ ...form, start_time: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-xs font-mono dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Thời Gian Kết Thúc *
                  </label>
                  <input
                    type="text"
                    required
                    value={form.end_time}
                    onChange={(e) => setForm({ ...form, end_time: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-xs font-mono dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-brand-500 px-5 py-2 text-sm font-medium text-white hover:bg-brand-600"
                >
                  Lưu Buổi Học
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
